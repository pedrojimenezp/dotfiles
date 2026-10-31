#!/usr/bin/env bash
# Undo install.sh: remove the links, restore the backups it made, delete the data it generated.
# Works on macOS (bash 3.2), Linux desktops and Linux servers. Never uses sudo and never touches tmux.
# Usage: ./uninstall.sh [--dry-run] [--yes] [--with-claude] [--keep-repo]
set -euo pipefail # stop on errors, unset variables and failed pipes

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # absolute path of this repo
REPO_REAL="$(cd "$REPO" && pwd -P)"                  # physical path (no symlinks)
HOME_REAL="$(cd "$HOME" && pwd -P)"                  # physical path of $HOME
DRY=0                                                # 1 = print actions, change nothing
ASSUME_YES=0                                         # 1 = skip the confirmation prompt
WITH_CLAUDE=0                                        # 1 = also undo and remove the Claude config clone
KEEP_REPO=0                                          # 1 = keep this clone
CLAUDE_DIR="${CLAUDE_SHARED_DIR:-$HOME/.config/claude-shared}" # same default as install.sh
PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"     # pi agent folder the Claude installer links into
NERD_FONT="Monaspace"                                # same value as install.sh
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"           # XDG base dirs, as the tools read them
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"

# Same packages as install.sh, plus the macOS and Ghostty ones: a package with no links does nothing.
PACKAGES=(zsh nvim tmux vim git lazygit starship mise atuin bin theme iterm ghostty)

# What happened, for the summary.
REMOVED=()
RESTORED=()
SKIPPED=()
LEFT_BACKUPS=()
LINKS=()      # links into this repo found by the scan
LINK_SET=$'\n' # same paths, newline separated, for duplicate checks
PKG_RELS=()   # path under $HOME of every file a package would link, read before the clone is deleted
SWEPT=0       # broken links removed by the final sweep

usage() { echo "Usage: $0 [--dry-run] [--yes] [--with-claude] [--keep-repo]"; } # one place for the usage text

# Run a command, or only print it in dry-run mode.
run() {
  if [[ $DRY -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

step() { echo "==> $*"; } # a step starts
finish() { echo "$*"; echo; } # one result line, then a blank line

# True if $1 is a path this script may delete: under $HOME, never $HOME itself, no ".." parts.
path_ok() {
  local p="$1"
  [[ -n "$p" && "$p" != *"/../"* && "$p" != */.. ]] || return 1
  [[ "$p" == "$HOME"/?* || "$p" == "$HOME_REAL"/?* ]]
}

# rm -rf behind a guard: refuses an empty path or one outside $HOME. Records what it removed.
safe_rm() {
  local p="$1"
  if ! path_ok "$p"; then
    echo "refusing to remove '$p': empty or outside $HOME" >&2
    SKIPPED+=("$p (outside \$HOME or empty path, not removed)")
    return 0
  fi
  if [[ -e "$p" || -L "$p" ]]; then
    run rm -rf "$p"
    REMOVED+=("$p")
  fi
}

# Print where the symlink $1 finally points, without readlink -f (not on macOS). Fails if the folder is gone.
link_target() {
  local l="$1" t dir
  t="$(readlink "$l")" || return 1
  case "$t" in /*) ;; *) t="$(dirname "$l")/$t" ;; esac # stow writes relative links
  dir="$(cd "$(dirname "$t")" 2>/dev/null && pwd -P)" || return 1
  echo "$dir/$(basename "$t")"
}

# True if the symlink $1 points inside the folder $2 (physical path).
link_points_into() {
  local target
  [[ -L "$1" ]] || return 1
  target="$(link_target "$1")" || return 1
  [[ "$target" == "$2"/* ]]
}

# Print the newest "<path>.<kind>-*" backup (kind: backup or bak), or nothing. Names sort by timestamp.
newest_backup() {
  local path="$1" kind="$2" b newest=""
  for b in "$path.$kind-"*; do
    if [[ -e "$b" || -L "$b" ]]; then newest="$b"; fi # an unmatched glob stays literal and fails the test
  done
  [[ -z "$newest" ]] || echo "$newest"
}

# Add $1 to LINKS once.
add_link() {
  case "$LINK_SET" in *$'\n'"$1"$'\n'*) return 0 ;; esac
  LINKS+=("$1")
  LINK_SET="$LINK_SET$1"$'\n'
}

# Find every link into this repo: the file each package would link, plus stray links in the usual folders.
scan_links() {
  local pkg file rel root
  for pkg in "${PACKAGES[@]}"; do
    [[ -d "$REPO/$pkg" ]] || continue
    while IFS= read -r -d '' file; do
      rel="${file#"$REPO/$pkg/"}"
      PKG_RELS+=("$rel")
      if link_points_into "$HOME/$rel" "$REPO_REAL"; then add_link "$HOME/$rel"; fi
    done < <(find "$REPO/$pkg" -type f -print0)
  done
  # leftovers from an older layout, and links a newer package list no longer names
  while IFS= read -r -d '' file; do
    if link_points_into "$file" "$REPO_REAL"; then add_link "$file"; fi
  done < <(find "$HOME" -maxdepth 1 -type l -print0)
  for root in "$CONFIG" "$HOME/.local/bin"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' file; do
      if link_points_into "$file" "$REPO_REAL"; then add_link "$file"; fi
    done < <(find "$root" -maxdepth 4 \( -path "$CLAUDE_DIR" -o -path "$CONFIG/tmux/plugins" \) -prune -o -type l -print0)
  done
}

# Print the absolute path the symlink $1 points at, from its text alone: "." and ".." parts are folded and
# nothing is read from disk, so it works when the target is gone. A relative target is read from the link's folder.
raw_link_target() {
  local l="$1" t dir rest part out=""
  t="$(readlink "$l")" || return 1
  case "$t" in
    /*) ;;
    *) dir="$(cd "$(dirname "$l")" 2>/dev/null && pwd -P)" || dir="$(dirname "$l")"; t="$dir/$t" ;;
  esac
  rest="$t"
  while [[ -n "$rest" ]]; do
    part="${rest%%/*}"
    if [[ "$rest" == */* ]]; then rest="${rest#*/}"; else rest=""; fi
    case "$part" in
      "" | .) ;;
      ..) out="${out%/*}" ;;
      *) out="$out/$part" ;;
    esac
  done
  echo "${out:-/}"
}

# Remove the symlink $1 if it is broken and its target text is inside $REPO or $REPO_REAL.
sweep_link() {
  local target
  [[ -L "$1" && ! -e "$1" ]] || return 0
  target="$(raw_link_target "$1")" || return 0
  case "$target" in
    "$REPO"/* | "$REPO_REAL"/*) ;;
    *) return 0 ;;
  esac
  rm -f "$1"
  REMOVED+=("$1")
  SWEPT=$((SWEPT + 1))
  prune_up "$(dirname "$1")"
}

# After the clone is deleted, remove the links into it that are now broken: the places scan_links reads,
# plus every path a package linked. Never touches a link that works, one pointing elsewhere, or a real file.
sweep_broken_links() {
  local rel root file
  if [[ ${#PKG_RELS[@]} -gt 0 ]]; then
    for rel in "${PKG_RELS[@]}"; do sweep_link "$HOME/$rel"; done
  fi
  while IFS= read -r -d '' file; do sweep_link "$file"; done < <(find "$HOME" -maxdepth 1 -type l -print0)
  for root in "$CONFIG" "$HOME/.local/bin"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' file; do
      sweep_link "$file"
    done < <(find "$root" -maxdepth 4 \( -path "$CLAUDE_DIR" -o -path "$CONFIG/tmux/plugins" \) -prune -o -type l -print0)
  done
}

# Generated data and caches, one path per line. Paths that do not exist are skipped by the caller.
data_paths() {
  cat <<EOF
$DATA/zsh-plugins
$CACHE/zsh
$CONFIG/tmux/plugins
$DATA/atuin
$DATA/nvim
$STATE/nvim
$CACHE/nvim
$DATA/mise
$STATE/mise
$CACHE/mise
$DATA/zoxide
$STATE/lazygit
$CACHE/starship
$CONFIG/git/local
$DATA/theme
$STATE/theme
$CACHE/theme
$STATE/dotfiles
$HOME/.vim/undo
$CONFIG/ghostty/theme.conf
$CONFIG/ghostty/theme.conf.tmp
$CONFIG/ghostty/themes
$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist
$DATA/fonts/${NERD_FONT}NerdFont
EOF
  local f
  for f in "$HOME"/.zcompdump*; do echo "$f"; done # zsh's completion cache; an unmatched glob is skipped later
}

# Print the data paths that exist now.
existing_data() {
  local p
  while IFS= read -r p; do
    if [[ -e "$p" || -L "$p" ]]; then echo "$p"; fi
  done < <(data_paths)
}

# Is the folder $1 safe to delete? Prints the reason and fails when it is not.
clone_unsafe_reason() {
  local dir="$1" n
  if ! command -v git >/dev/null 2>&1; then echo "git is missing, so it cannot check for unsaved work"; return 0; fi
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then echo "it is not a git clone, so it cannot check for unsaved work"; return 0; fi
  if [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]]; then echo "it has uncommitted changes"; return 0; fi
  n="$(git -C "$dir" rev-list --count HEAD --not --remotes 2>/dev/null || echo 1)"
  if [[ "$n" != 0 ]]; then echo "it has commits that are not on any remote branch"; return 0; fi
  return 1
}

# True if nothing is at $1, or (dry run) it is on the list of paths this run would remove.
path_is_free() {
  local p
  if [[ ! -e "$1" && ! -L "$1" ]]; then return 0; fi
  if [[ $DRY -eq 1 && ${#REMOVED[@]} -gt 0 ]]; then
    for p in "${REMOVED[@]}"; do [[ "$p" != "$1" ]] || return 0; done
  fi
  return 1
}

# Move the newest backup of $1 back when the path is free. Older backups are listed at the end.
restore_backup() {
  local path="$1" kind="${2:-backup}" newest b
  newest="$(newest_backup "$path" "$kind")"
  [[ -n "$newest" ]] || return 0
  if ! path_is_free "$path"; then
    SKIPPED+=("$newest (kept: $path exists)")
    return 0
  fi
  run mv "$newest" "$path"
  RESTORED+=("$newest -> $path")
  for b in "$path.$kind-"*; do
    if [[ "$b" != "$newest" && ( -e "$b" || -L "$b" ) ]]; then LEFT_BACKUPS+=("$b"); fi
  done
}

# Remove empty folders upward from $1, stopping at the standard roots. Never fails.
prune_up() {
  local d="$1"
  [[ $DRY -eq 0 ]] || return 0 # a preview never removes folders
  while [[ "$d" != "$HOME" && "$d" != "$HOME_REAL" && "$d" != "$CONFIG" && "$d" != "$DATA" && "$d" != "$STATE" \
    && "$d" != "$CACHE" && "$d" != "$HOME/.local" && "$d" != "$HOME/Library" && "$d" != / && -n "$d" ]]; do
    path_ok "$d" || return 0
    rmdir "$d" 2>/dev/null || return 0 # not empty or already gone
    d="$(dirname "$d")"
  done
}

# Print the Claude config folders: every ~/.claude-<name> plus the legacy ~/.claude.
claude_account_dirs() {
  local d
  for d in "$HOME"/.claude "$HOME"/.claude-*; do
    [[ -d "$d" && ! -L "$d" ]] && echo "$d"
  done
}

# Remove the links the Claude installer made in the Claude and pi account folders, restoring its .bak-* files.
undo_claude_links() {
  local root file n=0 dest claude_real
  local -a found=() roots=()
  claude_real="$(cd "$CLAUDE_DIR" && pwd -P)"
  while IFS= read -r root; do roots+=("$root"); done < <(claude_account_dirs)
  roots+=("$PI_DIR")
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' file; do
      if link_points_into "$file" "$claude_real"; then found+=("$file"); fi
    done < <(find "$root" -maxdepth 4 -type l -print0)
  done
  if [[ ${#found[@]} -gt 0 ]]; then
    for dest in "${found[@]}"; do
      run rm -f "$dest"
      REMOVED+=("$dest")
      restore_backup "$dest" bak
      prune_up "$(dirname "$dest")"
      n=$((n + 1))
    done
  fi
  echo "Claude links removed: $n"
}

# Delete the lines the Claude installer appended to a shell rc file: the claude.sh line, an old claude.zsh
# line and the "# Claude Code accounts" comment. A symlinked rc file belongs to a repo and is left alone.
undo_claude_shell_line() {
  local rc tmp
  for rc in "$HOME/.zshrc.local" "$HOME/.zshrc" "$HOME/.bashrc"; do
    [[ -f "$rc" && ! -L "$rc" ]] || continue
    grep -qE 'claude-shared/(zsh/claude\.zsh|claude\.sh)' "$rc" || continue
    tmp="$rc.uninstall.$$"
    if [[ $DRY -eq 1 ]]; then
      echo "[dry-run] remove the claude.sh lines from $rc"
    else
      grep -vE -e 'claude-shared/(zsh/claude\.zsh|claude\.sh)' -e '^# Claude Code accounts$' "$rc" >"$tmp" || true # exit 1 = nothing left
      cat "$tmp" >"$rc" # keeps the file's owner and mode
      rm -f "$tmp"
    fi
    REMOVED+=("claude.sh lines in $rc")
  done
}

# Print the brew commands that remove what the Brewfile installed. Brewfile is the single list.
brew_hint() {
  local formulae casks
  formulae="$(sed -n 's/^brew "\([^"]*\)".*/\1/p' "$REPO/Brewfile" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
  casks="$(sed -n 's/^cask "\([^"]*\)".*/\1/p' "$REPO/Brewfile" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
  echo "Homebrew packages were not touched. If the Brewfile installed them and you no longer want them:"
  [[ -z "$formulae" ]] || echo "  brew uninstall $formulae"
  [[ -z "$casks" ]] || echo "  brew uninstall --cask $casks"
}

# Print the command that makes bash the login shell again; prints nothing if the login shell is not zsh.
login_shell_hint() {
  local current=""
  if [[ "$OSTYPE" == darwin* ]]; then
    current="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')" # $SHELL can be stale
  else
    current="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7)"
  fi
  current="${current:-${SHELL:-}}"
  [[ "$(basename "${current:-unknown}")" == zsh || "$(basename "${SHELL:-unknown}")" == zsh ]] || return 0
  echo "Your login shell is zsh. To go back to bash, run (this script never changes it):"
  echo "  chsh -s /bin/bash"
  echo "If chsh asks for a password you do not have:"
  echo "  sudo chsh -s /bin/bash \"\$USER\""
}

# Print the numbered list of everything the run will do.
print_plan() {
  local l p b
  echo "This will remove:"
  if [[ ${#LINKS[@]} -gt 0 ]]; then
    echo "  links into this repo (${#LINKS[@]}):"
    for l in "${LINKS[@]}"; do
      echo "    $l"
      b="$(newest_backup "$l" backup)"
      [[ -z "$b" ]] || echo "      restores $b"
    done
  else
    echo "  links into this repo: none found"
  fi
  for p in "$HOME/.gitconfig" "$HOME/.local/bin/mise"; do
    b="$(newest_backup "$p" backup)"
    [[ -z "$b" ]] || echo "  restores $b -> $p"
  done
  echo "  generated data and caches:"
  while IFS= read -r p; do echo "    $p"; done < <(existing_data)
  [[ ! -f "$HOME/.local/bin/mise" ]] || echo "    $HOME/.local/bin/mise (the mise binary)"
  if [[ $WITH_CLAUDE -eq 1 && -d "$CLAUDE_DIR" ]]; then
    echo "  the Claude config: its links in every ~/.claude-<name> folder (and a legacy ~/.claude) and in $PI_DIR,"
    echo "    its line in ~/.zshrc.local, ~/.zshrc (not a symlink) and ~/.bashrc, then the clone $CLAUDE_DIR"
    echo "    (the clone's untracked local files, such as coaching logs, go with it)"
  fi
  if [[ $KEEP_REPO -eq 0 ]]; then
    echo "  this clone, last: $REPO (kept if it has unsaved work)"
  fi
  echo "It keeps: ~/.zshrc.local, ~/.zsh_history, ~/go, Homebrew packages and the login shell."
  echo
}

main() {
  local arg answer l p b reason mise_bin="$HOME/.local/bin/mise" font_dir stow_ran=0 count had_font=0
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY=1 ;;
      --yes | -y) ASSUME_YES=1 ;;
      --with-claude) WITH_CLAUDE=1 ;;
      --keep-repo) KEEP_REPO=1 ;;
      -h | --help) usage; exit 0 ;;
      *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
  done
  if [[ -z "${HOME:-}" || "$HOME" == / ]]; then
    echo "HOME is empty or /: refusing to run." >&2
    exit 1
  fi

  scan_links
  print_plan
  if [[ $DRY -eq 0 && $ASSUME_YES -eq 0 ]]; then
    read -r -p "Continue? [y/N] " answer || answer=""
    case "$answer" in y | Y | yes | YES) ;; *) echo "Cancelled. Nothing was changed."; exit 0 ;; esac
    echo
  fi
  local brew_text=""
  [[ "$OSTYPE" != darwin* ]] || brew_text="$(brew_hint)" # read the Brewfile before the clone goes

  # Step 1: links. stow knows its own links; the sweep catches what is left (the plain-symlink fallback).
  step "Removing links into $REPO"
  if command -v stow >/dev/null 2>&1; then
    run stow --delete --dir="$REPO" --target="$HOME" "${PACKAGES[@]}" || echo "Warning: stow could not remove everything; sweeping the rest" >&2
    stow_ran=1
  fi
  count=0
  if [[ ${#LINKS[@]} -gt 0 ]]; then
    for l in "${LINKS[@]}"; do
      # after a real stow run most links are gone already; a dry run prints stow's command only
      if link_points_into "$l" "$REPO_REAL" && [[ $DRY -eq 0 || $stow_ran -eq 0 ]]; then run rm -f "$l"; fi
      REMOVED+=("$l")
      prune_up "$(dirname "$l")"
      count=$((count + 1))
    done
  fi
  finish "Removed $count links"

  # Step 2: put the newest backups back where the path is free.
  step "Restoring backups"
  if [[ ${#LINKS[@]} -gt 0 ]]; then
    for l in "${LINKS[@]}"; do restore_backup "$l" backup; done
  fi
  finish "Restored ${#RESTORED[@]} files"

  # Step 3: the mise binary from mise.run, and ~/.gitconfig's backup.
  step "Removing the mise binary and restoring ~/.gitconfig"
  if [[ -f "$mise_bin" && ! -L "$mise_bin" ]]; then safe_rm "$mise_bin"; fi
  restore_backup "$mise_bin" backup
  restore_backup "$HOME/.gitconfig" backup
  finish "Done"

  # Step 4: generated data and caches (plain rm, so a test with a temp HOME is safe).
  step "Removing generated data and caches"
  font_dir="$DATA/fonts/${NERD_FONT}NerdFont"
  if [[ -e "$font_dir" ]]; then had_font=1; fi
  while IFS= read -r p; do
    [[ -e "$p" || -L "$p" ]] || continue
    safe_rm "$p"
    prune_up "$(dirname "$p")"
  done < <(data_paths)
  if [[ $had_font -eq 1 && "$OSTYPE" != darwin* ]] && command -v fc-cache >/dev/null 2>&1; then
    run fc-cache -f # refresh the font cache after the font folder is gone
  fi
  finish "Done"

  # Step 5: the optional Claude config.
  if [[ $WITH_CLAUDE -eq 1 ]]; then
    step "Undoing the Claude config in $CLAUDE_DIR"
    if [[ -d "$CLAUDE_DIR" ]]; then
      undo_claude_links
      undo_claude_shell_line
      SKIPPED+=("settings.json in each ~/.claude-<name> folder (copies that Claude Code also writes; delete them yourself if you want)")
      if reason="$(clone_unsafe_reason "$CLAUDE_DIR")"; then
        SKIPPED+=("$CLAUDE_DIR (kept: $reason)")
      else
        safe_rm "$CLAUDE_DIR"
        prune_up "$(dirname "$CLAUDE_DIR")"
      fi
    else
      echo "$CLAUDE_DIR does not exist"
    fi
    finish "Done"
  elif [[ -d "$CLAUDE_DIR" ]]; then
    SKIPPED+=("$CLAUDE_DIR (kept: run with --with-claude to remove it and its links)")
  fi

  # Step 6: this clone, last and from outside it.
  if [[ $KEEP_REPO -eq 1 ]]; then
    SKIPPED+=("$REPO (kept: --keep-repo)")
  else
    step "Removing this clone: $REPO"
    cd "$HOME" # never delete the folder we stand in
    if reason="$(clone_unsafe_reason "$REPO")"; then
      SKIPPED+=("$REPO (kept: $reason)")
      finish "Kept"
    elif ! path_ok "$REPO" && ! path_ok "$REPO_REAL"; then
      SKIPPED+=("$REPO (kept: it is outside $HOME)")
      finish "Kept"
    else
      safe_rm "$REPO"
      finish "Removed"
      # Step 7: a link the scan missed is broken now; a preview cannot know which ones.
      step "Sweeping for broken links into the deleted clone"
      if [[ $DRY -eq 1 ]]; then
        finish "The final sweep will run after the clone is deleted"
      else
        sweep_broken_links
        finish "Removed $SWEPT broken links"
      fi
    fi
  fi

  # Summary.
  echo "=== Summary ==="
  echo "Removed (${#REMOVED[@]}):"
  if [[ ${#REMOVED[@]} -gt 0 ]]; then for p in "${REMOVED[@]}"; do echo "  $p"; done; fi
  echo "Restored (${#RESTORED[@]}):"
  if [[ ${#RESTORED[@]} -gt 0 ]]; then for p in "${RESTORED[@]}"; do echo "  $p"; done; fi
  echo "Skipped (${#SKIPPED[@]}):"
  if [[ ${#SKIPPED[@]} -gt 0 ]]; then for p in "${SKIPPED[@]}"; do echo "  $p"; done; fi
  if [[ ${#LEFT_BACKUPS[@]} -gt 0 ]]; then
    echo "Older backups left in place (delete them when you are sure):"
    for b in "${LEFT_BACKUPS[@]}"; do echo "  $b"; done
  fi
  echo
  echo "Next:"
  echo "  Open a new terminal: shells that are already open keep the old settings."
  echo "  A running tmux server keeps its old config until you stop it yourself (tmux kill-server)."
  [[ -z "$brew_text" ]] || echo "$brew_text"
  login_shell_hint
  [[ $DRY -eq 0 ]] || echo "That was a dry run: nothing changed."
}

main "$@"
exit
