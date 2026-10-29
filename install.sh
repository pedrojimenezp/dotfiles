#!/usr/bin/env bash
# Install these dotfiles: back up conflicting files, then link packages with GNU Stow.
# Usage: ./install.sh [--dry-run] [--with-claude]
set -euo pipefail # stop on errors, unset variables and failed pipes

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # absolute path of this repo
REPO_REAL="$(cd "$REPO" && pwd -P)"                  # physical path (no symlinks)
STAMP="$(date +%Y%m%d-%H%M%S)"                       # suffix for backup files
DRY=0                                                # 1 = print actions, change nothing
WITH_CLAUDE=0                                        # 1 = also set up the private Claude config repo
CLAUDE_REPO_URL="git@github.com:pedrojimenezp/claude-config.git" # private repo: needs your GitHub SSH key
CLAUDE_DIR="${CLAUDE_SHARED_DIR:-$HOME/.config/claude-shared}"   # where the Claude config repo lives
NERD_FONT="Monaspace"                                # Nerd Fonts release archive name; change to switch fonts
NERD_FONT_FAMILY="Monaspice"                         # family prefix fc-list reports (Nerd Fonts renames Monaspace)

for arg in "$@"; do # parse command-line flags
  case "$arg" in
    --dry-run) DRY=1 ;;
    --with-claude) WITH_CLAUDE=1 ;;
    -h | --help)
      echo "Usage: $0 [--dry-run] [--with-claude]"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

# Prerequisite: zsh must exist (the configs are zsh-only). This script never uses sudo, so it only prints the command.
if ! command -v zsh >/dev/null 2>&1; then # nothing to link against without zsh
  if [[ "$OSTYPE" == linux* ]] && command -v apt-get >/dev/null 2>&1; then # Debian/Ubuntu
    echo "zsh was not found. Install it first (this script never uses sudo):" >&2 # tell the user what to run
    echo "  sudo apt-get update && sudo apt-get install -y zsh" >&2             # exact command
  else
    echo "zsh was not found. Install zsh with your package manager, then run this script again." >&2 # no known installer
  fi
  if [[ $DRY -eq 1 ]]; then # a preview should still show the rest of the plan
    echo "[dry-run] continuing without zsh" >&2 # make the skipped exit visible
  else
    exit 1 # stop before any change
  fi
fi

# Run a command, or only print it in dry-run mode.
run() {
  if [[ $DRY -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

# Succeeds when this machine can authenticate to GitHub over SSH (read-only: nothing is written but known_hosts).
github_ssh_ok() {
  local out                                                                       # ssh banner
  out="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -T git@github.com 2>&1 || true)" # exit 1 means authenticated, 255 means failed; offline times out
  [[ "$out" == *"successfully authenticated"* ]]                                  # match the text, not the exit code
}

# Packages to link.
PACKAGES=(zsh nvim tmux vim git starship mise atuin bin theme)

# iTerm Dynamic Profile template (theme sync builds the real profile): macOS only.
if [[ "$OSTYPE" == darwin* ]]; then
  PACKAGES+=(iterm)
fi

# Step 1: Homebrew packages.
if command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew packages"
  # Upgrades are a separate, deliberate `brew upgrade`.
  run brew bundle --no-upgrade --file="$REPO/Brewfile"
else
  cat <<'MSG'
Homebrew was not found. Install it first (this script never uses sudo):
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Then follow the "Next steps" it prints to add brew to your PATH, and run this script again.
MSG
  if [[ $DRY -eq 1 ]]; then # a preview should still show the rest of the plan
    echo "[dry-run] continuing without Homebrew" >&2 # make the skipped exit visible
  else
    exit 1 # stop before any change
  fi
fi

# Ghostty is optional: link its config only if the app or binary exists.
HAS_GHOSTTY=0                                                      # 1 once Ghostty is found
for app in "$HOME/Applications/Ghostty.app" /Applications/Ghostty.app; do # Brewfile appdir first, then the old path
  [[ -d $app ]] && HAS_GHOSTTY=1                                   # app bundle present
done
command -v ghostty >/dev/null 2>&1 && HAS_GHOSTTY=1                # Linux package on PATH
if [[ $HAS_GHOSTTY -eq 1 ]]; then
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
BREW_MISE="$(brew --prefix 2>/dev/null || true)/bin/mise" # Homebrew's copy; empty without brew
if [[ -x "$BREW_MISE" && -f "$HOME/.local/bin/mise" && ! -L "$HOME/.local/bin/mise" ]]; then
  echo "==> $HOME/.local/bin/mise shadows the Homebrew mise on PATH; backing it up"
  backup "$HOME/.local/bin/mise"
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

# Plain-symlink fallback used when stow is missing.
link_package() {
  local pkg="$1" file rel
  while IFS= read -r -d '' file; do
    rel="${file#"$REPO/$pkg/"}"
    run mkdir -p "$(dirname "$HOME/$rel")"
    run ln -sfn "$file" "$HOME/$rel"
  done < <(find "$REPO/$pkg" -type f -print0)
}

# Step 2b: the iTerm profile used to be a link into this repo; `theme sync` now writes a real file there.
ITERM_PROFILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist" # generated profile
OLD_TARGET="iterm/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist" # where the old link pointed
if [[ -L "$ITERM_PROFILE" && "$(readlink "$ITERM_PROFILE")" == *"$OLD_TARGET" ]]; then # old stow link (may dangle now)
  echo "==> Removing the old iTerm profile link (theme sync recreates it)"
  run rm "$ITERM_PROFILE" # only the link; the repo file is untouched
fi

# Step 3: link the packages.
echo "==> Linking packages: ${PACKAGES[*]}"
if command -v stow >/dev/null 2>&1; then
  # --no-folding links files, never whole folders: generated files (Ghostty theme.conf) stay out of the repo
  run stow --restow --no-folding --dir="$REPO" --target="$HOME" "${PACKAGES[@]}"
else
  echo "stow not found: falling back to plain symlinks"
  for pkg in "${PACKAGES[@]}"; do
    link_package "$pkg"
  done
fi

# Step 3b: install the global runtimes from the mise config.
if command -v mise >/dev/null 2>&1; then
  echo "==> Installing runtimes with mise"
  run mise install # reads ~/.config/mise/config.toml
else
  echo "==> Skipping mise install: mise not found"
fi

# Step 3b2: import the zsh history into atuin once.
ATUIN_DB="${XDG_DATA_HOME:-$HOME/.local/share}/atuin/history.db" # atuin's default database
if { command -v atuin >/dev/null 2>&1 || [[ $DRY -eq 1 ]]; }; then # in dry-run atuin may not be installed yet
  if [[ ! -e "$ATUIN_DB" ]]; then # first run only: a later run never imports again
    echo "==> Importing the zsh history into atuin"
    run atuin import zsh || echo "warning: atuin import failed; run 'atuin import zsh' later" >&2 # non-fatal
  fi
fi

# Step 3c: remove the https override older installs wrote (the git config now only rewrites pushes to SSH).
GIT_LOCAL="$HOME/.config/git/local" # machine-specific git overrides (untracked, included by the git config)
GIT_LOCAL_MARK="# written by dotfiles install.sh: GitHub over https (no SSH key); removed automatically once SSH works" # only a file starting with this line is ours
is_our_git_local() { # true for the marked file, or the exact two lines older installs wrote without a marker
  [[ -f "$GIT_LOCAL" ]] || return 1                                               # nothing to judge
  [[ "$(head -n1 "$GIT_LOCAL")" == "$GIT_LOCAL_MARK" ]] && return 0               # marked: ours
  [[ "$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$GIT_LOCAL")" == $'[url "https://github.com/"]\ninsteadOf = https://github.com/' ]] # legacy content, nothing else
}
if is_our_git_local; then # our own override, never a hand-written file
  echo "==> Removing the obsolete https override $GIT_LOCAL (fetches no longer go over SSH)"
  run rm -f "$GIT_LOCAL" # no longer needed
fi

# Step 4: tmux plugin manager.
TPM="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM" ]] && command -v git >/dev/null 2>&1; then
  echo "==> Cloning TPM"
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM" # public repo over https, no key needed
fi
# Download the plugins listed in tmux.conf; works without a running tmux server (public repos: https, no SSH key)
if [[ -x "$TPM/bin/install_plugins" || $DRY -eq 1 ]]; then
  echo "==> Installing tmux plugins"
  run "$TPM/bin/install_plugins" || echo "Warning: tmux plugin install failed; press prefix + I in tmux" >&2
fi

# Step 5: Nerd Font for Linux desktop terminals (Ghostty and macOS need nothing).
install_font() {
  local dir="$HOME/.local/share/fonts/${NERD_FONT}NerdFont" tmp # per-user dir, no sudo
  # fc-list shows Monaspice families as "MonaspiceNe Nerd Font", so match the family prefix
  # grep -c reads all input, so fc-list never gets SIGPIPE (which fails the pipe under pipefail)
  if [[ "$(fc-list | grep -ci "${NERD_FONT_FAMILY}.* Nerd Font")" -gt 0 ]] || [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
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

if [[ "$OSTYPE" == linux* ]]; then
  if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then # headless: the local terminal renders fonts
    echo "==> Skipping Nerd Font: no graphical session (headless server)"
  elif command -v fc-cache >/dev/null 2>&1 && command -v fc-list >/dev/null 2>&1; then # needs fontconfig
    install_font
  else
    echo "==> Skipping Nerd Font: fontconfig (fc-cache, fc-list) not found"
  fi
fi

# Step 5b: generate the Ghostty and iTerm theme files from ~/.config/theme/config.
echo "==> Generating terminal theme files (theme sync)"
# a failed sync (offline, unknown theme name) must not stop the install
run "$REPO/bin/.local/bin/theme" sync || echo "Warning: theme sync failed; run 'theme sync' later" >&2

CLAUDE_SKIPPED=0 # 1 = the Claude step was skipped, so the script exits non-zero
# Step 6: optional private Claude config (opt-in).
if [[ $WITH_CLAUDE -eq 1 ]]; then
  echo "==> Setting up Claude config in $CLAUDE_DIR"
  if [[ ! -e "$CLAUDE_DIR" && $DRY -eq 1 ]]; then # dry-run stays offline and leaves known_hosts alone
    echo "[dry-run] would check GitHub SSH access"
    run git clone "$CLAUDE_REPO_URL" "$CLAUDE_DIR"
  elif [[ ! -e "$CLAUDE_DIR" ]] && ! github_ssh_ok; then # the private repo needs your GitHub key
    CLAUDE_SKIPPED=1 # reported at the end, with a non-zero exit
    cat >&2 <<'ERR'
Warning: skipping the Claude config: no GitHub SSH access on this machine.
  On your Mac, add "ForwardAgent yes" to this host in ~/.ssh/config and check that
  "ssh-add -l" lists your GitHub key. Reconnect, then run: ./install.sh --with-claude
  (see docs/server.md)
ERR
  elif [[ ! -e "$CLAUDE_DIR" ]]; then
    run git clone "$CLAUDE_REPO_URL" "$CLAUDE_DIR" # access was checked above
  elif git -C "$CLAUDE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Claude config already there: $CLAUDE_DIR (not pulling)"
  else
    echo "Warning: $CLAUDE_DIR exists but is not a git repo: skipping" >&2
  fi
  # run its own installer once it is there (in dry-run the clone is only printed)
  if [[ $CLAUDE_SKIPPED -eq 0 && ( -x "$CLAUDE_DIR/install.sh" || $DRY -eq 1 ) ]]; then # not after a skipped clone
    run "$CLAUDE_DIR/install.sh"
  fi
fi

cat <<'MSG'

Done. Next steps:
  1. Open tmux; plugins are installed already (prefix + I, Ctrl+Space then Shift+i, retries).
  2. Open nvim once and let lazy.nvim install plugins (run :Mason to check LSP tools).
  3. Move secrets and machine-specific settings into ~/.zshrc.local (sourced last).
  4. Put machine-specific git settings in ~/.config/git/local.
  5. Start a new shell (exec zsh).
MSG

# Print the command that makes zsh the login shell; prints nothing if it already is.
suggest_login_shell() {
  local current zsh_path=""                                                     # current login shell, zsh to recommend
  if [[ "$OSTYPE" == darwin* ]]; then                                           # macOS keeps users in Directory Services
    current="$(dscl . -read ~/ UserShell 2>/dev/null | awk '{print $2}')"       # $SHELL can be stale
    zsh_path="/bin/zsh"                                                         # always shipped with macOS
  else
    current="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7)"   # passwd entry, not the current process
    if [[ -x /usr/bin/zsh ]] && grep -qx /usr/bin/zsh /etc/shells 2>/dev/null; then # chsh only accepts listed shells
      zsh_path="/usr/bin/zsh"                                                   # the system zsh
    else
      zsh_path="$(grep -m1 '/zsh$' /etc/shells 2>/dev/null || true)"            # first listed zsh (empty if none)
    fi
  fi
  current="${current:-${SHELL:-unknown}}"                                       # fall back when the lookup failed
  [[ "$(basename "$current")" == zsh ]] && return 0                             # already zsh: say nothing
  [[ -n "$zsh_path" ]] || return 0                                              # no usable zsh to suggest
  echo
  echo "Your login shell is $current. Make zsh the default (then log out and back in):"
  if [[ "$OSTYPE" == darwin* ]]; then                                           # no sudo needed on macOS
    echo "  chsh -s $zsh_path"                                                  # changes the current user
  else
    echo "  sudo chsh -s $zsh_path \"\$USER\""                                    # EC2-style users have no password
  fi
}
suggest_login_shell

if [[ $CLAUDE_SKIPPED -eq 1 ]]; then # a skipped step must not look like success
  echo >&2
  echo "The Claude config was NOT installed (no GitHub SSH access). Fix that and run ./install.sh --with-claude again." >&2
  exit 1 # visible to scripts and to the eye, after everything else finished
fi
