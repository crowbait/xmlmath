#!/bin/bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# declare common test input files
TEST_DEFAULT="$DIR/test/test.xml"

# declare all tests
# format: [parameters for xmlmath]
# the expected output is test/[name of test].xml

declare -A tests=(
  [target_attr]="attr add 1 -f $TEST_DEFAULT attr1"
)



ALL_OKAY="true"
RUN_TESTS=0
RUN_TESTS_SUCCESS=0
RUN_TESTS_ERROR=0
rm -f "$dir/testout_*"

for T in "${!tests[@]}"; do
  ((RUN_TESTS+=1))
  read -r -a ARGS <<< "${tests[$T]}"
  output=$(echo "$("$DIR/xmlmath" "${ARGS[@]}")" | xmllint --format -)
  expect=$(cat "$DIR/test/$T.xml" | xmllint --format -)
  
  if [[ "$output" == "$expect" ]]; then
    ((RUN_TESTS_SUCCESS+=1))
    echo "✅ $T"
  else
    ((RUN_TESTS_ERROR+=1))
    echo "❌ $T"
    if [[ -n "$output" ]]; then
      echo "$output" > "$DIR/testout_$T"
      echo "Output written to $DIR/testout_$T"
    else
      echo "⚠️ No output to write!"
    fi
  fi
done

echo ""
if [[ "$ALL_OKAY" == "true" ]]; then
  echo "✅ $(tput bold)Tests:   $(printf "%4s\n" $RUN_TESTS)$(tput sgr0)"
else
  echo "❌ $(tput bold)Tests:   $(printf "%4s\n" $RUN_TESTS)$(tput sgr0)"
fi
echo "   Success: $(printf "%4s\n" $RUN_TESTS_SUCCESS)"
echo "   Failed:  $(printf "%4s\n" $RUN_TESTS_ERROR)"