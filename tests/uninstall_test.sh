#!/usr/bin/env bash
# Tests uninstall.sh against a temp HOME that holds a clone of this repo. Run: bash tests/uninstall_test.sh
# Exits non-zero on the first failed check group. Needs git; uses stow too when it is installed.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test (working tree, committed or not)
PKGS=(zsh nvim tmux vim git lazygit starship mise atuin bin theme)
PASS=0
FAIL=0
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
check() { # check "<description>" <test command...>
  local desc="$1"
  shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}
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
  git init -q --bare "$origin"
  git -C "$work" push -q "$origin" main
  git clone -q "$origin" "$clone"
  rm -rf "$work"
}

# Build a fake installed machine in $1/home. $2 = stow or plain (the fallback symlinks).
make_machine() {
  local base="$1" mode="$2" h="$1/home" pkg f rel
  mkdir -p "$h"
  make_clone "$base/origin.git" "$h/dotfiles"
  if [[ "$mode" == stow ]]; then
    stow --restow --no-folding --dir="$h/dotfiles" --target="$h" "${PKGS[@]}" 2>/dev/null
  else
    for pkg in "${PKGS[@]}"; do
      while IFS= read -r -d '' f; do
        rel="${f#"$h/dotfiles/$pkg/"}"
        mkdir -p "$(dirname "$h/$rel")"
        ln -sfn "$f" "$h/$rel"
      done < <(find "$h/dotfiles/$pkg" -type f -print0)
    done
  fi
  # backups: two for .zshrc (the newer must win), one each for .gitconfig and mise
  echo old >"$h/.zshrc.backup-20260101-000000"
  echo newest >"$h/.zshrc.backup-20260301-000000"
  echo gitconfig >"$h/.gitconfig.backup-20260301-000000"
  echo mise-orig >"$h/.local/bin/mise.backup-20260301-000000"
  echo "not ours" >"$h/.config/starship.toml.backup-20260301-000000"
  # a real file at a package path stays: it is not a link into the repo
  rm -f "$h/.config/starship.toml"
  echo mine >"$h/.config/starship.toml"
  echo secret >"$h/.zshrc.local"
  # generated data
  mkdir -p "$h/.local/share/zsh-plugins/fzf-tab" "$h/.cache/zsh" "$h/.config/tmux/plugins/tpm" \
    "$h/.local/share/atuin" "$h/.local/share/nvim/lazy" "$h/.local/state/nvim" "$h/.cache/nvim" \
    "$h/.local/share/mise/installs" "$h/.local/state/mise" "$h/.cache/mise" "$h/.local/share/theme/themes" \
    "$h/.cache/theme" "$h/.local/share/fonts/MonaspaceNerdFont" "$h/.vim/undo" "$h/.config/ghostty/themes"
  echo db >"$h/.local/share/atuin/history.db"
  echo x >"$h/.local/share/zsh-plugins/fzf-tab/a.zsh"
  echo dark >"$h/.local/state/theme"
  echo id >"$h/.config/git/local"
  echo c >"$h/.config/ghostty/theme.conf"
  echo z >"$h/.zcompdump"
  echo bin >"$h/.local/bin/mise"
  chmod +x "$h/.local/bin/mise"
}

# Run uninstall.sh from the clone inside the machine. Usage: run_un <base> [flags]; PATH_OVERRIDE sets PATH.
run_un() {
  local base="$1"
  shift
  (cd "$base/home/dotfiles" && env HOME="$base/home" PATH="${PATH_OVERRIDE:-$PATH}" /bin/bash ./uninstall.sh "$@")
}

snapshot() { (cd "$1" && find . -print | sort; find . -type l -exec readlink {} \; | sort; find . -type f -not -path './dotfiles/.git/*' -exec cksum {} \; | sort); }

# Checks shared by every full run: links gone, newest backups back, data gone, real file kept.
assert_uninstalled() {
  local h="$1/home"
  check "zshrc link removed and newest backup restored" has_text "$h/.zshrc" newest
  check "older backup left in place" test -e "$h/.zshrc.backup-20260101-000000"
  check "gitconfig backup restored" has_text "$h/.gitconfig" gitconfig
  check "mise binary replaced by its backup" has_text "$h/.local/bin/mise" mise-orig
  check "no link into the repo remains" test -z "$(find "$h" -path "$h/dotfiles" -prune -o -type l -print | while read -r l; do readlink "$l" | grep -q dotfiles && echo "$l"; done)"
  check "real file at a package path is kept" has_text "$h/.config/starship.toml" mine
  check "its backup is kept" test -e "$h/.config/starship.toml.backup-20260301-000000"
  check "unrelated ~/.zshrc.local is kept" has_text "$h/.zshrc.local" secret
  for p in .local/share/zsh-plugins .cache/zsh .config/tmux/plugins .local/share/atuin .local/share/nvim \
    .local/state/nvim .cache/nvim .local/share/mise .local/state/mise .cache/mise .local/state/theme \
    .config/git/local .config/ghostty/theme.conf .local/share/fonts/MonaspaceNerdFont .zcompdump .vim/undo; do
    check "data removed: $p" gone "$h/$p"
  done
}

echo "== dry run changes nothing"
B="$ROOT/dry"
make_machine "$B" plain
before="$(snapshot "$B/home")"
out="$(run_un "$B" --dry-run 2>&1)" || { echo "$out"; bad "dry run exits 0"; }
after="$(snapshot "$B/home")"
check "dry run left every file as it was" test "$before" = "$after"
check "dry run printed a plan" grep -q "This will remove" <<<"$out"
check "dry run printed dry-run actions" grep -q "\[dry-run\] rm" <<<"$out"

echo "== answering no changes nothing"
B="$ROOT/no"
make_machine "$B" plain
before="$(snapshot "$B/home")"
echo n | run_un "$B" >/dev/null 2>&1
after="$(snapshot "$B/home")"
check "prompt 'n' left every file as it was" test "$before" = "$after"

echo "== --yes with plain symlinks and no stow"
B="$ROOT/plain"
make_machine "$B" plain
SHIM="$ROOT/shim"
mkdir -p "$SHIM"
for f in /usr/bin/* /bin/*; do [[ "$(basename "$f")" == stow ]] || ln -sf "$f" "$SHIM/$(basename "$f")" 2>/dev/null || true; done
PATH_OVERRIDE="$SHIM" run_un "$B" --yes --keep-repo >"$ROOT/plain.out" 2>&1 || { cat "$ROOT/plain.out"; bad "exit 0"; }
assert_uninstalled "$B"
check "--keep-repo keeps the clone" test -d "$B/home/dotfiles/.git"
check "summary lists skipped clone" grep -q "kept: --keep-repo" "$ROOT/plain.out"

if command -v stow >/dev/null 2>&1; then
  echo "== --yes with stow links, clean clone is removed"
  B="$ROOT/stow"
  make_machine "$B" stow
  run_un "$B" --yes >"$ROOT/stow.out" 2>&1 || { cat "$ROOT/stow.out"; bad "exit 0"; }
  assert_uninstalled "$B"
  check "clean clone removed last" gone "$B/home/dotfiles"
else
  echo "== stow is not installed here: the stow path is not tested"
fi

echo "== dirty clone is kept"
B="$ROOT/dirty"
make_machine "$B" plain
echo change >>"$B/home/dotfiles/README.md"
run_un "$B" --yes >"$ROOT/dirty.out" 2>&1 || { cat "$ROOT/dirty.out"; bad "exit 0"; }
assert_uninstalled "$B"
check "dirty clone kept" test -d "$B/home/dotfiles/.git"
check "reason is reported" grep -q "uncommitted changes" "$ROOT/dirty.out"

echo "== clone with an unpushed commit is kept"
B="$ROOT/unpushed"
make_machine "$B" plain
git -C "$B/home/dotfiles" commit -q --allow-empty -m local
run_un "$B" --yes >"$ROOT/unpushed.out" 2>&1 || { cat "$ROOT/unpushed.out"; bad "exit 0"; }
check "unpushed clone kept" test -d "$B/home/dotfiles/.git"
check "reason is reported" grep -q "not on any remote" "$ROOT/unpushed.out"

echo "== --with-claude undoes the Claude links and removes a clean clone"
B="$ROOT/claude"
make_machine "$B" plain
h="$B/home"
make_clone "$B/claude-origin.git" "$h/.config/claude-shared"
mkdir -p "$h/.config/claude-shared/skills/foo" "$h/.claude/skills" "$h/.claude-personal"
git -C "$h/.config/claude-shared" add -A
git -C "$h/.config/claude-shared" commit -q --allow-empty -m skills
git -C "$h/.config/claude-shared" push -q origin HEAD:main
ln -s "$h/.config/claude-shared/skills/foo" "$h/.claude/skills/foo"
echo bak >"$h/.claude-personal/CLAUDE.md.bak-20260101000000"
ln -s "$h/.config/claude-shared/CLAUDE.md" "$h/.claude-personal/CLAUDE.md"
printf 'export A=1\n\n# Claude Code accounts\nsource "%s/.config/claude-shared/zsh/claude.zsh"\n' "$h" >"$h/.zshrc.local"
run_un "$B" --yes --keep-repo >"$ROOT/claude0.out" 2>&1 || { cat "$ROOT/claude0.out"; bad "exit 0"; }
check "without --with-claude the clone is kept" test -d "$h/.config/claude-shared"
check "without --with-claude its links are kept" is_link "$h/.claude/skills/foo"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --keep-repo --with-claude >"$ROOT/claude1.out" 2>&1) || { cat "$ROOT/claude1.out"; bad "exit 0"; }
check "Claude skill link removed" gone "$h/.claude/skills/foo"
check "Claude backup restored" has_text "$h/.claude-personal/CLAUDE.md" bak
check "claude.zsh line removed, other lines kept" has_text "$h/.zshrc.local" "export A=1"
check "Claude clone removed" gone "$h/.config/claude-shared"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
