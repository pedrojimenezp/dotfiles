#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests tmux-sessionizer and tmux-new-session on a private tmux socket with TMUX unset, a temp HOME and a stub
# fzf. Run: bash tests/tmux_sessions_test.sh. Exits non-zero when a check fails.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)" # resolved, so paths match what the scripts print
SOCK="$ROOT/tmux.sock"
cleanup() {
  env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
mkdir -p "$HOME"
unset TMUX

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}

BIN="$SRC/bin/.local/bin"
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
# tmux wrapper: every call of tmux-new-session goes to the private server
printf '#!/bin/sh\nunset TMUX\nexec "%s" -S "%s" "$@"\n' "$(command -v tmux)" "$SOCK" >"$STUBS/tmux"
# fzf stub: prints the query line (empty), then $FZF_PICK, like --print-query
printf '#!/bin/sh\ncat >/dev/null\n[ -n "${FZF_QUERY+x}" ] && echo "$FZF_QUERY" || echo\n[ -n "${FZF_PICK:-}" ] && echo "$FZF_PICK"\nexit 0\n' >"$STUBS/fzf"
chmod +x "$STUBS"/*
T() { env -u TMUX tmux -S "$SOCK" "$@"; }
T -f /dev/null new-session -d -s keeper -c "$ROOT" # keeps the server alive

# sessionizer <dir>: TMUX is faked so it creates the session detached; switch-client then fails, which is fine.
sess() {
  env HOME="$HOME" TMUX=fake SESSIONIZER_TMUX_ARGS="-S $SOCK" SESSIONIZER_DIRS="$ROOT/none" PATH="$STUBS:$PATH" bash "$BIN/tmux-sessionizer" "$1" >/dev/null 2>&1 || true
}
path_of() { # the folder of session $1, or "missing"
  T list-sessions -F '#{session_name}'$'\t''#{session_path}' | awk -F'\t' -v n="$1" '$1 == n { print $2; f = 1 } END { if (!f) print "missing" }'
}

echo "== tmux-sessionizer names"
mkdir -p "$ROOT/a/x/web" "$ROOT/b/x/web" "$ROOT/c/x/web" "$ROOT/d.e/my app"
sess "$ROOT/a/x/web"
check "first folder: named after its basename" "$ROOT/a/x/web" "$(path_of web)"
sess "$ROOT/a/x/web"
check "same folder again: reuses the session" "2" "$(T list-sessions | wc -l | tr -d ' ')"
sess "$ROOT/b/x/web"
check "same basename: adds the parent folder" "$ROOT/b/x/web" "$(path_of web-x)"
sess "$ROOT/c/x/web"
check "second collision: counter keeps it apart" "$ROOT/c/x/web" "$(path_of web-x-2)"
check "second collision: earlier sessions untouched" "$ROOT/b/x/web" "$(path_of web-x)"
sess "$ROOT/c/x/web"
check "collision folder again: reuses its session" "4" "$(T list-sessions | wc -l | tr -d ' ')"
sess "$ROOT/d.e/my app"
check "dots and spaces become dashes" "$ROOT/d.e/my app" "$(path_of my-app)"

echo "== tmux-sessionizer --list"
mkdir -p "$ROOT/proj/repo1/.git" "$ROOT/proj/repo1/worktrees/feat-a" "$ROOT/proj/parent/worktrees/feat-b/svc" "$ROOT/proj/.hidden/.git" "$ROOT/proj/node_modules/pkg/.git"
list="$(env HOME="$HOME" SESSIONIZER_DIRS="$ROOT/proj" bash "$BIN/tmux-sessionizer" --list)"
check "list: repo with its path" "1" "$(grep -cF "$ROOT/proj/repo1"$'\t'"$ROOT/proj/repo1" <<<"$list")"
check "list: feature labelled with its owner" "1" "$(grep -cF "feat-a  [repo1]"$'\t'"$ROOT/proj/repo1/worktrees/feat-a" <<<"$list")"
check "list: parent-level feature" "1" "$(grep -cF "feat-b  [parent]"$'\t'"$ROOT/proj/parent/worktrees/feat-b" <<<"$list")"
check "list: hidden and node_modules skipped" "0" "$(grep -cE 'hidden|node_modules' <<<"$list")"
check "list: features come before repos" "feat" "$(head -1 <<<"$list" | cut -c1-4)"

echo "== tmux-new-session --list"
mkdir -p "$ROOT/here" "$ROOT/other"
nlist="$(env HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" SESSIONIZER_DIRS="$ROOT/proj" bash "$BIN/tmux-new-session" --list "$ROOT/here")"
check "new-session list: pane path first" "$ROOT/here" "$(head -1 <<<"$nlist")"
nlist="$(env HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$BIN/tmux-new-session" --list "$ROOT/nope")"
check "new-session list: missing folders dropped" "0" "$(grep -c nope <<<"$nlist")"
nlist="$(env HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$BIN/tmux-new-session" --list "$ROOT/here" 2>/dev/null)"
check "new-session list: no duplicates" "1" "$(grep -cxF "$ROOT/here" <<<"$nlist")"

echo "== tmux-new-session creates sessions"
# run_new <name> <fzf pick> [fzf query]: runs the script on the private server; the name travels in @new_session_name
run_new() {
  T set -g @new_session_name "$1"
  env HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" FZF_PICK="$2" ${3+FZF_QUERY="$3"} bash "$BIN/tmux-new-session" "$ROOT" >/dev/null 2>&1 || true
}
run_new "my.proj:1" "$ROOT/here"
check "name cleaned of dots and colons" "$ROOT/here" "$(path_of my-proj-1)"
run_new "" "$ROOT/other"
check "empty name: folder basename" "$ROOT/other" "$(path_of other)"
check "name option cleared after use" "" "$(T show -gv @new_session_name 2>/dev/null || true)"
run_new "my.proj:1" "$ROOT/other"
check "existing name: no second session" "1" "$(T list-sessions -F '#{session_name}' | grep -cx 'my-proj-1')"
run_new "typed" "" "$ROOT/nonexistent"
check "typed missing folder: no session" "missing" "$(path_of typed)"
run_new "typed" "" "$ROOT/here"
check "typed existing path: used as typed" "$ROOT/here" "$(path_of typed)"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
