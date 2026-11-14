#!/usr/bin/env bash
# Tests zsh/.zshrc settings in a temp HOME. Run: bash tests/zshrc_test.sh
# Exits non-zero when a check fails. Needs zsh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT


if ! command -v zsh >/dev/null; then
  echo "zsh not installed: skipped"
  exit 0
fi

H="$ROOT/home"
mkdir -p "$H"
ln -s "$SRC/zsh/.zshrc" "$H/.zshrc"
zrun() { env HOME="$H" XDG_CACHE_HOME="$ROOT/cache" ZDOTDIR="$H" zsh -i -c "$1" 2>&1; }

# shellcheck disable=SC2016 # the zsh code must reach zsh unexpanded
check "history uses fcntl locking" test "$(zrun 'print ${options[histfcntllock]}' | tail -n 1)" = on

# a stale temp file from an interrupted start is removed when a cache is regenerated
mkdir -p "$H/.local/bin" "$ROOT/cache/zsh"
printf '#!/bin/sh\necho true\n' >"$H/.local/bin/fzf" # fake fzf: `fzf --zsh` is cached by the zshrc
chmod +x "$H/.local/bin/fzf"
: >"$ROOT/cache/zsh/fzf.__zsh.zsh.12345"
zrun 'true' >/dev/null || true
check "cache file written" test -s "$ROOT/cache/zsh/fzf.__zsh.zsh"
check "stale cache temp file removed" test ! -e "$ROOT/cache/zsh/fzf.__zsh.zsh.12345"

summary
