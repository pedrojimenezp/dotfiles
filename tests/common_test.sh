#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests common.sh: which folders are stow packages, and which apply on this machine.
# Run: bash tests/common_test.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$ROOT"' EXIT

REPO="$ROOT/repo"
mkdir -p "$REPO"/{zsh,git,iterm,skhd,ghostty,docs,tests,work,worktrees,.hidden}
touch "$REPO/Brewfile"
source "$SRC/common.sh"

joined() { tr '\n' ' ' | sed 's/ $//'; }

echo "== packages_all"
check_eq "every folder but docs, tests, work, worktrees and hidden ones" "ghostty git iterm skhd zsh" "$(packages_all | joined)"
check_eq "files at the root are not packages" "0" "$(packages_all | grep -c Brewfile || true)"
check "the real repo has the core packages" bash -c 'REPO="$1"; source "$1/common.sh"; packages_all | grep -qx zsh && ! packages_all | grep -qxE "docs|tests|work|worktrees"' _ "$SRC"

echo "== packages_here"
NOGHOSTTY="$ROOT/bin-none"
mkdir -p "$NOGHOSTTY" "$ROOT/home"
export HOME="$ROOT/home"
export GHOSTTY_APPS="$HOME/Applications/Ghostty.app" # never the real /Applications
PATH_NO="$NOGHOSTTY:/usr/bin:/bin"
check_eq "macOS without Ghostty: iterm and skhd, no ghostty" "git iterm skhd zsh" "$(PATH="$PATH_NO" OSTYPE=darwin24 packages_here | joined)"
check_eq "Linux without Ghostty: neither" "git zsh" "$(PATH="$PATH_NO" OSTYPE=linux-gnu packages_here | joined)"
mkdir -p "$HOME/Applications/Ghostty.app"
check_eq "Linux with Ghostty.app: ghostty only" "ghostty git zsh" "$(PATH="$PATH_NO" OSTYPE=linux-gnu packages_here | joined)"
rmdir "$HOME/Applications/Ghostty.app"
printf '#!/bin/sh\n' >"$NOGHOSTTY/ghostty"
chmod +x "$NOGHOSTTY/ghostty"
check_eq "ghostty on PATH counts" "ghostty git zsh" "$(PATH="$PATH_NO" OSTYPE=linux-gnu packages_here | joined)"

echo "== with_heartbeat"
DRY=0
out="$(HEARTBEAT_INTERVAL=1 with_heartbeat sleep 2.5)"
check_eq "a silent step prints still running every interval" "still running (1s) still running (2s)" "$(joined <<<"$out")"
out="$(HEARTBEAT_INTERVAL=1 with_heartbeat true)"
check_eq "a quick step prints nothing" "" "$out"
rc=0
HEARTBEAT_INTERVAL=1 with_heartbeat bash -c 'exit 3' || rc=$?
check_eq "the command's status is returned" "3" "$rc"

echo "== step and finish"
check_eq "step prints an arrow line" "==> Doing it" "$(step Doing it)"
check_eq "finish prints the result and a blank line" "Done||" "$(finish Done | tr '\n' '|')"
check_eq "finish marks a dry run" "[dry-run] Done||" "$(DRY=1 finish Done | tr '\n' '|')"

summary
