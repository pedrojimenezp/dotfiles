#!/usr/bin/env bash
# Install these dotfiles: back up conflicting files, then link packages with GNU Stow.
# Usage: ./install.sh [--server] [--dry-run]
set -euo pipefail # stop on errors, unset variables and failed pipes

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # absolute path of this repo
REPO_REAL="$(cd "$REPO" && pwd -P)"                  # physical path (no symlinks)
STAMP="$(date +%Y%m%d-%H%M%S)"                       # suffix for backup files
SERVER=0                                             # 1 = minimal mode without Homebrew
DRY=0                                                # 1 = print actions, change nothing
NERD_FONT="JetBrainsMono"                            # Nerd Fonts release name; change to switch fonts

for arg in "$@"; do # parse command-line flags
  case "$arg" in
    --server) SERVER=1 ;;
    --dry-run) DRY=1 ;;
    -h | --help)
      echo "Usage: $0 [--server] [--dry-run]"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

# Run a command, or only print it in dry-run mode.
run() {
  if [[ $DRY -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

# Packages to link: full mode vs server mode.
if [[ $SERVER -eq 1 ]]; then
  PACKAGES=(zsh tmux vim git bin)
else
  PACKAGES=(zsh nvim tmux vim git starship bin)
fi

# Ghostty is optional: link its config only if the app or binary exists.
if [[ $SERVER -eq 0 ]] && { [[ -d /Applications/Ghostty.app ]] || command -v ghostty >/dev/null 2>&1; }; then
  PACKAGES+=(ghostty)
fi

# Step 1: Homebrew packages (full mode only).
if [[ $SERVER -eq 0 ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo "==> Installing Homebrew packages"
    run brew bundle --file="$REPO/Brewfile"
  else
    cat <<'MSG'
Homebrew was not found. Install it first (this script never uses sudo):
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Then follow the "Next steps" it prints to add brew to your PATH, and run this script again.
On a server without Homebrew, use: ./install.sh --server
MSG
    exit 1
  fi
fi

# True if $1 resolves (through any symlinks) to a file inside this repo.
is_repo_link() {
  local resolved
  resolved="$(realpath "$1" 2>/dev/null)" || return 1 # follows links, incl. folded directories
  [[ "$resolved" == "$REPO_REAL"/* ]]
}

# Move a real file (not one of our links) out of the way.
backup() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]] && ! is_repo_link "$path"; then
    echo "backup: $path -> $path.backup-$STAMP"
    run mv "$path" "$path.backup-$STAMP"
  fi
}

# Step 2: back up every file a package would link, so stow never conflicts.
echo "==> Backing up existing files"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r -d '' file; do
    rel="${file#"$REPO/$pkg/"}" # path relative to the package root
    backup "$HOME/$rel"
  done < <(find "$REPO/$pkg" -type f -print0)
done
# ~/.gitconfig wins over ~/.config/git/config, so it must move away too.
if [[ " ${PACKAGES[*]} " == *" git "* ]]; then
  backup "$HOME/.gitconfig"
fi

# Plain-symlink fallback used when stow is missing (server mode).
link_package() {
  local pkg="$1" file rel
  while IFS= read -r -d '' file; do
    rel="${file#"$REPO/$pkg/"}"
    run mkdir -p "$(dirname "$HOME/$rel")"
    run ln -sfn "$file" "$HOME/$rel"
  done < <(find "$REPO/$pkg" -type f -print0)
}

# Step 3: link the packages.
echo "==> Linking packages: ${PACKAGES[*]}"
if command -v stow >/dev/null 2>&1; then
  # Pre-create real directories so stow links files, not whole folders (keeps ~/.config writable).
  for pkg in "${PACKAGES[@]}"; do
    while IFS= read -r -d '' file; do
      rel="${file#"$REPO/$pkg/"}"
      run mkdir -p "$(dirname "$HOME/$rel")"
    done < <(find "$REPO/$pkg" -type f -print0)
  done
  run stow --restow --dir="$REPO" --target="$HOME" "${PACKAGES[@]}"
else
  echo "stow not found: falling back to plain symlinks"
  for pkg in "${PACKAGES[@]}"; do
    link_package "$pkg"
  done
fi

# Step 4: tmux plugin manager.
TPM="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM" ]] && command -v git >/dev/null 2>&1; then
  echo "==> Cloning TPM"
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
fi

# Step 5: Nerd Font for Linux desktop terminals (Ghostty and macOS need nothing).
install_font() {
  local dir="$HOME/.local/share/fonts/${NERD_FONT}NerdFont" tmp # per-user dir, no sudo
  if fc-list | grep -qi "${NERD_FONT} Nerd Font" || [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
    return 0 # already installed
  fi
  echo "==> Installing ${NERD_FONT} Nerd Font"
  if [[ $DRY -eq 1 ]]; then
    tmp="<tmpdir>" # nothing is downloaded in dry-run
  else
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT # remove the download on exit
  fi
  # download the release archive
  run curl -fsSL -o "$tmp/font.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.tar.xz"
  run mkdir -p "$dir" # target folder
  run tar -xJf "$tmp/font.tar.xz" -C "$dir" # unpack the fonts
  run fc-cache -f # refresh the font cache
}

if [[ $SERVER -eq 0 && "$OSTYPE" == linux* ]]; then
  if command -v fc-cache >/dev/null 2>&1; then # needs fontconfig
    install_font
  else
    echo "==> Skipping Nerd Font: fc-cache not found"
  fi
fi

cat <<'MSG'

Done. Next steps:
  1. Open tmux and press prefix + I (Ctrl+Space, then Shift+i) to install plugins.
  2. Open nvim once and let lazy.nvim install plugins (run :Mason to check LSP tools).
  3. Move secrets and machine-specific settings into ~/.zshrc.local (sourced last).
  4. Put machine-specific git settings in ~/.config/git/local.
  5. Start a new shell (exec zsh).
MSG
