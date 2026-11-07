#!/usr/bin/env bash
# Tests bin/.local/bin/review with temp git repos and a stub nvim on PATH. Run: bash tests/review_test.sh
# Never starts tmux. Exits non-zero when a check fails.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)" # resolved, so paths match what git prints
trap 'rm -rf "$ROOT"' EXIT
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
printf '#!/bin/sh\necho "nvim $*"\n' >"$STUBS/nvim"
chmod +x "$STUBS/nvim"
SCRIPT="$SRC/bin/.local/bin/review"
run() { PATH="$STUBS:$PATH" bash "$SCRIPT" "$@" 2>&1 || true; }

# mkrepo <path> <default branch>: a repo on that default branch with a fake origin and origin/HEAD set.
mkrepo() {
  git init -q -b "$2" "$1"
  git -C "$1" commit -q --allow-empty -m init
  git init -q --bare "$1.origin"
  git -C "$1" remote add origin "$1.origin"
  git -C "$1" push -q origin "$2"
  git -C "$1" remote set-head origin "$2" >/dev/null
}

# Feature folder: api (main) with a commit and an untracked file, web (master, no origin/HEAD) with no changes.
mkdir -p "$ROOT/feat"
mkrepo "$ROOT/feat/api" main
git -C "$ROOT/feat/api" checkout -q -b feature
echo a >"$ROOT/feat/api/a.txt"
git -C "$ROOT/feat/api" add a.txt
git -C "$ROOT/feat/api" commit -q -m "add a"
echo b >"$ROOT/feat/api/b.txt" # untracked
mkrepo "$ROOT/feat/web" master
git -C "$ROOT/feat/web" remote set-head origin -d >/dev/null # falls back to origin/master
mkdir -p "$ROOT/feat/notes"

out="$(run --print "$ROOT/feat")"
mb="$(git -C "$ROOT/feat/api" merge-base origin/main HEAD)"
contains "feature folder: api line" "api: branch feature, base origin/main, 1 changed files, 1 untracked" "$out"
contains "feature folder: api command" "cd $ROOT/feat/api && nvim -c \"DiffviewOpen $mb\"" "$out"
contains "feature folder: web falls back to origin/master" "web: branch master, base origin/master, 0 changed files, 0 untracked" "$out"
contains "feature folder: web without changes is skipped" "no changes: nothing to open" "$out"
check "feature folder: only api has a command" "1" "$(grep -c 'nvim -c' <<<"$out")"
check "feature folder: notes is not listed" "0" "$(grep -c '^notes' <<<"$out")"

# Uncommitted edit to a tracked file counts as changed.
echo more >>"$ROOT/feat/api/a.txt"
contains "uncommitted edit counts" "api: branch feature, base origin/main, 1 changed files" "$(run --print "$ROOT/feat/api")"
git -C "$ROOT/feat/api" checkout -q a.txt

# Inside a subfolder of a repo: the repo root is used.
mkdir -p "$ROOT/feat/api/sub"
contains "subfolder of a repo: uses the repo root" "cd $ROOT/feat/api && nvim" "$(run --print "$ROOT/feat/api/sub")"

# Single repo, outside tmux: exec nvim in the repo.
check "single repo, no tmux: opens nvim" "nvim -c DiffviewOpen $mb" "$(run "$ROOT/feat/api" | tail -1)"

# Several repos with changes, outside tmux: prints the commands and exits 0.
echo w >"$ROOT/feat/web/w.txt"
out="$(PATH="$STUBS:$PATH" bash "$SCRIPT" "$ROOT/feat" 2>&1)"
contains "several repos, no tmux: hint" "Not in tmux: run one of the commands above" "$out"
check "several repos, no tmux: nvim not started" "0" "$(grep -c '^nvim ' <<<"$out")"

# Folder with no repos: error, exit 1.
mkdir -p "$ROOT/empty/plain"
rc=0
out="$(PATH="$STUBS:$PATH" bash "$SCRIPT" --print "$ROOT/empty" 2>&1)" || rc=$?
check "no repos: exit 1" "1" "$rc"
contains "no repos: message" "review: no git repo in $ROOT/empty" "$out"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
