#!/usr/bin/env bash
# Tests install.sh's Claude flags against a temp HOME. Offline: errors exit before any step, and the
# dry runs only print. Run: bash tests/install_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export HOME="$ROOT/home"
mkdir -p "$HOME"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" <test command...>
  local desc="$1"
  shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

# Runs install.sh with the given flags; sets OUT (stdout and stderr) and RC (exit code).
run_install() {
  RC=0
  OUT="$(env HOME="$HOME" CLAUDE_SHARED_DIR="${CLAUDE_SHARED_DIR:-$ROOT/claude-shared}" bash "$SRC/install.sh" "$@" 2>&1)" || RC=$?
}

# True when the last run failed with exit 1 and its output contains $1.
failed_with() { [[ $RC -eq 1 ]] && grep -qF -- "$1" <<<"$OUT"; }

echo "== --claude-accounts needs --with-claude"
run_install --claude-accounts personal
check "alone: error" failed_with "only works together with --with-claude"
run_install --dry-run --claude-accounts=personal
check "alone, = form: error" failed_with "only works together with --with-claude"

echo "== --claude-accounts rejects bad values"
run_install --with-claude url --claude-accounts
check "missing value" failed_with "needs account names"
run_install --with-claude url --claude-accounts --dry-run
check "flag as value" failed_with "needs account names"
run_install --with-claude url --claude-accounts=
check "empty value, = form" failed_with "needs account names"
run_install --with-claude url --claude-accounts "a b"
check "space in value" failed_with "needs account names"
run_install --with-claude url --claude-accounts "a,,b"
check "empty name between commas" failed_with "empty name"
run_install --with-claude url --claude-accounts "a,"
check "trailing comma" failed_with "empty name"

echo "== dry run passes the names on"
run_install --dry-run --with-claude "$ROOT/none.git" --claude-accounts personal,niche
check "clone not yet there: installer gets both names" grep -qF "claude-shared/install.sh personal niche" <<<"$OUT"
run_install --dry-run --with-claude "$ROOT/none.git" --claude-accounts=personal
check "= form: installer gets one name" grep -qE "claude-shared/install.sh personal$" <<<"$OUT"
run_install --dry-run --with-claude "$ROOT/none.git"
check "without the flag: installer gets no arguments" grep -qE "claude-shared/install.sh$" <<<"$OUT"

mkdir -p "$ROOT/existing"
git -C "$ROOT/existing" init -q
CLAUDE_SHARED_DIR="$ROOT/existing" run_install --dry-run --with-claude "$ROOT/none.git" --claude-accounts personal
check "clone already there: installer still gets the name" grep -qE "existing/install.sh personal$" <<<"$OUT"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
