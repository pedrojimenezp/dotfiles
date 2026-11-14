#!/usr/bin/env bash
# Install these dotfiles: back up conflicting files, then link packages with GNU Stow.
# Usage: ./install.sh [--dry-run] [--with-claude <git-url>]
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO/common.sh"
REPO_REAL="$(cd "$REPO" && pwd -P)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
WITH_CLAUDE=0
CLAUDE_REPO_URL=""
CLAUDE_DIR="$HOME/.config/claude-shared"
NERD_FONT="Monaspace" # Nerd Fonts release archive name
NERD_FONT_FAMILY="Monaspice" # family prefix fc-list reports (Nerd Fonts renames Monaspace)

usage() { echo "Usage: $0 [--dry-run] [--with-claude <git-url>]"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --with-claude=*)
      WITH_CLAUDE=1
      CLAUDE_REPO_URL="${1#--with-claude=}"
      ;;
    --with-claude)
      WITH_CLAUDE=1
      CLAUDE_REPO_URL="${2:-}"
      [[ $# -gt 1 ]] && shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done
if [[ $WITH_CLAUDE -eq 1 && ( -z "$CLAUDE_REPO_URL" || "$CLAUDE_REPO_URL" == -* ) ]]; then # a flag is not a URL
  echo "--with-claude needs the git URL of your Claude config repo." >&2
  usage >&2
  exit 1
fi

# Linux also needs git, curl, unzip (mise), stow and libatomic1 (node); a desktop needs xz for the font.
# Never sudo: only print the command.
NEEDED=(zsh)
MISSING=()
if [[ "$OSTYPE" == linux* ]]; then
  NEEDED+=(git curl unzip stow) # macOS ships git, curl and unzip; brew installs stow
  [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && NEEDED+=(xz)
  { /sbin/ldconfig -p 2>/dev/null || ldconfig -p 2>/dev/null || true; } | grep -q 'libatomic\.so\.1' || MISSING+=(libatomic1)
fi
for cmd in "${NEEDED[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd") # collect every gap, so one run reports them all
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  if [[ "$OSTYPE" == linux* ]] && command -v apt-get >/dev/null 2>&1; then
    PKGS=("${MISSING[@]/xz/xz-utils}") # the xz command comes from xz-utils
    echo "Missing: ${MISSING[*]}. An admin installs them once (this script never uses sudo):" >&2
    echo "  sudo apt-get update && sudo apt-get install -y ${PKGS[*]}" >&2
  else
    echo "Missing: ${MISSING[*]}. Install them with your package manager, then run this script again." >&2
  fi
  if [[ $DRY -eq 1 ]]; then # a preview still shows the rest of the plan
    echo "[dry-run] continuing without ${MISSING[*]}" >&2
  else
    exit 1
  fi
fi

run() {
  if [[ $DRY -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

# Step 1: Homebrew (macOS only; Linux gets its tools from mise).
if [[ "$OSTYPE" == darwin* ]]; then
  # A fresh SSH login (bash) has no brew on PATH.
  if ! command -v brew >/dev/null 2>&1; then
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [[ -x $brew_bin ]]; then
        eval "$("$brew_bin" shellenv)"
        break
      fi
    done
  fi
  if command -v brew >/dev/null 2>&1; then
    step "Installing Homebrew packages"
    # Upgrades are a separate, deliberate `brew upgrade`.
    if run brew bundle --no-upgrade --file="$REPO/Brewfile"; then
      finish "Homebrew packages installed"
    else
      echo "Warning: brew bundle failed; run 'brew bundle' later" >&2
      finish "Homebrew packages: brew bundle failed"
    fi
    # compinit prompts about group/other-writable completion dirs, which brew can recreate.
    step "Removing group/other write from Homebrew's zsh completion dirs (chmod go-w)"
    BREW_SHARE="$(brew --prefix)/share"
    CHMODDED=0
    for d in "$BREW_SHARE" "$BREW_SHARE/zsh" "$BREW_SHARE/zsh/site-functions"; do
      if [[ -d $d && -O $d ]]; then
        run chmod go-w "$d"
        CHMODDED=$((CHMODDED + 1))
      fi
    done
    finish "Changed $CHMODDED folders"
  else
    step "Installing Homebrew packages"
    cat <<'MSG'
Homebrew was not found. Install it first (this script never uses sudo):
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Then follow the "Next steps" it prints to add brew to your PATH, and run this script again.
MSG
    if [[ $DRY -eq 1 ]]; then # a preview still shows the rest of the plan
      echo "[dry-run] continuing without Homebrew" >&2
      finish "Skipped: Homebrew not found"
    else
      exit 1
    fi
  fi
fi

# Packages that apply here (after Homebrew, which can install Ghostty).
PACKAGES=()
while IFS= read -r pkg; do PACKAGES+=("$pkg"); done < <(packages_here)

# True if $1 resolves (through any symlinks) to a file inside this repo.
is_repo_link() {
  local resolved
  resolved="$(realpath "$1" 2>/dev/null)" || return 1 # follows links, incl. folded directories
  [[ "$resolved" == "$REPO_REAL"/* ]]
}

# Move a real file (not one of our links) out of the way.
BACKED_UP=0
backup() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]] && ! is_repo_link "$path"; then
    echo "backup: $path -> $path.backup-$STAMP"
    run mv "$path" "$path.backup-$STAMP"
    BACKED_UP=$((BACKED_UP + 1))
  fi
}

# Step 2: back up every file a package would link, so stow never conflicts.
step "Backing up existing files"
for pkg in "${PACKAGES[@]}"; do
  while IFS= read -r -d '' file; do
    rel="${file#"$REPO/$pkg/"}"
    backup "$HOME/$rel"
  done < <(find "$REPO/$pkg" -type f -print0)
done
# ~/.gitconfig wins over ~/.config/git/config, so it must move away too.
if [[ " ${PACKAGES[*]} " == *" git "* ]]; then
  backup "$HOME/.gitconfig"
fi
finish "Backed up $BACKED_UP files"

# Step 3: link the packages.
step "Linking packages: ${PACKAGES[*]}"
if ! command -v stow >/dev/null 2>&1 && [[ $DRY -eq 0 ]]; then
  echo "stow is required and was not found. Install it (brew install stow, or apt-get install stow) and run this script again." >&2
  exit 1
fi
# --no-folding: generated files (Ghostty theme.conf) stay out of the repo
run stow --restow --no-folding --dir="$REPO" --target="$HOME" "${PACKAGES[@]}"
finish "Linked ${#PACKAGES[@]} packages"

# Step 4: install mise if missing (per user, no sudo), then every tool of its config.
export PATH="$HOME/.local/bin:$PATH"
if ! command -v mise >/dev/null 2>&1; then
  step "Installing mise into ~/.local/bin"
  if with_heartbeat run sh -c 'curl -fsSL https://mise.run | sh'; then
    finish "mise installed"
  else
    echo "Warning: could not install mise; run it again later" >&2
    finish "mise: install failed"
  fi
fi
step "Installing tools with mise"
if command -v mise >/dev/null 2>&1; then
  if run mise install; then
    finish "mise tools installed"
  else
    echo "Warning: some mise tools failed; run 'mise install' later" >&2
    finish "mise tools: install failed"
  fi
  # Later steps (tmux plugins) need the mise tools on PATH.
  [[ $DRY -eq 1 ]] || eval "$(mise env -s bash)" || true
else
  finish "Skipped: mise not found"
fi

# Step 5: zsh plugins as git clones, the same on every OS.
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh-plugins"
PLUGINS_OK=0
PLUGINS_FAILED=0
clone_plugin() { # $1 = folder name, $2 = GitHub repo path
  local dir="$ZSH_PLUGIN_DIR/$1"
  if [[ -d "$dir/.git" ]]; then
    if with_heartbeat run git -C "$dir" pull --ff-only --quiet; then # offline or local edits fail the pull
      PLUGINS_OK=$((PLUGINS_OK + 1))
    else
      echo "Warning: could not update $1; keeping it as it is" >&2
      PLUGINS_FAILED=$((PLUGINS_FAILED + 1))
    fi
  elif with_heartbeat run git clone --depth 1 --quiet "https://github.com/$2" "$dir"; then
    PLUGINS_OK=$((PLUGINS_OK + 1))
  else
    echo "Warning: could not clone $1" >&2
    PLUGINS_FAILED=$((PLUGINS_FAILED + 1))
  fi
}
step "Installing zsh plugins in $ZSH_PLUGIN_DIR"
run mkdir -p "$ZSH_PLUGIN_DIR"
clone_plugin zsh-autosuggestions zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting zsh-users/zsh-syntax-highlighting
clone_plugin zsh-completions zsh-users/zsh-completions
clone_plugin fzf-tab Aloxaf/fzf-tab
finish "zsh plugins installed or updated: $PLUGINS_OK, failed: $PLUGINS_FAILED"

# Step 6: tmux plugin manager, then the plugins.
TPM="$HOME/.config/tmux/plugins/tpm"
# TPM reads TMUX_PLUGIN_MANAGER_PATH from a tmux server (set-environment in tmux.conf). A server that is already
# running (or the one we are inside) started before the config was linked, so it lacks the variable. Run the
# whole install on a private server instead: its own TMUX_TMPDIR socket, TMUX unset, killed at the end.
install_tmux_plugins() {
  local tmp rc=0
  if [[ $DRY -eq 1 ]]; then tmp="<temp dir>"; else tmp="$(mktemp -d)" || return 1; fi
  local -a priv=(env -u TMUX TMUX_TMPDIR="$tmp") # TPM's tmux calls inherit this and hit the private server
  run "${priv[@]}" tmux new-session -d -s dotfiles-tpm || rc=1
  [[ $rc -eq 0 ]] && { with_heartbeat run "${priv[@]}" "$TPM/bin/install_plugins" || rc=1; }
  run "${priv[@]}" tmux -S "$tmp/tmux-$(id -u)/default" kill-server || true # by socket path: only the private server dies
  [[ $DRY -eq 1 ]] || rm -rf "$tmp"
  return "$rc"
}
TMUX_PLUGINS_OK=0
step "Installing tmux plugins"
if [[ ! -d "$TPM" ]] && command -v git >/dev/null 2>&1; then
  with_heartbeat run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM" || echo "Warning: could not clone TPM" >&2
fi
if [[ ( -x "$TPM/bin/install_plugins" || $DRY -eq 1 ) ]] && { command -v tmux >/dev/null 2>&1 || [[ $DRY -eq 1 ]]; }; then
  if install_tmux_plugins; then
    TMUX_PLUGINS_OK=1
    finish "tmux plugins installed"
  else
    echo "Warning: tmux plugin install failed; press prefix + I in tmux" >&2
    finish "tmux plugins: install failed"
  fi
else
  finish "Skipped: tmux or TPM not found"
fi

# Step 7: Nerd Font for Linux desktop terminals (Ghostty and macOS need nothing).
install_font() {
  local dir="$HOME/.local/share/fonts/${NERD_FONT}NerdFont" tmp
  step "Installing ${NERD_FONT} Nerd Font"
  # grep -c reads all input, so fc-list never gets SIGPIPE under pipefail
  if [[ "$(fc-list | grep -ci "${NERD_FONT_FAMILY}.* Nerd Font")" -gt 0 ]] || [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
    finish "Already installed"
    return 0
  fi
  if [[ $DRY -eq 1 ]]; then tmp="<tmpdir>"; else tmp="$(mktemp -d)" || { finish "Skipped: no temp folder"; return 0; }; fi
  # A failure must not stop the install: drop the partial folder so the next run retries.
  if with_heartbeat run curl -fsSL -o "$tmp/font.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.tar.xz" &&
    run mkdir -p "$dir" &&
    with_heartbeat run tar -xJf "$tmp/font.tar.xz" -C "$dir" &&
    run fc-cache -f; then
    finish "${NERD_FONT} Nerd Font installed"
  else
    echo "Warning: font install failed, re-run install.sh to retry" >&2
    [[ $DRY -eq 1 ]] || rm -rf "$dir"
    finish "Nerd Font: install failed"
  fi
  [[ $DRY -eq 1 ]] || rm -rf "$tmp"
  return 0
}

if [[ "$OSTYPE" == linux* ]]; then
  if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then # headless: the local terminal renders fonts
    step "Installing ${NERD_FONT} Nerd Font"
    finish "Skipped: no graphical session (headless server)"
  elif command -v fc-cache >/dev/null 2>&1 && command -v fc-list >/dev/null 2>&1; then
    install_font
  else
    step "Installing ${NERD_FONT} Nerd Font"
    finish "Skipped: fontconfig (fc-cache, fc-list) not found"
  fi
fi

# Step 8: Ghostty and iTerm theme files.
step "Generating terminal theme files (theme sync)"
# offline or unknown theme: must not stop the install
if with_heartbeat run "$REPO/bin/.local/bin/theme" sync; then
  finish "Theme files generated"
else
  echo "Warning: theme sync failed; run 'theme sync' later" >&2
  finish "Theme files: sync failed"
fi

CLAUDE_SKIPPED=0 # 1 = exit non-zero at the end
# Step 9: optional Claude config; its pull.sh pulls and installs it.
if [[ $WITH_CLAUDE -eq 1 ]]; then
  step "Setting up Claude config in $CLAUDE_DIR"
  if [[ ! -e "$CLAUDE_DIR" ]]; then
    run git clone "$CLAUDE_REPO_URL" "$CLAUDE_DIR" || {
      CLAUDE_SKIPPED=1
      echo "Warning: could not clone $CLAUDE_REPO_URL. A private repo needs your GitHub SSH key (see docs/server.md)." >&2
    }
  elif ! git -C "$CLAUDE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_SKIPPED=1 # its scripts must not run from an unknown folder
    echo "Warning: $CLAUDE_DIR exists but is not a git repo: skipping" >&2
  fi
  if [[ $CLAUDE_SKIPPED -eq 0 ]]; then
    # a failed pull keeps the clone as it is; pull.sh still installs it
    if run "$CLAUDE_DIR/pull.sh" --install; then
      finish "Claude config installed"
    else
      echo "Warning: the Claude config pull or install failed (see above)" >&2
      finish "Claude config: pull or install failed"
    fi
  else
    finish "Skipped: Claude config not installed"
  fi
fi

# Step 10: make sure git has a commit identity (name and email from any config).
ensure_git_identity() {
  local name email local_file="$HOME/.config/git/local"
  step "Checking the git identity"
  name="$(git config --global --includes user.name 2>/dev/null || true)"
  email="$(git config --global --includes user.email 2>/dev/null || true)"
  if [[ -n "$name" && -n "$email" ]]; then
    finish "Git identity: $name <$email>"
    return 0
  fi
  if [[ -t 0 && $DRY -eq 0 ]]; then # only ask a person, never a pipe or a preview
    if [[ -z "$name" ]]; then
      read -r -p "Name for git commits: " name
      [[ -n "$name" ]] && git config --file "$local_file" user.name "$name"
    fi
    if [[ -z "$email" ]]; then
      read -r -p "Email for git commits: " email
      [[ -n "$email" ]] && git config --file "$local_file" user.email "$email"
    fi
    finish "Git identity saved in $local_file"
  else
    echo "Git has no commit identity yet. Set it with:"
    echo "  git config --file ~/.config/git/local user.name \"Your Name\""
    echo "  git config --file ~/.config/git/local user.email you@example.com"
    finish "Skipped: git identity not set"
  fi
  return 0
}
ensure_git_identity

if [[ $TMUX_PLUGINS_OK -eq 1 ]]; then
  TMUX_STEP="Open tmux; the plugins are installed already (if one is missing: Ctrl+Space, then Shift+i)."
else
  TMUX_STEP="Open tmux and press Ctrl+Space, then Shift+i, to install the plugins (the install above did not finish)."
fi

cat <<MSG
Done. Next steps:
  1. $TMUX_STEP
  2. Open nvim once and let lazy.nvim install plugins (run :Mason to check LSP tools).
  3. Move secrets and machine-specific settings into ~/.zshrc.local (loaded near the end, after all other settings).
  4. Put other machine-specific git settings (work email, signing) in ~/.config/git/local.
  5. Start a new shell (exec zsh).
MSG

# Print the command that makes zsh the login shell; prints nothing if it already is.
suggest_login_shell() {
  local current zsh_path=""
  if [[ "$OSTYPE" == darwin* ]]; then
    current="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')" # $SHELL can be stale
    zsh_path="/bin/zsh"
  else
    current="$(getent passwd "${USER:-$(id -un)}" 2>/dev/null | cut -d: -f7)" # passwd entry, not the current process
    if [[ -x /usr/bin/zsh ]] && grep -qx /usr/bin/zsh /etc/shells 2>/dev/null; then # chsh only accepts listed shells
      zsh_path="/usr/bin/zsh"
    else
      zsh_path="$(grep -m1 '/zsh$' /etc/shells 2>/dev/null || true)"
    fi
  fi
  current="${current:-${SHELL:-unknown}}"
  [[ "$(basename "$current")" == zsh ]] && return 0
  [[ -n "$zsh_path" ]] || return 0
  echo
  echo "Your login shell is $current. Make zsh the default (then log out and back in):"
  if [[ "$OSTYPE" == darwin* ]]; then
    echo "  chsh -s $zsh_path"
  else
    echo "  sudo chsh -s $zsh_path \"\$USER\"" # EC2-style users have no password
  fi
  echo "With SSH connection sharing (ControlMaster), also run 'ssh -O exit <user>@<host>' (the same destination you ssh to) on your laptop, or reconnecting keeps the old shell."
  local sys_ver
  sys_ver="$(/usr/bin/tmux -V 2>/dev/null | sed -n 's/^tmux \([0-9]*\.[0-9]*\).*/\1/p')"
  if [[ -n "$sys_ver" ]] && (( ${sys_ver%%.*} < 3 || ( ${sys_ver%%.*} == 3 && ${sys_ver#*.} < 7 ) )); then # tmux.conf needs 3.7+
    echo "Until then, bash does not put mise's tools on PATH, so logins start the system tmux $sys_ver and tmux.conf shows errors."
    echo "After switching, stop the old server with: tmux kill-server"
  fi
}
suggest_login_shell

if [[ $CLAUDE_SKIPPED -eq 1 ]]; then # a skipped step must not look like success
  echo >&2
  echo "The Claude config was NOT installed (see the warning above). Fix that and run ./install.sh --with-claude <git-url> again." >&2
  exit 1
fi
