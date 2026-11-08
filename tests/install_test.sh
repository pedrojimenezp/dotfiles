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

echo "== dry run calls the Claude installer with no arguments"
run_install --dry-run --with-claude "$ROOT/none.git"
check "clone not yet there" grep -qE "claude-shared/install.sh$" <<<"$OUT"

mkdir -p "$ROOT/existing"
git -C "$ROOT/existing" init -q
CLAUDE_SHARED_DIR="$ROOT/existing" run_install --dry-run --with-claude "$ROOT/none.git"
check "clone already there" grep -qE "existing/install.sh$" <<<"$OUT"

echo "== font install failure"
# install_font only runs on a Linux desktop, so run the function alone with stub tools on PATH.
font_home="$ROOT/font-home"
font_bin="$ROOT/font-bin"
mkdir -p "$font_home" "$font_bin"
printf '#!/bin/sh\nexit 0\n' >"$font_bin/fc-list"
printf '#!/bin/sh\nexit 0\n' >"$font_bin/fc-cache"
printf '#!/bin/sh\nexit 22\n' >"$font_bin/curl" # what curl -f returns on an HTTP error
chmod +x "$font_bin"/*
awk '/^install_font\(\) /,/^}/' "$SRC/install.sh" >"$ROOT/install_font.sh"
FONT_RC=0
FONT_OUT="$(
  PATH="$font_bin:$PATH" HOME="$font_home" bash -c '
    set -euo pipefail
    DRY=0 NERD_FONT=Monaspace NERD_FONT_FAMILY=Monaspice
    run() { "$@"; }
    source "$2"
    mkdir -p "$HOME/.local/share/fonts/MonaspaceNerdFont" # empty folder: not "installed", must be removed on failure
    install_font
    echo "continued"
  ' _ "$SRC" "$ROOT/install_font.sh" 2>&1
)" || FONT_RC=$?
check "failed download: install continues with exit 0" bash -c '[[ $1 -eq 0 ]] && grep -qF continued <<<"$2"' _ "$FONT_RC" "$FONT_OUT"
check "failed download: warning printed" grep -qF "Warning: font install failed, re-run install.sh to retry" <<<"$FONT_OUT"
check "failed download: partial font folder removed" bash -c '[[ ! -e "$1/.local/share/fonts/MonaspaceNerdFont" ]]' _ "$font_home"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
