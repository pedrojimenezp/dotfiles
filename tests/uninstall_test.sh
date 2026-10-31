#!/usr/bin/env bash
# Tests uninstall.sh against a temp HOME that holds a clone of this repo. Run: bash tests/uninstall_test.sh
# Exits non-zero on the first failed check group. Needs git; uses stow too when it is installed.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" # the repo under test (working tree, committed or not)
PKGS=(zsh nvim tmux vim git lazygit starship mise bin theme)
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

# Plant links into the clone that the scan misses (its folder is gone, so they cannot be resolved), a broken link
# elsewhere, and a working link. $1 = machine base.
plant_sweep_links() {
  local h="$1/home"
  mkdir -p "$h/.config/x/y"
  ln -s "$h/dotfiles/nope/abs" "$h/.stale-abs"
  ln -s "dotfiles/nope/../nope/rel" "$h/.stale-rel"
  ln -s "$h/dotfiles/nope/deep" "$h/.config/x/y/stale"
  ln -s /nonexistent/elsewhere "$h/.other-broken"
  echo real >"$h/real.txt"
  ln -s "$h/real.txt" "$h/.config/good"
}

echo "== final sweep removes broken links into the deleted clone"
B="$ROOT/sweep"
make_machine "$B" plain
plant_sweep_links "$B"
run_un "$B" --yes >"$ROOT/sweep.out" 2>&1 || { cat "$ROOT/sweep.out"; bad "exit 0"; }
h="$B/home"
check "clone removed" gone "$h/dotfiles"
check "absolute broken link swept" gone "$h/.stale-abs"
check "relative broken link swept" gone "$h/.stale-rel"
check "broken link in a config subfolder swept" gone "$h/.config/x/y/stale"
check "emptied folders pruned" gone "$h/.config/x"
check "unrelated broken link kept" is_link "$h/.other-broken"
check "working link kept" is_link "$h/.config/good"
check "swept links are in the summary" grep -q "$h/.stale-abs" "$ROOT/sweep.out"

echo "== dry run only announces the sweep"
B="$ROOT/sweepdry"
make_machine "$B" plain
plant_sweep_links "$B"
run_un "$B" --dry-run >"$ROOT/sweepdry.out" 2>&1 || { cat "$ROOT/sweepdry.out"; bad "exit 0"; }
check "dry run says the sweep will run" grep -q "final sweep will run" "$ROOT/sweepdry.out"
check "dry run lists no swept link" test -z "$(grep -F "$B/home/.stale-abs" "$ROOT/sweepdry.out" || true)"
check "dry run kept the planted link" is_link "$B/home/.stale-abs"

echo "== no sweep when the clone is kept"
B="$ROOT/sweepdirty"
make_machine "$B" plain
plant_sweep_links "$B"
echo change >>"$B/home/dotfiles/README.md"
run_un "$B" --yes >"$ROOT/sweepdirty.out" 2>&1 || { cat "$ROOT/sweepdirty.out"; bad "exit 0"; }
check "dirty clone kept" test -d "$B/home/dotfiles/.git"
check "sweep step did not run" test -z "$(grep -F "Sweeping for broken links" "$ROOT/sweepdirty.out" || true)"
check "planted link untouched" is_link "$B/home/.stale-abs"

echo "== --with-claude undoes the Claude links and removes a clean clone"
B="$ROOT/claude"
make_machine "$B" plain
h="$B/home"
c="$h/.config/claude-shared"
make_clone "$B/claude-origin.git" "$c"
mkdir -p "$c/skills/foo" "$c/accounts/niche/agents" "$c/accounts/personal/rules" "$h/.claude/skills" \
  "$h/.claude-niche/skills" "$h/.claude-personal" "$h/.pi/agent"
git -C "$c" add -A
git -C "$c" commit -q --allow-empty -m skills
git -C "$c" push -q origin HEAD:main
ln -s "$c/skills/foo" "$h/.claude/skills/foo"                      # legacy folder
ln -s "$c/skills/foo" "$h/.claude-niche/skills/foo"
ln -s "$c/accounts/niche/agents" "$h/.claude-niche/agents"
ln -s "$c/accounts/personal/rules" "$h/.claude-personal/rules"
echo bak >"$h/.claude-personal/CLAUDE.md.bak-20260101000000"
ln -s "$c/CLAUDE.md" "$h/.claude-personal/CLAUDE.md"
ln -s "$c/CLAUDE.md" "$h/.pi/agent/CLAUDE.md"
echo '{}' >"$h/.claude-personal/settings.json"
echo '{}' >"$h/.claude-niche/settings.json"
ln -s "$h/real.txt" "$h/.claude-niche/keep-link"                    # a link elsewhere stays
echo real >"$h/real.txt"
printf 'export A=1\n\n# Claude Code accounts\nsource "%s/.config/claude-shared/claude.sh"\n' "$h" >"$h/.zshrc.local"
printf 'export B=1\nsource "%s/.config/claude-shared/zsh/claude.zsh"\n' "$h" >"$h/.bashrc"
run_un "$B" --yes --keep-repo >"$ROOT/claude0.out" 2>&1 || { cat "$ROOT/claude0.out"; bad "exit 0"; }
check "without --with-claude the clone is kept" test -d "$c"
check "without --with-claude its links are kept" is_link "$h/.claude-niche/skills/foo"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --keep-repo --with-claude >"$ROOT/claude1.out" 2>&1) || { cat "$ROOT/claude1.out"; bad "exit 0"; }
check "legacy ~/.claude link removed" gone "$h/.claude/skills/foo"
check "~/.claude-niche skill link removed" gone "$h/.claude-niche/skills/foo"
check "agents link removed" gone "$h/.claude-niche/agents"
check "rules link removed" gone "$h/.claude-personal/rules"
check "pi link removed" gone "$h/.pi/agent/CLAUDE.md"
check "Claude backup restored" has_text "$h/.claude-personal/CLAUDE.md" bak
check "link to somewhere else kept" is_link "$h/.claude-niche/keep-link"
check "settings.json copies kept" test -f "$h/.claude-niche/settings.json" -a -f "$h/.claude-personal/settings.json"
check "settings.json copies reported" grep -q "settings.json in each" "$ROOT/claude1.out"
check "claude.sh line removed, other lines kept" has_text "$h/.zshrc.local" "export A=1"
check "claude.zsh line removed from ~/.bashrc" has_text "$h/.bashrc" "export B=1"
check "Claude clone removed" gone "$c"

echo "== a symlinked ~/.zshrc is not edited"
B="$ROOT/claudelink"
make_machine "$B" plain
h="$B/home"
make_clone "$B/claude-origin.git" "$h/.config/claude-shared"
printf 'source "%s/.config/claude-shared/claude.sh"\n' "$h" >"$h/dotfiles/zsh/.zshrc.extra"
rm -f "$h/.zshrc"
ln -s "$h/dotfiles/zsh/.zshrc.extra" "$h/.zshrc"
(cd "$h/dotfiles" && env HOME="$h" /bin/bash ./uninstall.sh --yes --keep-repo --with-claude >"$ROOT/claude2.out" 2>&1) || { cat "$ROOT/claude2.out"; bad "exit 0"; }
check "file behind the symlink keeps its line" grep -q "claude.sh" "$h/dotfiles/zsh/.zshrc.extra"

echo "== the exec bash notice and the zsh setup-menu note"
B="$ROOT/notice"
make_machine "$B" plain
rm -f "$B/home/.zshrc.backup-"* # no backup: ~/.zshrc stays gone
SHELL=/bin/zsh run_un "$B" --yes --keep-repo >"$ROOT/notice.out" 2>&1 || { cat "$ROOT/notice.out"; bad "exit 0"; }
check "notice is the last output" test "$(tail -n 1 "$ROOT/notice.out")" = "(or log out and back in)."
check "notice tells to run exec bash" grep -qx "  exec bash" "$ROOT/notice.out"
check "open-a-new-terminal line replaced by the notice" bash -c '! grep -q "Open a new terminal" "$1"' _ "$ROOT/notice.out"
check "zsh setup menu mentioned once" test "$(grep -c "new-user setup menu" "$ROOT/notice.out")" = 1
check "chsh printed once" test "$(grep -c "^  chsh -s /bin/bash" "$ROOT/notice.out")" = 1
check "ssh -O exit note printed once" test "$(grep -c "ssh -O exit <host>" "$ROOT/notice.out")" = 1

B="$ROOT/nonotice"
make_machine "$B" plain
h="$B/home"
# nothing a running shell uses: no zsh/bash links, no mise binary or data
find "$h" -path "$h/dotfiles" -prune -o -type l -name '.z*' -print -o -type l -name '.bash*' -print | while read -r l; do rm -f "$l"; done
rm -rf "$h/.local/bin/mise" "$h/.local/share/mise" "$h/.local/bin/mise.backup-"*
run_un "$B" --yes --keep-repo >"$ROOT/nonotice.out" 2>&1 || { cat "$ROOT/nonotice.out"; bad "exit 0"; }
check "no notice when nothing shell-related was removed" bash -c '! grep -q "exec bash" "$1"' _ "$ROOT/nonotice.out"
check "keeps the open-a-new-terminal line" grep -q "Open a new terminal" "$ROOT/nonotice.out"

echo
echo "passed: $PASS, failed: $FAIL"
[[ $FAIL -eq 0 ]]
