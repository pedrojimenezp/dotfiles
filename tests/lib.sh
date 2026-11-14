#!/usr/bin/env bash
# Shared helpers for the bash tests. Source it: source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# Counts results in PASS and FAIL; end the test with `summary`.

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }

check() { # check "<description>" <test command...>
  local desc="$1"
  shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

check_eq() { # check_eq "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}

contains() { # contains "<description>" "<needle>" "<haystack>"
  case "$3" in *"$2"*) ok "$1" ;; *) bad "$1 (missing: $2 in: $3)" ;; esac
}

summary() { # Prints the totals; the return status is non-zero when a check failed.
  echo
  echo "passed: $PASS, failed: $FAIL"
  [[ $FAIL -eq 0 ]]
}
