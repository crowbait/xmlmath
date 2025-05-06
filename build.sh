#!/bin/bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

replacement_targets=(
  "ext_checks"
  "ext_diff"
  "ext_help"
  "ext_operation"
)

mkdir -p "$DIR/build"
sourcefile="$DIR/xmlmath"
outfile="$DIR/build/xmlmath"
tmpfile="$DIR/build/tmp"
cp "$sourcefile" "$outfile"

for target in "${replacement_targets[@]}"; do
  echo "Replacing source \"$target\"..."

  if [[ ! -f "$target" ]]; then
    echo "❌ File '$target' not found! Aborting."
    exit 1
  fi

  awk -v pattern="^[[:space:]]*source[[:space:]]+\\\"${target}\\\"" -v repl_file="$target" '
    $0 ~ pattern {
      while ((getline line < repl_file) > 0)
        print line
      close(repl_file)
      next
    }
    { print }
  ' "$outfile" > "$tmpfile"

  mv "$tmpfile" "$outfile"
done

echo "✅ Compiled file written to $outfile"

echo ""
chmod +x "$outfile"
./test.sh "$outfile"

echo ""
echo "✅ $(tput bold)Build completed.$(tput sgr0)"