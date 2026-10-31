# Brewfile: macOS only (`brew bundle`, run by install.sh). Linux needs no Homebrew.
# CLI tools come from mise (mise/.config/mise/config.toml); only what mise cannot provide is here.

cask_args appdir: "~/Applications" # per-user app folder: casks never need sudo or admin rights

brew "mise"                    # installs the CLI tools of this setup, per user
brew "stow"                    # symlink manager that links this repo into $HOME
brew "btop"                    # resource monitor (CPU, memory, disks, network); mise has no macOS build
# brew "mosh"                  # optional: SSH-like shell that survives roaming and sleep

# --- macOS-only apps and fonts ---
cask "ghostty"                          # GPU-accelerated terminal emulator
cask "font-monaspice-nerd-font"         # Monaspace (GitHub Next) Nerd Font, used by Ghostty and iTerm
