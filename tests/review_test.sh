#!/usr/bin/env bash
# Tests bin/.local/bin/review with temp git repos and a stub nvim on PATH. Run: bash tests/review_test.sh
# Never starts tmux. Exits non-zero when a check fails.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(cd "$(mktemp -d)" && pwd -P)" # resolved, so paths match what git prints
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 HOME="$ROOT/home"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p "$HOME"
unset TMUX


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
check_eq "feature folder: only api has a command" "1" "$(grep -c 'nvim -c' <<<"$out")"
check_eq "feature folder: notes is not listed" "0" "$(grep -c '^notes' <<<"$out")"

# Base argument: a short name prefers origin/<name>, then the local ref; dir and base come in either order.
git -C "$ROOT/feat/api" branch -q dev main
git -C "$ROOT/feat/api" push -q origin dev
git -C "$ROOT/feat/api" branch -q local-only main
out="$(run --print "$ROOT/feat/api")"
contains "no base: default origin/main" "api: branch feature, base origin/main," "$out"
out="$(run --print dev "$ROOT/feat/api")"
contains "base then dir: origin/dev" "api: branch feature, base origin/dev," "$out"
out="$(run --print "$ROOT/feat/api" dev)"
contains "dir then base: origin/dev" "api: branch feature, base origin/dev," "$out"
out="$(cd "$ROOT/feat/api" && PATH="$STUBS:$PATH" bash "$SCRIPT" --print dev 2>&1)"
contains "base only: current folder" "api: branch feature, base origin/dev," "$out"
out="$(run --print local-only "$ROOT/feat/api")"
contains "base without origin ref: local ref" "api: branch feature, base local-only," "$out"
out="$(run --print origin/main "$ROOT/feat/api")"
contains "full ref name as base" "api: branch feature, base origin/main," "$out"
rc=0
out="$(PATH="$STUBS:$PATH" bash "$SCRIPT" --print nope "$ROOT/feat/api" 2>&1)" || rc=$?
check_eq "unknown base: exit 1" "1" "$rc"
contains "unknown base: message" "review: no branch 'nope' in any repo" "$out"
# Feature folder where only api has the base: web is skipped with a message, api is reviewed.
out="$(run --print dev "$ROOT/feat")"
contains "multi repo: repo with the base" "api: branch feature, base origin/dev," "$out"
contains "multi repo: repo without the base is skipped" "web: branch master, no branch 'dev': skipped" "$out"
rc=0
PATH="$STUBS:$PATH" bash "$SCRIPT" --print dev dev "$ROOT/feat" >/dev/null 2>&1 || rc=$?
check_eq "two bases: usage error" "2" "$rc"

rc=0
PATH="$STUBS:$PATH" bash "$SCRIPT" --name >/dev/null 2>&1 || rc=$?
check_eq "--name without a value: usage error" "2" "$rc"

# -u: the gitsigns unified panel with the same merge-base; the default stays diffview.
uni="nvim -c \"lua require('gitsigns').diff('$mb', nil, { diff = 'unified' })\""
out="$(run --print -u "$ROOT/feat/api")"
contains "-u: gitsigns command" "cd $ROOT/feat/api && $uni" "$out"
check_eq "-u: no diffview" "0" "$(grep -c DiffviewOpen <<<"$out")"
contains "default: still diffview" "DiffviewOpen $mb" "$(run --print "$ROOT/feat/api")"
out="$(run --print -u dev "$ROOT/feat/api")"
contains "-u base dir: origin/dev" "base origin/dev," "$out"
contains "-u base dir: gitsigns command" "&& nvim -c \"lua require('gitsigns').diff('$(git -C "$ROOT/feat/api" merge-base origin/dev HEAD)'" "$out"
out="$(run --print "$ROOT/feat/api" dev -u)"
contains "dir base -u: origin/dev" "base origin/dev," "$out"
contains "dir base -u: gitsigns command" "diff = 'unified'" "$out"
out="$(run --print dev -u "$ROOT/feat/api")"
contains "base -u dir: gitsigns command" "diff = 'unified'" "$out"
contains "-h mentions -u" "-u opens gitsigns" "$(run -h)"
check_eq "-u, single repo, no tmux: opens nvim" "nvim -c lua require('gitsigns').diff('$mb', nil, { diff = 'unified' })" "$(run -u "$ROOT/feat/api" | tail -1)"

# Uncommitted edit to a tracked file counts as changed.
echo more >>"$ROOT/feat/api/a.txt"
contains "uncommitted edit counts" "api: branch feature, base origin/main, 1 changed files" "$(run --print "$ROOT/feat/api")"
git -C "$ROOT/feat/api" checkout -q a.txt

# Inside a subfolder of a repo: the repo root is used.
mkdir -p "$ROOT/feat/api/sub"
contains "subfolder of a repo: uses the repo root" "cd $ROOT/feat/api && nvim" "$(run --print "$ROOT/feat/api/sub")"

# Feature folder of worktrees nested inside an outer repo that ignores it: the inner repos, not the outer one.
mkrepo "$ROOT/outer" main
echo "worktrees/" >"$ROOT/outer/.gitignore"
git -C "$ROOT/outer" add .gitignore
git -C "$ROOT/outer" commit -q -m ignore
mkdir -p "$ROOT/outer/worktrees/feat"
for r in api web; do
  git -C "$ROOT/outer" worktree add -q -b "f-$r" "$ROOT/outer/worktrees/feat/$r" HEAD
  echo x >"$ROOT/outer/worktrees/feat/$r/x.txt" # untracked
done
out="$(run --print "$ROOT/outer/worktrees/feat")"
contains "nested feature folder: api listed" "cd $ROOT/outer/worktrees/feat/api && nvim" "$out"
contains "nested feature folder: web listed" "cd $ROOT/outer/worktrees/feat/web && nvim" "$out"
check_eq "nested feature folder: outer repo not listed" "0" "$(grep -c '^outer' <<<"$out")"

# Top level of a repo that also holds a nested repo folder: that repo, not the nested one.
mkrepo "$ROOT/top" main
echo t >"$ROOT/top/t.txt"
mkrepo "$ROOT/top/inner" main
out="$(run --print "$ROOT/top")"
contains "top level with nested repo: reviews the top repo" "top: branch main" "$out"
check_eq "top level with nested repo: inner not listed" "0" "$(grep -c '^inner' <<<"$out")"

# Subfolder of a single repo: that repo.
mkdir -p "$ROOT/top/src/deep"
contains "subfolder of a single repo: reviews the repo" "cd $ROOT/top && nvim" "$(run --print "$ROOT/top/src/deep")"

# Single repo, outside tmux: exec nvim in the repo.
check_eq "single repo, no tmux: opens nvim" "nvim -c DiffviewOpen $mb" "$(run "$ROOT/feat/api" | tail -1)"

# Several repos with changes, outside tmux: prints the commands and exits 0.
echo w >"$ROOT/feat/web/w.txt"
out="$(PATH="$STUBS:$PATH" bash "$SCRIPT" "$ROOT/feat" 2>&1)"
rc=0
PATH="$STUBS:$PATH" bash "$SCRIPT" --name x "$ROOT/feat" >/dev/null 2>&1 || rc=$?
check_eq "--name with several repos: exit 2" "2" "$rc"
contains "several repos, no tmux: hint" "Not in tmux: run one of the commands above" "$out"
check_eq "several repos, no tmux: nvim not started" "0" "$(grep -c '^nvim ' <<<"$out")"

# Folder with no repos: error, exit 1.
mkdir -p "$ROOT/empty/plain"
rc=0
out="$(PATH="$STUBS:$PATH" bash "$SCRIPT" --print "$ROOT/empty" 2>&1)" || rc=$?
check_eq "no repos: exit 1" "1" "$rc"
contains "no repos: message" "review: no git repo in $ROOT/empty" "$out"

summary
