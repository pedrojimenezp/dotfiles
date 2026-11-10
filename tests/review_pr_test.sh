#!/usr/bin/env bash
# Tests bin/.local/bin/review-pr with a temp origin repo, a clone and stub gh and review on PATH.
# Run: bash tests/review_pr_test.sh. Tmux only runs on a private socket. Exits non-zero when a check fails.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)" # resolved, so paths match what git prints
SOCK="$ROOT/tmux.sock"
cleanup() {
  env -u TMUX tmux -S "$SOCK" kill-server >/dev/null 2>&1 || true # only the private server of this test
  rm -rf "$ROOT"
}
trap cleanup EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p "$HOME"
unset TMUX

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" "<expected>" "<actual>"
  if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected: $2, got: $3)"; fi
}
contains() { # contains "<description>" "<needle>" "<haystack>"
  case "$3" in *"$2"*) ok "$1" ;; *) bad "$1 (missing: $2 in: $3)" ;; esac
}

STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
printf '#!/bin/sh\necho "gh $*" >>"%s/gh.log"\necho develop\n' "$ROOT" >"$STUBS/gh"
printf '#!/bin/sh\necho "review $*" >>"%s/review.log"\n' "$ROOT" >"$STUBS/review"
chmod +x "$STUBS/gh" "$STUBS/review"
SCRIPT="$SRC/bin/.local/bin/review-pr"
# run <dir> <args...>: runs review-pr from <dir>; sets $out and $rc.
run() {
  local d="$1"
  shift
  rc=0
  out="$(cd "$d" && PATH="$STUBS:$PATH" bash "$SCRIPT" "$@" 2>&1)" || rc=$?
}

ORIGIN="$ROOT/origin.git"
git init -q --bare -b main "$ORIGIN"
git init -q -b main "$ROOT/seed"
git -C "$ROOT/seed" remote add origin "$ORIGIN"
echo base >"$ROOT/seed/f.txt"
git -C "$ROOT/seed" add f.txt
git -C "$ROOT/seed" commit -q -m base
git -C "$ROOT/seed" push -q origin main
git -C "$ROOT/seed" branch develop
git -C "$ROOT/seed" push -q origin develop
# pr_commit <file> <text>: commits on a branch in seed built on main and pushes it as the PR head.
git -C "$ROOT/seed" checkout -q -b prsrc
pr_commit() {
  echo "$2" >"$ROOT/seed/$1"
  git -C "$ROOT/seed" add "$1"
  git -C "$ROOT/seed" commit -q -m "$1"
  git -C "$ROOT/seed" push -q -f origin prsrc:refs/pull/123/head
}
pr_commit one.txt 1
git clone -q "$ORIGIN" "$ROOT/clone"
CLONE="$ROOT/clone"
WT="$CLONE/worktrees/pr-123"

run "$CLONE" 
check "no args: usage, exit 2" "2" "$rc"
contains "no args: message" "usage: review-pr" "$out"
run "$CLONE" abc
check "bad number: exit 2" "2" "$rc"
run "$ROOT" 123
check "outside a repo: exit 1" "1" "$rc"

echo "first open"
run "$CLONE" 123
check "first open: exit 0" "0" "$rc"
check "first open: worktree is at the PR head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check "first open: branch pr-123" "pr-123" "$(git -C "$WT" branch --show-current)"
contains "first open: runs review with base and path" "review develop $WT" "$(cat "$ROOT/review.log")"
contains "first open: gh asked for the base" "gh pr view 123 --json baseRefName -q .baseRefName" "$(cat "$ROOT/gh.log")"
contains "first open: dependency hint" "install the dependencies" "$out"
contains "first open: prints the path" "Worktree: $WT" "$out"
git -C "$CLONE" rev-parse --verify -q origin/develop >/dev/null && ok "first open: base fetched" || bad "first open: base fetched"

echo "rerun from another worktree of the repo, PR has a new commit"
pr_commit two.txt 2
run "$WT" 123
check "fast-forward: exit 0" "0" "$rc"
check "fast-forward: worktree moved" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
check "fast-forward: no second worktree" "2" "$(git -C "$CLONE" worktree list | wc -l | tr -d ' ')"

echo "dirty worktree"
pr_commit three.txt 3
echo edit >>"$WT/one.txt"
before="$(git -C "$WT" rev-parse HEAD)"
run "$CLONE" 123
check "dirty: exit 1" "1" "$rc"
contains "dirty: says what to do" "review-pr --done 123" "$out"
check "dirty: HEAD unchanged" "$before" "$(git -C "$WT" rev-parse HEAD)"
check "dirty: edit kept" "edit" "$(tail -1 "$WT/one.txt")"
run "$CLONE" --done 123
[[ $rc -ne 0 ]] && ok "done dirty: refuses" || bad "done dirty: refuses"
contains "done dirty: git's error passes through" "contains modified or untracked files" "$out"
[[ -d "$WT" ]] && ok "done dirty: worktree kept" || bad "done dirty: worktree kept"
git -C "$CLONE" rev-parse --verify -q pr-123 >/dev/null && ok "done dirty: branch kept" || bad "done dirty: branch kept"
git -C "$WT" checkout -q one.txt
run "$CLONE" 123
check "after cleaning: fast-forwards" "0" "$rc"

echo "force-push"
git -C "$ROOT/seed" reset -q --hard main
pr_commit other.txt x
before="$(git -C "$WT" rev-parse HEAD)"
run "$CLONE" 123
check "force-push: exit 1" "1" "$rc"
contains "force-push: says what to do" "force-pushed" "$out"
contains "force-push: points to --done" "review-pr --done 123" "$out"
check "force-push: HEAD unchanged" "$before" "$(git -C "$WT" rev-parse HEAD)"
check "force-push: work still there" "3" "$(cat "$WT/three.txt")"

echo "done"
env -u TMUX tmux -S "$SOCK" -f /dev/null new-session -d -s t -n review:pr-123 "sleep 300"
run "$CLONE" --done 123
check "done clean: exit 0" "0" "$rc"
[[ ! -d "$WT" ]] && ok "done clean: worktree removed" || bad "done clean: worktree removed"
git -C "$CLONE" rev-parse --verify -q pr-123 >/dev/null && bad "done clean: branch removed" || ok "done clean: branch removed"
check "done clean: no tmux note outside tmux" "0" "$(grep -c 'tmux window' <<<"$out")"
run "$CLONE" 123
check "reopen after done: exit 0" "0" "$rc"
check "reopen after done: at the force-pushed head" "$(git -C "$ROOT/seed" rev-parse prsrc)" "$(git -C "$WT" rev-parse HEAD)"
rc=0
out="$(cd "$CLONE" && TMUX="$SOCK,1,0" PATH="$STUBS:$PATH" bash "$SCRIPT" --done 123 2>&1)" || rc=$?
check "done in tmux: exit 0" "0" "$rc"
contains "done in tmux: mentions the open window" "review:pr-123 is still open" "$out"
check "done in tmux: window not killed" "review:pr-123" "$(env -u TMUX tmux -S "$SOCK" list-windows -F '#{window_name}')"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
