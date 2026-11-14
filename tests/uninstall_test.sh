#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests uninstall.sh against a temp HOME that holds a clone of this repo. Run: bash tests/uninstall_test.sh
# Needs git and stow.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test (working tree, committed or not)
REPO="$SRC"
source "$SRC/common.sh"
PKGS=()
while IFS= read -r pkg; do PKGS+=("$pkg"); done < <(packages_all)
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

gone() { [[ ! -e "$1" && ! -L "$1" ]]; }
has_text() { [[ "$(cat "$1" 2>/dev/null)" == "$2" ]]; }
is_link() { [[ -L "$1" ]]; }

# Copy the working tree (tracked and new files) to $1, commit it and push it to a bare origin; clone it into $2.
make_clone() {
  local origin="$1" clone="$2" work="$ROOT/work.$$.$RANDOM" f
  mkdir -p "$work"
  while IFS= read -r -d '' f; do
    mkdir -p "$work/$(dirname "$f")"
    cp -p "$SRC/$f" "$work/$f"
  done < <(cd "$SRC" && git ls-files -co --exclude-standard -z)
  git -C "$work" init -q -b main
  git -C "$work" add -A
  git -C "$work" commit -q -m init
  git init -q -b main --bare "$origin"
  git -C "$work" push -q "$origin" main
  git clone -q "$origin" "$clone"
  rm -rf "$work"
}

# Build a fake installed machine in $1/home: the packages stowed, plus the backups install.sh would have made.
make_machine() {
  local base="$1" h="$1/home"
  mkdir -p "$h"
  make_clone "$base/origin.git" "$h/dotfiles"
  stow --restow --no-folding --dir="$h/dotfiles" --target="$h" "${PKGS[@]}" 2>/dev/null
  # backups: two for .zshrc (the newer must win), one for .gitconfig and one for a path that now holds a real file
  echo old >"$h/.zshrc.backup-20260101-000000"
  echo newest >"$h/.zshrc.backup-20260301-000000"
  echo gitconfig >"$h/.gitconfig.backup-20260301-000000"
  echo "not ours" >"$h/.config/starship.toml.backup-20260301-000000"
  # a real file at a package path stays: it is not a link into the repo
  rm -f "$h/.config/starship.toml"
  echo mine >"$h/.config/starship.toml"
  echo secret >"$h/.zshrc.local"
}

# Run uninstall.sh from the clone inside the machine. Usage: run_un <base> [flags]; PATH_OVERRIDE sets PATH.
run_un() {
  local base="$1"
  shift
  (cd "$base/home/dotfiles" && env HOME="$base/home" PATH="${PATH_OVERRIDE:-$PATH}" /bin/bash ./uninstall.sh "$@")
}

snapshot() { (cd "$1" && find . -print | sort; find . -type l -exec readlink {} \; | sort; find . -type f -not -path './dotfiles/.git/*' -exec cksum {} \; | sort); }

# Checks shared by every full run: links gone, newest backups back, real file kept.
assert_uninstalled() {
  local h="$1/home"
  check "zshrc link removed and newest backup restored" has_text "$h/.zshrc" newest
  check "older backup left in place" test -e "$h/.zshrc.backup-20260101-000000"
  check "gitconfig backup restored" has_text "$h/.gitconfig" gitconfig
  check "no link into the repo remains" test -z "$(find "$h" -path "$h/dotfiles" -prune -o -type l -print | while read -r l; do readlink "$l" | grep -q dotfiles && echo "$l"; done)"
  check "real file at a package path is kept" has_text "$h/.config/starship.toml" mine
  check "its backup is kept" test -e "$h/.config/starship.toml.backup-20260301-000000"
  check "unrelated ~/.zshrc.local is kept" has_text "$h/.zshrc.local" secret
  check "this clone is kept" test -d "$h/dotfiles/.git"
}

echo "== dry run changes nothing"
B="$ROOT/dry"
make_machine "$B"
before="$(snapshot "$B/home")"
out="$(run_un "$B" --dry-run 2>&1)" || { echo "$out"; bad "dry run exits 0"; }
after="$(snapshot "$B/home")"
check "dry run left every file as it was" test "$before" = "$after"
check "dry run printed the stow command" grep -q "\[dry-run\] stow --delete" <<<"$out"

echo "== answering no changes nothing"
B="$ROOT/no"
make_machine "$B"
before="$(snapshot "$B/home")"
echo n | run_un "$B" >/dev/null 2>&1
after="$(snapshot "$B/home")"
check "prompt 'n' left every file as it was" test "$before" = "$after"

echo "== --yes unlinks and restores backups"
B="$ROOT/yes"
make_machine "$B"
run_un "$B" --yes >"$ROOT/yes.out" 2>&1 || { cat "$ROOT/yes.out"; bad "exit 0"; }
assert_uninstalled "$B"

echo "== --with-claude runs the Claude installer's --uninstall and removes a clean clone"
B="$ROOT/claude"
make_machine "$B"
h="$B/home"
c="$h/.config/claude-shared"
stub="$ROOT/claude-stub"
mkdir -p "$stub"
printf '#!/bin/bash\necho "$*" >> "$HOME/claude-calls"\n' >"$stub/install.sh"
chmod +x "$stub/install.sh"
git -C "$stub" init -q -b main
git -C "$stub" add install.sh
git -C "$stub" commit -q -m init
git init -q -b main --bare "$B/claude-origin.git"
git -C "$stub" push -q "$B/claude-origin.git" main
git clone -q "$B/claude-origin.git" "$c"
run_un "$B" --yes >"$ROOT/claude0.out" 2>&1 || { cat "$ROOT/claude0.out"; bad "exit 0"; }
check "without --with-claude the clone is kept" test -d "$c"
check "without --with-claude its installer is not called" gone "$h/claude-calls"
run_un "$B" --dry-run --with-claude >"$ROOT/claude3.out" 2>&1 || { cat "$ROOT/claude3.out"; bad "exit 0"; }
check "dry run prints the call and keeps the clone" bash -c 'grep -q "\[dry-run\].*install.sh --uninstall" "$1" && [[ -d "$2" ]]' _ "$ROOT/claude3.out" "$c"
check "dry run does not call it" gone "$h/claude-calls"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --with-claude >"$ROOT/claude1.out" 2>&1) || { cat "$ROOT/claude1.out"; bad "exit 0"; }
check "its installer ran once with --uninstall" has_text "$h/claude-calls" "--uninstall"
check "settings.json copies reported" grep -q "settings.json in each" "$ROOT/claude1.out"
check "Claude clone removed" gone "$c"

echo "== --with-claude keeps the clone when its install.sh is missing or fails"
B="$ROOT/claude-missing"
make_machine "$B"
h="$B/home"
c="$h/.config/claude-shared"
git clone -q "$ROOT/claude/claude-origin.git" "$c"
chmod -x "$c/install.sh"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --with-claude >"$ROOT/claude4.out" 2>&1) || { cat "$ROOT/claude4.out"; bad "exit 0"; }
check "not executable: clone kept" test -d "$c"
check "not executable: reported as skipped" grep -q "install.sh is missing or not executable" "$ROOT/claude4.out"
rm -f "$c/install.sh"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --with-claude >"$ROOT/claude5.out" 2>&1) || { cat "$ROOT/claude5.out"; bad "exit 0"; }
check "missing: clone kept" test -d "$c"
check "missing: reported as skipped" grep -q "install.sh is missing or not executable" "$ROOT/claude5.out"
printf '#!/bin/bash\nexit 3\n' >"$c/install.sh"
chmod +x "$c/install.sh"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --with-claude >"$ROOT/claude6.out" 2>&1) || { cat "$ROOT/claude6.out"; bad "exit 0"; }
check "failing uninstall: clone kept" test -d "$c"
check "failing uninstall: reported as skipped" grep -q "its install.sh --uninstall failed" "$ROOT/claude6.out"
check "summary prints Removed (n)" grep -q "^Removed (" "$ROOT/claude6.out"

summary
