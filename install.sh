#!/usr/bin/env bash
# Install these dotfiles: back up conflicting files, then link packages with GNU Stow.
# Usage: ./install.sh [--server] [--dry-run] [--with-claude]
set -euo pipefail # stop on errors, unset variables and failed pipes

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # absolute path of this repo
REPO_REAL="$(cd "$REPO" && pwd -P)"                  # physical path (no symlinks)
STAMP="$(date +%Y%m%d-%H%M%S)"                       # suffix for backup files
SERVER=0                                             # 1 = minimal mode without Homebrew
DRY=0                                                # 1 = print actions, change nothing
WITH_CLAUDE=0                                        # 1 = also set up the private Claude config repo
CLAUDE_REPO_URL="git@github.com:pedrojimenezp/claude-config.git" # private repo: needs your GitHub SSH key
CLAUDE_DIR="${CLAUDE_SHARED_DIR:-$HOME/.config/claude-shared}"   # where the Claude config repo lives
NERD_FONT="Monaspace"                                # Nerd Fonts release archive name; change to switch fonts
NERD_FONT_FAMILY="Monaspice"                         # family prefix fc-list reports (Nerd Fonts renames Monaspace)

for arg in "$@"; do # parse command-line flags
  case "$arg" in
    --server) SERVER=1 ;;
    --dry-run) DRY=1 ;;
    --with-claude) WITH_CLAUDE=1 ;;
    -h | --help)
      echo "Usage: $0 [--server] [--dry-run] [--with-claude]"
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
  PACKAGES=(zsh nvim tmux vim git starship mise bin)
fi

# iTerm Dynamic Profile: macOS only, never in server mode.
if [[ $SERVER -eq 0 && "$OSTYPE" == darwin* ]]; then
  PACKAGES+=(iterm)
fi

# Step 1: Homebrew packages (full mode only).
if [[ $SERVER -eq 0 ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo "==> Installing Homebrew packages"
    # Upgrades are a separate, deliberate `brew upgrade`.
    run brew bundle --no-upgrade --file="$REPO/Brewfile"
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

# Ghostty is optional: link its config only if the app or binary exists.
HAS_GHOSTTY=0                                                      # 1 once Ghostty is found
for app in "$HOME/Applications/Ghostty.app" /Applications/Ghostty.app; do # Brewfile appdir first, then the old path
  [[ -d $app ]] && HAS_GHOSTTY=1                                   # app bundle present
done
command -v ghostty >/dev/null 2>&1 && HAS_GHOSTTY=1                # Linux package on PATH
if [[ $SERVER -eq 0 && $HAS_GHOSTTY -eq 1 ]]; then                 # never in server mode
  PACKAGES+=(ghostty)                                              # stow the Ghostty config
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

# Step 1b: an old standalone mise in ~/.local/bin shadows the Homebrew one on PATH.
if [[ $SERVER -eq 0 ]]; then
  BREW_MISE="$(brew --prefix 2>/dev/null)/bin/mise" # Homebrew's copy
  if [[ -x "$BREW_MISE" && -f "$HOME/.local/bin/mise" && ! -L "$HOME/.local/bin/mise" ]]; then
    echo "==> $HOME/.local/bin/mise shadows the Homebrew mise on PATH; backing it up"
    backup "$HOME/.local/bin/mise"
  fi
fi

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

# Step 3b: install the global runtimes from the mise config (full mode only).
if [[ $SERVER -eq 0 ]]; then
  if command -v mise >/dev/null 2>&1; then
    echo "==> Installing runtimes with mise"
    run mise install # reads ~/.config/mise/config.toml
  else
    echo "==> Skipping mise install: mise not found"
  fi
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
  # fc-list shows Monaspice families as "MonaspiceNe Nerd Font", so match the family prefix
  if fc-list | grep -qi "${NERD_FONT_FAMILY}.* Nerd Font" || [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
    return 0 # already installed
  fi
  echo "==> Installing ${NERD_FONT} Nerd Font"
  if [[ $DRY -eq 1 ]]; then
    tmp="<tmpdir>" # nothing is downloaded in dry-run
  else
    tmp="$(mktemp -d)"
    # shellcheck disable=SC2064 # expand $tmp now: it is local
    trap "rm -rf '${tmp}'" EXIT # remove the download on exit
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

# Step 6: optional private Claude config (opt-in, full mode only).
if [[ $WITH_CLAUDE -eq 1 ]]; then
  if [[ $SERVER -eq 1 ]]; then
    echo "==> --with-claude is ignored in server mode"
  else
    echo "==> Setting up Claude config in $CLAUDE_DIR"
    if [[ ! -e "$CLAUDE_DIR" ]]; then
      run git clone "$CLAUDE_REPO_URL" "$CLAUDE_DIR" # needs GitHub SSH access
    elif git -C "$CLAUDE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
      echo "Claude config already there: $CLAUDE_DIR (not pulling)"
    else
      echo "Warning: $CLAUDE_DIR exists but is not a git repo: skipping" >&2
    fi
    # run its own installer once it is there (in dry-run the clone is only printed)
    if [[ -x "$CLAUDE_DIR/install.sh" || $DRY -eq 1 ]]; then
      run "$CLAUDE_DIR/install.sh"
    fi
  fi
fi
