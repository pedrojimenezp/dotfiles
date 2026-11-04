#!/usr/bin/env bash
# Tests bin/.local/bin/tmux-lazygit with stub lazygit and fzf on PATH. Run: bash tests/tmux_lazygit_test.sh
# Exits non-zero when a check fails.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}

# Stub lazygit prints its arguments; stub fzf prints $FZF_PICK (nothing when unset).
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
printf '#!/bin/sh\necho "lazygit $*"\n' >"$STUBS/lazygit"
# shellcheck disable=SC2016 # the stub's variables must stay unexpanded
printf '#!/bin/sh\ncat >/dev/null\n[ -n "${FZF_PICK:-}" ] && echo "$FZF_PICK"\nexit 0\n' >"$STUBS/fzf"
chmod +x "$STUBS/lazygit" "$STUBS/fzf"
BASE_PATH="/usr/bin:/bin" # system dirs only: no fzf, and no real lazygit
SCRIPT="$SRC/bin/.local/bin/tmux-lazygit"

# run <dir> [VAR=value...]: the script's output with the stubs on PATH
run() {
  local dir="$1"
  shift
  env PATH="$STUBS:$BASE_PATH" ${1+"$@"} bash "$SCRIPT" "$dir" </dev/null 2>&1 || true
}

mkdir -p "$ROOT/repo/.git" "$ROOT/repo/sub" "$ROOT/repo/nested/.git"
check "repo: opens in the folder" "lazygit -p $ROOT/repo" "$(run "$ROOT/repo")"
check "subfolder of a repo: opens in the folder" "lazygit -p $ROOT/repo/sub" "$(run "$ROOT/repo/sub")"

mkdir -p "$ROOT/one/api/.git" "$ROOT/one/docs"
check "one repo below: opens it" "lazygit -p $ROOT/one/api" "$(run "$ROOT/one")"

mkdir -p "$ROOT/wt/web" "$ROOT/wt/api/.git" "$ROOT/wt/notes"
echo "gitdir: /elsewhere" >"$ROOT/wt/web/.git" # a worktree has a .git file
check "several repos: opens the pick" "lazygit -p $ROOT/wt/web" "$(run "$ROOT/wt" FZF_PICK=web)"
check "several repos: no pick exits quietly" "" "$(run "$ROOT/wt")"

# Without fzf on PATH the script prints the repos and a hint.
mkdir -p "$ROOT/nofzf"
printf '#!/bin/sh\necho "lazygit $*"\n' >"$ROOT/nofzf/lazygit"
chmod +x "$ROOT/nofzf/lazygit"
out="$(env PATH="$ROOT/nofzf:$BASE_PATH" bash "$SCRIPT" "$ROOT/wt" </dev/null 2>&1 || true)"
case "$out" in
  *api*web*"fzf is not installed"*) ok "no fzf: lists the repos and a hint" ;;
  *) bad "no fzf: lists the repos and a hint (got: $out)" ;;
esac

mkdir -p "$ROOT/empty/plain"
check "no repos below: opens lazygit as is" "lazygit -p $ROOT/empty" "$(run "$ROOT/empty")"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
