source "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/_common.sh"

echo "Target attr1"
expect "attr add 1 -f $TEST_DEFAULT attr1" "expect-target_attr-1.xml"

fin