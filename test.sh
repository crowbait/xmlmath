#!/bin/bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TESTFILE="$DIR/test/test.xml"

# declare all tests
# format: [parameters for xmlmath]
# the expected output is test/[name of test].xml

declare -A tests=(
  [target_attr]="attr add 1 -f $TESTFILE attr1"
  [target_val]="value add 1.1 -f $TESTFILE val1"
  [target_attr_multiple]="attr add 1 -f $TESTFILE attr1 attr2"
  [target_val_multiple]="value add 1 -f $TESTFILE val1 val2"
  [op_subtract]="value subtract 5 -f $TESTFILE val2"
  [op_multiply]="value multiply 2 -f $TESTFILE val2"
  [op_divide]="value divide 5 -f $TESTFILE val2"
  [op_set]="value set 500 -f $TESTFILE val2"
  [flag_int_down]="value add 5.2 --int -f $TESTFILE singleval"
  [flag_int_up]="value add 5.6 --int -f $TESTFILE singleval"
  [flag_min]="value subtract 9 --min 5 -f $TESTFILE singleval"
  [flag_max]="value add 9 --max 15 -f $TESTFILE singleval"
  [flag_regex_value]="value multiply 10 --regex -f $TESTFILE val."
  [flag_regex_attr]="attr multiply 10 --regex -f $TESTFILE attr[0-9]"
  [within_attr]="attr multiply 10 --within notype -f $TESTFILE attr2"
  [within_val]="value multiply 10 --within type -f $TESTFILE val1"
  [within_nested_parent]="value multiply 10 --within notype -f $TESTFILE val1"
  [within_nested_child]="value multiply 10 --within med -f $TESTFILE val1"
  [within_additional_attr]="attr multiply 10 --within notype --wa name=\"named\" -f $TESTFILE --regex attr[0-9]"
  [within_additional_val]="value multiply 10 --within notype --wa named -f $TESTFILE val1"
  [within_additional_nested_child]="value multiply 10 --within med --wa namedsub -f $TESTFILE val1"
)



ALL_OKAY="true"
RUN_TESTS=0
RUN_TESTS_SUCCESS=0
RUN_TESTS_ERROR=0
rm -f $DIR/testout_*

for T in "${!tests[@]}"; do
  ((RUN_TESTS+=1))
  read -r -a ARGS <<< "${tests[$T]}"
  output=$("$DIR/xmlmath" "${ARGS[@]}")
  output_formatted=$(echo "$output" | xmllint --format -)
  expect=$(cat "$DIR/test/$T.xml" | xmllint --format -)
  
  if [[ -n "$output_formatted" && "$output_formatted" == "$expect" ]]; then
    ((RUN_TESTS_SUCCESS+=1))
    echo "✅ $T"
  else
    ((RUN_TESTS_ERROR+=1))
    echo "❌ $T: Mismatch"
    # add verbose flag to run and dump
    newargs="${tests[$T]/ -f/ -v -f}"
    read -r -a ARGS <<< "$newargs"
    output=$("$DIR/xmlmath" "${ARGS[@]}" 2>&1)
    echo "$output" > "$DIR/testout_$T"
    echo "Output written to $DIR/testout_$T"
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