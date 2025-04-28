#!/usr/bin/env zsh
set -euo pipefail

cwd=$(pwd)
prefix="${cwd%/}/"
# default ignore regex and fallback pattern for trimming paths
ignore_regex='Firebase.*AST'
fallback_pattern='/Classes/'

# parse options: -i | --ignore, -f | --fallback, and optional infile
infile='-'
while (( $# > 0 )); do
  case "$1" in
    -i|--ignore)
      if (( $# < 2 )); then echo "Missing argument for $1" >&2; exit 2; fi
      ignore_regex="$2"; shift 2
      ;;
    -f|--fallback)
      if (( $# < 2 )); then echo "Missing argument for $1" >&2; exit 2; fi
      fallback_pattern="$2"; shift 2
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [-i ignore_regex] [-f fallback_pattern] [build_log.txt]"
      exit 0
      ;;
    *)
      if [[ "$1" == -* ]]; then echo "Unknown option: $1" >&2; exit 2; fi
      infile="$1"; shift
      ;;
  esac
done

gawk -v prefix="$prefix" \
     -v ignore_regex="$ignore_regex" \
     -v fallback_pattern="$fallback_pattern" \
' 
BEGIN { errors = 0 }
/error:/ {
  if ($0 ~ ignore_regex) next
  if (match($0, /^(.+):([0-9]+):([0-9]+):[[:space:]]*error:[[:space:]]*(.*)$/, arr)) {
    path = arr[1]; ln = arr[2]; col = arr[3]; msg = arr[4]
    if (substr(path, 1, length(prefix)) == prefix) {
      path = substr(path, length(prefix) + 1)
    } else {
      pos = index(path, fallback_pattern)
      if (pos) path = substr(path, pos + 1)
    }
    print path ":" ln ":" col ": error: " msg
  } else {
    print $0
  }
  while (getline nl > 0) {
    if (nl ~ /^[[:space:]]*$/) continue
    if (nl ~ /^[[:space:]]*[0-9]+[[:space:]]*[|]/) {
      print nl
      if (getline arrow > 0 && arrow ~ /^[[:space:]]*[|]/) {
        print arrow
      }
    }
    break
  }
  print ""
  errors = 1
}
END {
  if (errors) exit 1
  print "BUILD SUCCEEDED"
  exit 0
}
' "$infile"
