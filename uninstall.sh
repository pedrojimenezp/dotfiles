#!/usr/bin/env bash
# Undo install.sh: unlink the packages with stow, then put back the newest backup of each file it moved aside.
# Never uses sudo and never touches tmux, generated data, Homebrew or this clone.
# Usage: ./uninstall.sh [--dry-run] [--yes] [--with-claude]
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # absolute path of this repo
HOME_REAL="$(cd "$HOME" && pwd -P)"                  # physical path of $HOME
DRY=0                                                # 1 = print actions, change nothing
ASSUME_YES=0                                         # 1 = skip the confirmation prompt
WITH_CLAUDE=0                                        # 1 = also undo and remove the Claude config clone
CLAUDE_DIR="$HOME/.config/claude-shared"            # same path as install.sh
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"           # XDG base dirs, as the tools read them
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"

# Same packages as install.sh, plus the macOS and Ghostty ones: a package with no links does nothing.
PACKAGES=(zsh nvim tmux vim git lazygit starship mise bin theme iterm skhd ghostty)

# What happened, for the summary.
REMOVED=()
RESTORED=()
SKIPPED=()
LEFT_BACKUPS=()

usage() { echo "Usage: $0 [--dry-run] [--yes] [--with-claude]"; } # one place for the usage text

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

# Print the newest "<path>.backup-*" backup, or nothing. Names sort by timestamp.
newest_backup() {
  local path="$1" b newest=""
  for b in "$path.backup-"*; do
    if [[ -e "$b" || -L "$b" ]]; then newest="$b"; fi # an unmatched glob stays literal and fails the test
  done
  [[ -z "$newest" ]] || echo "$newest"
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
  local path="$1" newest b
  newest="$(newest_backup "$path")"
  [[ -n "$newest" ]] || return 0
  if ! path_is_free "$path"; then
    SKIPPED+=("$newest (kept: $path exists)")
    return 0
  fi
  run mv "$newest" "$path"
  RESTORED+=("$newest -> $path")
  for b in "$path.backup-"*; do
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

# Print the path under $HOME of every file a package would link, one per line.
package_files() {
  local pkg file
  for pkg in "${PACKAGES[@]}"; do
    [[ -d "$REPO/$pkg" ]] || continue
    while IFS= read -r -d '' file; do echo "${file#"$REPO/$pkg/"}"; done < <(find "$REPO/$pkg" -type f -print0)
  done
}

main() {
  local arg answer rel reason b REPO_REAL
  REPO_REAL="$(cd "$REPO" && pwd -P)" # physical path (no symlinks)
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY=1 ;;
      --yes | -y) ASSUME_YES=1 ;;
      --with-claude) WITH_CLAUDE=1 ;;
      -h | --help) usage; exit 0 ;;
      *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
  done
  if [[ -z "${HOME:-}" || "$HOME" == / ]]; then
    echo "HOME is empty or /: refusing to run." >&2
    exit 1
  fi
  command -v stow >/dev/null 2>&1 || { echo "stow is required and was not found." >&2; exit 1; }

  echo "This will unlink the packages of $REPO from $HOME and restore the newest backups install.sh made."
  [[ $WITH_CLAUDE -eq 0 ]] || echo "It will also undo the Claude config in $CLAUDE_DIR and remove that clone."
  echo "It keeps this clone, generated data and caches, Homebrew packages and the login shell."
  if [[ $DRY -eq 0 && $ASSUME_YES -eq 0 ]]; then
    read -r -p "Continue? [y/N] " answer || answer=""
    case "$answer" in y | Y | yes | YES) ;; *) echo "Cancelled. Nothing was changed."; exit 0 ;; esac
  fi
  echo

  step "Unlinking the packages"
  run stow --delete --no-folding --dir="$REPO" --target="$HOME" "${PACKAGES[@]}"
  finish "Done"

  step "Restoring backups"
  while IFS= read -r rel; do
    link_points_into "$HOME/$rel" "$REPO_REAL" && REMOVED+=("$HOME/$rel") # a dry run still sees the link
    restore_backup "$HOME/$rel"
    prune_up "$(dirname "$HOME/$rel")"
  done < <(package_files)
  restore_backup "$HOME/.gitconfig"
  finish "Restored ${#RESTORED[@]} files"

  if [[ $WITH_CLAUDE -eq 1 ]]; then
    step "Undoing the Claude config in $CLAUDE_DIR"
    if [[ -d "$CLAUDE_DIR" ]]; then
      if [[ $DRY -eq 1 ]]; then
        echo "[dry-run] $CLAUDE_DIR/install.sh --uninstall"
      elif [[ -x "$CLAUDE_DIR/install.sh" ]]; then
        "$CLAUDE_DIR/install.sh" --uninstall
      fi
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
  fi

  echo "=== Summary ==="
  echo "Restored (${#RESTORED[@]}):"
  if [[ ${#RESTORED[@]} -gt 0 ]]; then for rel in "${RESTORED[@]}"; do echo "  $rel"; done; fi
  echo "Skipped (${#SKIPPED[@]}):"
  if [[ ${#SKIPPED[@]} -gt 0 ]]; then for rel in "${SKIPPED[@]}"; do echo "  $rel"; done; fi
  if [[ ${#LEFT_BACKUPS[@]} -gt 0 ]]; then
    echo "Older backups left in place (delete them when you are sure):"
    for b in "${LEFT_BACKUPS[@]}"; do echo "  $b"; done
  fi
  echo
  echo "Open a new terminal: shells that are already open keep the old settings."
  [[ $DRY -eq 0 ]] || echo "That was a dry run: nothing changed."
}

main "$@"
