#!/usr/bin/env zsh
set -euo pipefail

cwd=$(pwd)
prefix="${cwd%/}/"
ignore_regex='Firebase.*AST'

if [ $# -gt 0 ] && [ "$1" != "-h" ] && [ "$1" != "--help" ]; then
  infile="$1"
else
  infile="-"
fi

gawk -v prefix="$prefix" -v ignore_regex="$ignore_regex" '
BEGIN { errors = 0 }
/error:/ {
  if ($0 ~ ignore_regex) next
  if (match($0, /^(.+):([0-9]+):([0-9]+):[[:space:]]*error:[[:space:]]*(.*)$/, arr)) {
    path = arr[1]; ln = arr[2]; col = arr[3]; msg = arr[4]
    if (substr(path, 1, length(prefix)) == prefix) {
      path = substr(path, length(prefix) + 1)
    } else {
      pos = index(path, "/Classes/")
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
