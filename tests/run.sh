#!/usr/bin/env bash
# Runs every test file in this folder and prints the ones that failed.
# Usage: tests/run.sh
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
failed=()
for t in *_test.sh *_test.py; do
  echo "### $t"
  case "$t" in
    *.py) python3 -I "$t" ;;
    *) bash "$t" ;;
  esac || failed+=("$t")
done
echo
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "FAILED: ${failed[*]}"
  exit 1
fi
echo "all test files passed"
