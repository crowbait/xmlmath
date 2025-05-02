#!/bin/bash
set -e

print_help () {
  echo "XMLMath v1.0.0"
  echo "c Crowbait | MIT License"
  echo ""
  echo "Usage: $0 <target-mode> <operation-mode> [<modifier>] [options] <targets...>"
  echo ""
  echo "Target Modes:"
  echo "  attr        Modify XML attributes:     <tag attr=\"2\" />"
  echo "  value       Modify XML element values: <tag>2</tag>"
  echo ""
  echo "Operation Modes:"
  echo "  --add      | a   Add modifier"
  echo "  --subtract | s   Subtract modifier"
  echo "  --multiply | m   Multiply by modifier"
  echo "  --divide   | d   Divide by modifier"
  echo ""
  echo "Options:"
  echo "  --file <file>  | -f <file>  Input file (optional, stdin if not specified, stdout is file path)"
  echo "  --inplace      | -p         Modify the file in place (requires --file, stdout if not specified)"
  echo "  --int          | -i         Round results to nearest integer"
  echo "  --min <val>                 Clamp values to this minimum"
  echo "  --max <val>                 Clamp values to this maximum"
  echo "  --regex        | -r         Treat targets names (value elements or attributes) as regex patterns - use single quotes!"
  echo "  --within <tag> | -w <tag>   Only affect targets within this enclosing tag (regex; use single quotes!)"
  echo "                                attr:  matches only attributes on this specific tag: <thismatches attr=..."
  echo "                                value: matches only values if *this* is a descendant of tag: <thismatches>[...]<val>2</val>..."
  echo "    --within-additional <regex> | --wa <regex>"
  echo "                                This is an addon to -w and specifies that the opening tag line must match an additional regex."
  echo "                                -w 'type' --wr 'attr.=\"1\"' will match all \"type\" tags that also have some attribute called \"attr\" set to 1."
  echo "  --verbose      | -v         Print detailed information about what's being done"
  echo "  --progress                  Prints progress updates (default false, can't be used with -v)"
  echo "  help                        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 value add 1.5 --file zones.xml --within zone radius"
  echo "  $0 attr multiply 2 --file zones.xml smin smax dmin dmax"
  echo "  $0 attr divide 3 --file zones.xml --int --min 1 --max 10 count"
  echo "  $0 attr multiply 1.1 --file zones.xml --regex -w zoneA '.*min'"
  echo "  $0 attr format --file zones.xml"
  echo "  cat zones.xml | $0 value subtract 2 depth"
}

# Print help if no arguments are passed
if [[ $# -eq 0 ]]; then
  print_help
  exit 0
fi

# --- Default values ---
FILE=""
INPLACE="false"
INTEGER_MODE="false"
MIN_VALUE=""
MAX_VALUE=""
REGEX_MODE="false"
WITHIN_TAG=""
WITHIN_TAG_ADDITIONAL=""
VERBOSE="false"
PROGRESS="false"

# --- Parse positional args ---
TARGET_MODE="$1"
OP_MODE="$2"
MODIFIER="$3"
shift 3

# Collect options
while [[ "$1" == --* || "$1" == -* ]]; do
  case "$1" in
    --file|-f)
      FILE="$2"
      shift 2
      ;;
    --inplace|-p)
      INPLACE="true"
      shift
      ;;
    --int|-i)
      INTEGER_MODE="true"
      shift
      ;;
    --min)
      MIN_VALUE="$2"
      shift 2
      ;;
    --max)
      MAX_VALUE="$2"
      shift 2
      ;;
    --regex|-r)
      REGEX_MODE="true"
      shift
      ;;
    --within|-w)
      WITHIN_TAG="$2"
      shift 2
      ;;
    --within-additional|--wa)
      WITHIN_TAG_ADDITIONAL="$2"
      shift 2
      ;;
    --verbose|-v)
      VERBOSE="true"
      shift
      ;;
    --progress)
      PROGRESS="true"
      shift 1
      ;;
    help)
      print_help
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo ""
      print_help
      exit 1
      ;;
  esac
done

TARGETS=("$@")

# Validate modes
if [[ "$TARGET_MODE" != "attr" && "$TARGET_MODE" != "value" ]]; then
  print_help
  echo ""
  echo "❌ Invalid target mode: $TARGET_MODE"
  exit 1
fi

if [[ "$OP_MODE" != "add" && "$OP_MODE" != "a" &&
      "$OP_MODE" != "subtract" && "$OP_MODE" != "s" &&
      "$OP_MODE" != "multiply" && "$OP_MODE" != "m" &&
      "$OP_MODE" != "divide" && "$OP_MODE" != "d" &&
      "$OP_MODE" != "format" && "$OP_MODE" != "f" ]]; then
  print_help
  echo ""
  echo "❌ Invalid operation mode: $OP_MODE"
  exit 1
fi

if [[ "$OP_MODE" != "format" && "$OP_MODE" != "f" && ! "$MODIFIER" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
  print_help
  echo ""
  echo "❌ Invalid modifier: $MODIFIER"
  exit 1
fi

# Check if --inplace; requires --file
if [[ "$INPLACE" == "true" && -z "$FILE" ]]; then
  print_help
  echo ""
  echo "❌ --inplace requires --file"
  exit 1
fi

# END sanity checks

# Setup input
if [[ -n "$FILE" ]]; then
  if [[ ! -f "$FILE" ]]; then
    echo "❌ File not found: $FILE"
    exit 1
  fi
  [[ "$INPLACE" == "true" ]] && cp "$FILE" "$FILE.bak"
  INPUT_STREAM="$FILE"
else
  INPUT_STREAM="/dev/stdin"
fi
# format before processing to protect fragile regex and line-based processing
TMP_XML=$(mktemp)
xmllint --format "$INPUT_STREAM" > "$TMP_XML"
INPUT_STREAM="$TMP_XML"

# Math operation
apply_math() {
  local value="$1"
  local modifier="$2"
  local result

  case "$OP_MODE" in
    add|a)
      result=$(awk "BEGIN { print $value + $modifier }")
      ;;
    subtract|s)
      result=$(awk "BEGIN { print $value - $modifier }")
      ;;
    multiply|m)
      result=$(awk "BEGIN { print $value * $modifier }")
      ;;
    divide|d)
      result=$(awk "BEGIN { print $value / $modifier }")
      ;;
  esac

  # Clamp
  if [[ -n "$MIN_VALUE" ]]; then
    result=$(awk -v r="$result" -v min="$MIN_VALUE" 'BEGIN { print (r < min) ? min : r }')
  fi

  if [[ -n "$MAX_VALUE" ]]; then
    result=$(awk -v r="$result" -v max="$MAX_VALUE" 'BEGIN { print (r > max) ? max : r }')
  fi

  # Round
  if [[ "$INTEGER_MODE" == "true" ]]; then
    result_old=result
    result=$(awk "BEGIN { printf \"%.0f\", $result }")
  else
    result=$(awk "BEGIN { printf \"%.8f\", $result }")  # Limit to 8 decimal places for safety
    # Strip trailing zeros and the decimal point if there's no fractional part
    result=$(echo "$result" | sed -E 's/(\.[0-9]*[1-9])0+$|\.[0-9]*$/\1/')
  fi

  echo "$result"
}

# Main processing loop

TOTAL_LINES=$(wc -l < "$TMP_XML")
TOTAL_TARGETS="${#TARGETS[@]}"
TOTAL_ITERATIONS=$(awk "BEGIN { print $TOTAL_LINES * $TOTAL_TARGETS }")
[[ "$VERBOSE" == "true" ]] && echo "$TOTAL_LINES total lines" >&2
[[ "$VERBOSE" == "true" ]] && echo "$TOTAL_TARGETS total targets" >&2
[[ "$VERBOSE" == "true" ]] && echo "$TOTAL_ITERATIONS total iterations" >&2

TMP_FILE="$(mktemp)"

LINE_NUM=0
ITERATION=0
WITHIN_ACTIVE=false
while IFS= read -r line || [[ -n "$line" ]]; do
  ((LINE_NUM+=1))
  [[ "$VERBOSE" == "true" ]] && echo "Line $LINE_NUM" >&2
  [[ "$PROGRESS" == "true" && "$VERBOSE" == "false" ]] && echo -ne ">> $(awk "BEGIN { printf \"%.2f\", $ITERATION / $TOTAL_ITERATIONS * 100 }")% $ITERATION / ${TOTAL_ITERATIONS}: L#$LINE_NUM $target\r"

  new_line="$line"
  indent=$(echo "$line" | grep -o '^[[:space:]]*')

  # Track within state for --within
  if [[ -n "$WITHIN_TAG" ]]; then
    if [[ "$TARGET_MODE" == "attr" ]]; then
      if [[ "$line" =~ \<$WITHIN_TAG && ( -z "$WITHIN_TAG_ADDITIONAL" || "$line" =~ $WITHIN_TAG_ADDITIONAL ) ]]; then
        WITHIN_ACTIVE=true
      fi
    elif [[ "$TARGET_MODE" == "value" ]]; then
      if [[ "$line" =~ \<$WITHIN_TAG && ( -z "$WITHIN_TAG_ADDITIONAL" || "$line" =~ $WITHIN_TAG_ADDITIONAL )  ]]; then
        WITHIN_ACTIVE=true
      fi
      if [[ "$line" =~ \<\/$WITHIN_TAG\> ]]; then
        WITHIN_ACTIVE=false
      fi
    fi
  else
    WITHIN_ACTIVE=false
  fi

  if [[ "$WITHIN_ACTIVE" == "true" ]]; then
    for target in "${TARGETS[@]}"; do
      ((ITERATION+=1))
      pattern="$target"
      [[ "$REGEX_MODE" == "false" ]] && pattern="^$target$"

      if [[ "$TARGET_MODE" == "attr" ]]; then
        orig_line="$new_line"
        while IFS= read -r pair; do
          key=$(echo "$pair" | cut -d= -f1)
          val=$(echo "$pair" | cut -d= -f2- | tr -d '"')

          match=false
          if [[ "$REGEX_MODE" == "true" && "$key" =~ $pattern ]]; then
            match=true
          elif [[ "$REGEX_MODE" == "false" && "$key" == "$target" ]]; then
            match=true
          fi

          if [[ "$match" == "true" ]]; then
            new_val=$(apply_math "$val" "$MODIFIER")
            orig_line=$(echo "$orig_line" | sed -E "s/($key=\")$val\"/\1$new_val\"/")
            [[ "$VERBOSE" == "true" ]] && echo "[$LINE_NUM]   Target '$target'   replaced attribute '$key' value '$val' → '$new_val'" >&2
          fi
        done < <(echo "$line" | grep -oE '[a-zA-Z0-9_.:-]+="[^"]*"')
        new_line="$orig_line"
      elif [[ "$TARGET_MODE" == "value" && "$line" =~ \<$target\>([^<]+)\</$target\> ]]; then
        old_val="${BASH_REMATCH[1]}"
        new_val=$(apply_math "$old_val" "$MODIFIER")
        new_line=$(echo "$new_line" | sed -E "s|(<$target>)$old_val(</$target>)|\1$new_val\2|")
        [[ "$VERBOSE" == "true" ]] && echo "[$LINE_NUM]   Value modified: <$target>$old_val</$target> → <$target>$new_val</$target>" >&2
      fi
    done
  else
    ((ITERATION+="${#TARGETS[@]}"))
  fi

  if [[ "$TARGET_MODE" == "attr" && "$WITHIN_ACTIVE" == "true" && "$line" =~ \> ]]; then
    WITHIN_ACTIVE=false
  fi

  printf "%s\n" "$new_line" >> "$TMP_FILE"
done < "$INPUT_STREAM"

# Output result
if [[ "$INPLACE" == "true" ]]; then
  echo "$FILE"
  if [[ "$VERBOSE" == "true" ]]; then
    echo "Updated '$FILE' in place (backup: $FILE.bak)" >&2
  fi
else
  cat "$TMP_FILE"
  if [[ "$VERBOSE" == "true" ]]; then
    echo "Output written to stdout" >&2
  fi
fi

rm "$TMP_FILE"
rm "$TMP_XML"