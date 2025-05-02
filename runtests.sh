#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export RUN="$SCRIPT_DIR/xmlmath"

ALL_OKAY="true"
RUN_TESTS=0
RUN_TESTS_SUCCESS=0
RUN_TESTS_ERROR=0

for script in "$SCRIPT_DIR/test"/*.sh; do

  if [[ -f "$script" && "$(basename $script)" != "_common.sh" ]]; then
    ((RUN_TESTS+=1))
    result=$(bash "$script")

    if [[ "$result" =~ success$ ]]; then
      ((RUN_TESTS_SUCCESS+=1))
      echo "✅ $(basename $script)"
    else
      ((RUN_TESTS_ERROR+=1))
      ALL_OKAY="false"
      echo "❌ $(basename $script)"
      while IFS= read -r line; do
        echo "  $line"
      done <<< "$result"
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