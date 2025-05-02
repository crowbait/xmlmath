result="success"
out=""

dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TEST_DEFAULT="$dir/test.xml"

addline () {
  out=$(printf "$out\n$1")
}

error () {
  result="error"
  addline "$(tput bold)ERROR$(tput sgr0): $1"
}

# takes 2 arguments:
# - string of options to be passed to script
# - filename (basename) of expected output
expect () {
  call=($(caller))
  pos="$(basename ${call[1]})#${call[0]}"
  read -r -a ARGS <<< "$1"
  if [[ "$(echo "$("$RUN" "${ARGS[@]}")" | xmllint --format -)" != "$(cat "$dir/$2" | xmllint --format -)" ]]; then
    error "Mismatch $pos"
  fi
}

fin () {
  if [[ "$result" == "success" ]]; then
    printf "$out\nsuccess"
  else
    printf "$out\nerror"
  fi
}