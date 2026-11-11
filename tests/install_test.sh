#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests install.sh against a temp HOME. Offline and side-effect free: stub brew, mise, curl, pkill and
# pgrep sit first on PATH, a git wrapper fakes GitHub clones, THEME_NO_RELOAD=1 keeps Ghostty alone, and stdin
# is /dev/null. Run: bash tests/install_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export HOME="$ROOT/home"
mkdir -p "$HOME"
export THEME_NO_RELOAD=1

# Stubs for everything that would install packages or touch the real system.
STUBS="$ROOT/stubs"
mkdir -p "$STUBS"
for t in brew mise curl pkill pgrep; do
  printf '#!/bin/sh\n[ "$1" = --prefix ] && echo "%s/brew-prefix"\nexit 0\n' "$ROOT" >"$STUBS/$t"
done
printf '#!/bin/sh\nexit 1\n' >"$STUBS/pgrep" # no Ghostty running
# shellcheck disable=SC2016
printf '#!/bin/sh\n[ "$1" = bundle ] && [ -n "${BREW_FAIL:-}" ] && exit 1\n[ "$1" = --prefix ] && echo "%s/brew-prefix"\nexit 0\n' "$ROOT" >"$STUBS/brew"
REAL_GIT="$(command -v git)"
# A clone of a github.com URL only creates the folder; every other git call is real.
cat >"$STUBS/git" <<G
#!/bin/bash
for a in "\$@"; do
  if [[ \$a == https://github.com/* ]]; then
    mkdir -p "\${@: -1}"
    exit 0
  fi
done
exec "$REAL_GIT" "\$@"
G
chmod +x "$STUBS"/*

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
  OUT="$(env HOME="$HOME" PATH="$STUBS:$PATH" bash "$SRC/install.sh" "$@" 2>&1 </dev/null)" || RC=$?
}

# True when the last run failed with exit 1 and its output contains $1.
failed_with() { [[ $RC -eq 1 ]] && grep -qF -- "$1" <<<"$OUT"; }

echo "== dry run clones, then runs pull.sh --install"
run_install --dry-run --with-claude "$ROOT/none.git"
check "clone not yet there" grep -qE "git clone .*none.git .*claude-shared$" <<<"$OUT"
check "pull.sh --install is called" grep -qE "claude-shared/pull.sh --install$" <<<"$OUT"

echo "== a real clone: pull.sh --install runs once"
origin="$ROOT/claude-origin.git"
stub="$ROOT/claude-stub"
mkdir -p "$stub"
printf '#!/bin/bash\necho "$*" >> "$HOME/pull-calls"\n' >"$stub/pull.sh"
chmod +x "$stub/pull.sh"
git -C "$stub" init -q -b main
git -C "$stub" add pull.sh
git -C "$stub" -c user.name=t -c user.email=t@example.com commit -q -m init
git init -q -b main --bare "$origin"
git -C "$stub" push -q "$origin" main
claude_dir="$HOME/.config/claude-shared"
run_install --with-claude "$origin"
check "missing: it is cloned" test -f "$claude_dir/pull.sh"
check "missing: pull.sh ran once with --install" bash -c '[[ "$(cat "$1")" == "--install" ]]' _ "$HOME/pull-calls"
rm -f "$HOME/pull-calls"
run_install --with-claude "$origin"
check "existing: pull.sh ran once with --install" bash -c '[[ "$(cat "$1")" == "--install" ]]' _ "$HOME/pull-calls"

echo "== a clone that fails is reported"
rm -rf "$claude_dir"
run_install --with-claude "$ROOT/missing.git"
check "exit 1 and a warning" failed_with "could not clone"

echo "== a folder that is not a git repo is skipped"
mkdir -p "$claude_dir"
run_install --with-claude "$origin"
check "exit 1 and a warning" failed_with "is not a git repo"

echo "== backup step and linking (real run against the temp HOME)"
bhome="$ROOT/backup-home"
mkdir -p "$bhome"
echo mine >"$bhome/.zshrc"
echo gitconfig >"$bhome/.gitconfig"
mkdir -p "$bhome/.config/starship"
echo mine >"$bhome/.config/starship.toml"
run_in() { # run_in <home> [flags]: a real install with that HOME
  RC=0
  OUT="$(env HOME="$1" PATH="$STUBS:$PATH" bash "$SRC/install.sh" "${@:2}" 2>&1 </dev/null)" || RC=$?
}
run_in "$bhome"
check "first install: exit 0" test "$RC" -eq 0
check "a real file is moved to .backup-<stamp>" bash -c 'cat "$1"/.zshrc.backup-* | grep -qx mine' _ "$bhome"
check "the backup message names both paths" grep -qE "backup: .*/\.zshrc -> .*/\.zshrc\.backup-[0-9]{8}-[0-9]{6}" <<<"$OUT"
check "the path is now a link into the repo" bash -c '[[ -L "$1/.zshrc" && "$(realpath "$1/.zshrc")" == "$2"/* ]]' _ "$bhome" "$(cd "$SRC" && pwd -P)"
check "the old gitconfig is backed up too" bash -c 'grep -qx gitconfig "$1"/.gitconfig.backup-*' _ "$bhome"
check "the old gitconfig is gone, so config/git applies" bash -c '[[ ! -e "$1/.gitconfig" ]]' _ "$bhome"
check "another package file is backed up" bash -c 'grep -qx mine "$1"/.config/starship.toml.backup-*' _ "$bhome"
before="$(ls -A "$bhome" | sort | tr '\n' ' ')"
sleep 1 # a new stamp would show as a new backup name
run_in "$bhome"
check "second install: exit 0" test "$RC" -eq 0
check "existing repo links are left alone: no new backups" test "$before" = "$(ls -A "$bhome" | sort | tr '\n' ' ')"
check "no backup message on the second run" bash -c '! grep -q "^backup:" <<<"$1"' _ "$OUT"

echo "== brew bundle failure does not stop the install"
if [[ "$OSTYPE" == darwin* ]]; then
  fhome="$ROOT/brew-fail-home"
  mkdir -p "$fhome"
  RC=0
  OUT="$(env HOME="$fhome" BREW_FAIL=1 PATH="$STUBS:$PATH" bash "$SRC/install.sh" 2>&1 </dev/null)" || RC=$?
  check "exit 0" test "$RC" -eq 0
  check "warning printed" grep -qF "Warning: brew bundle failed; run 'brew bundle' later" <<<"$OUT"
  check "later steps still ran" grep -qF "Linking packages" <<<"$OUT"
fi

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
