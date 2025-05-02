#!/usr/bin/env zsh
set -euo pipefail

cwd=$(pwd)
prefix="${cwd%/}/"
# default ignore regex and fallback pattern (none)
ignore_regex=''
fallback_pattern=''

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

awk -v prefix="$prefix" \
     -v ignore_regex="$ignore_regex" \
     -v fallback_pattern="$fallback_pattern" \
'
BEGIN { errors = 0; ctx_len = 0 }
# buffer include-chain context lines
/^In file included from / {
  # trim prefix or fallback from context path
  ctx_line = $0
  if (substr(ctx_line, 1, length(prefix)) == prefix) {
    ctx_line = substr(ctx_line, length(prefix) + 1)
  } else if (fallback_pattern != "" && (pos = index(ctx_line, fallback_pattern))) {
    ctx_line = substr(ctx_line, pos + length(fallback_pattern))
  }
  ctx_len++
  ctx[ctx_len] = ctx_line
  next
}
/error:/ {
  if (ignore_regex != "" && $0 ~ ignore_regex) next
  # print buffered include-context, then clear
  for (i = 1; i <= ctx_len; i++) print ctx[i]
  ctx_len = 0
  # parse and trim error lines path:line:col: error: message
  line = $0
  p1 = index(line, ":")
  if (p1 == 0) {
    print line
  } else {
    path = substr(line, 1, p1-1)
    rest1 = substr(line, p1+1)
    p2 = index(rest1, ":")
    if (p2 == 0) {
      print line
    } else {
      ln = substr(rest1, 1, p2-1)
      rest2 = substr(rest1, p2+1)
      p3 = index(rest2, ":")
      if (p3 == 0) {
        print line
      } else {
        col = substr(rest2, 1, p3-1)
        rest3 = substr(rest2, p3+1)
        sub(/^[[:space:]]*/, "", rest3)
        sub(/^error:[[:space:]]*/, "", rest3)
        msg = rest3
        if (substr(path, 1, length(prefix)) == prefix) {
          path = substr(path, length(prefix) + 1)
        } else if (fallback_pattern != "" && (pos = index(path, fallback_pattern))) {
          path = substr(path, pos + length(fallback_pattern))
        }
        print path ":" ln ":" col ": error: " msg
      }
    }
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
  if (errors) {
    print "BUILD FAILED"
    exit 1
  }
  print "BUILD SUCCEEDED"
  exit 0
}
' "$infile"
