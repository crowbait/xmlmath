#!/bin/bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

replacement_targets=(
  "checks"
  "diff"
  "help"
  "operation"
)

mkdir -p "$DIR/build"
sourcefile="$DIR/xmlmath"
outfile="$DIR/build/xmlmath"
tmpfile="$DIR/build/tmp"
cp "$sourcefile" "$outfile"

for target in "${replacement_targets[@]}"; do
  echo "Replacing source \"parts/$target\"..."

  if [[ ! -f "parts/$target" ]]; then
    echo "❌ File '$target' not found! Aborting."
    exit 1
  fi

  awk -v pattern="^[[:space:]]*source[[:space:]]+\\\"parts/${target}\\\"" -v repl_file="parts/$target" '
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