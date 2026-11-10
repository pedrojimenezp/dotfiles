#!/usr/bin/env bash
# Tests git wip / git pr (bin/.local/bin/git-changes) with temp repos and a stub delta. Run: bash tests/git_changes_test.sh
# Exits non-zero when a check fails.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
export GIT_CONFIG_GLOBAL="$SRC/git/.config/git/config"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p "$HOME"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
has() { case "$3" in *"$2"*) ok "$1" ;; *) bad "$1 (missing: $2 in: $3)" ;; esac; }
lacks() { case "$3" in *"$2"*) bad "$1 (found: $2 in: $3)" ;; *) ok "$1" ;; esac; }

# The stub delta prints the side-by-side setting, then the diff it received.
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
printf '#!/bin/sh\necho "features=${DELTA_FEATURES:-}"\ncat\n' >"$STUBS/delta"
chmod +x "$STUBS/delta"
export PATH="$STUBS:$SRC/bin/.local/bin:$PATH"

# mkrepo <path> <default branch>: a repo with one commit, a fake origin and origin/HEAD set.
mkrepo() {
  git init -q -b "$2" "$1"
  git -C "$1" commit -q --allow-empty -m init
  git init -q --bare "$1.origin"
  git -C "$1" remote add origin "$1.origin"
  git -C "$1" push -q origin "$2"
  git -C "$1" remote set-head origin "$2" >/dev/null
}

R="$ROOT/repo"
mkrepo "$R" main
cd "$R"
mkdir sub
echo one >tracked.txt && echo one >staged.txt && echo one >sub/in.txt
echo ignored.log >.gitignore
git add . && git commit -q -m base
echo "== git wip"
out="$(git wip)"
has "clean repo says so" "No uncommitted changes." "$out"

echo two >>tracked.txt
echo two >>staged.txt && git add staged.txt
echo new >untracked.txt
echo new >"with space.txt"
echo new >sub/new.txt
echo secret >ignored.log
before="$(git status --porcelain)"
out="$(git wip)"
has "unstaged change" "+two" "$out"
has "staged change" "staged.txt" "$out"
has "untracked file" "untracked.txt" "$out"
has "untracked file with a space" "with space.txt" "$out"
lacks "ignored file hidden" "ignored.log" "$out"
has "one column by default" "features=" "$out"
lacks "no side-by-side by default" "side-by-side" "$out"
if [[ "$before" == "$(git status --porcelain)" ]]; then ok "index untouched"; else bad "index changed"; fi
out="$(cd sub && git wip)"
has "untracked in subdir, run from subdir" "sub/new.txt" "$out"
has "tracked file outside the subdir" "tracked.txt" "$out"
out="$(git wip -s)"
has "wip -s is side by side" "features=+side-by-side" "$out"

echo "== git pr"
git checkout -q -b feat
git add -A . && git commit -q -m feat
echo more >>tracked.txt
echo late >late.txt
out="$(git pr)"
has "origin/HEAD base: committed change" "untracked.txt" "$out"
has "origin/HEAD base: uncommitted change" "+more" "$out"
has "origin/HEAD base: untracked" "late.txt" "$out"
lacks "ignored hidden in pr" "+secret" "$out"
git remote set-head origin -d >/dev/null
out="$(git pr)"
has "origin/HEAD unset falls back to origin/main" "untracked.txt" "$out"
git push -q origin main:dev
git fetch -q origin
git commit -q --allow-empty -m "dev only"
out="$(git pr dev)"
has "explicit base" "late.txt" "$out"
has "explicit base uses origin/dev" "untracked.txt" "$out"
out="$(git pr -s dev)"
has "-s before base" "features=+side-by-side" "$out"
out="$(git pr dev -s)"
has "-s after base" "features=+side-by-side" "$out"
out="$(git pr nope 2>&1 || true)"
has "unknown base errors" "no branch 'nope'" "$out"
git stash -q -u
git reset -q --hard origin/main
git clean -fdq
out="$(git pr)"
has "empty pr says so" "No changes since" "$out"

echo "== fallbacks without origin"
L="$ROOT/local"
git init -q -b master "$L"
cd "$L"
git commit -q --allow-empty -m init
git checkout -q -b topic
echo x >x.txt
out="$(git pr)"
has "local master is the base" "x.txt" "$out"
out="$(git wip)"
has "wip in a repo without origin" "x.txt" "$out"
git init -q -b main "$ROOT/fresh"
cd "$ROOT/fresh"
echo y >y.txt
out="$(git wip)"
has "wip before the first commit" "y.txt" "$out"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
