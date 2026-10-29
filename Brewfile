# Brewfile: install everything with `brew bundle` (see install.sh).

cask_args appdir: "~/Applications" # per-user app folder: casks never need sudo or admin rights

# --- Editor and terminal ---
brew "neovim"                  # main editor (Lua config in nvim/)
brew "tmux"                    # terminal multiplexer: sessions, windows, panes
brew "stow"                    # symlink manager that links this repo into $HOME
brew "tmux-fingers"            # binary for the tmux-fingers plugin: hint-based copy (prefix Space)
brew "starship"                # fast, customizable shell prompt
brew "zsh-autosuggestions"     # fish-style suggestions from history while typing
brew "zsh-syntax-highlighting" # colors valid/invalid commands as you type
brew "zsh-completions"         # extra tab-completion definitions for zsh

# --- Shell productivity ---
brew "fzf"                     # fuzzy finder: Ctrl-R history, Ctrl-T files, Alt-C dirs
brew "zoxide"                  # smarter cd: `z foo` jumps to a frequent directory
brew "eza"                     # modern ls with colors and git status
brew "bat"                     # cat with syntax highlighting
brew "ripgrep"                 # very fast recursive grep (`rg`)
brew "fd"                      # simple, fast find alternative
brew "jq"                      # JSON processor for the command line
brew "yq"                      # jq-like processor for YAML/TOML/XML
brew "btop"                    # resource monitor (CPU, memory, disks, network)
brew "tealdeer"                # fast tldr client: short command examples (`tldr tar`)
brew "hyperfine"               # command-line benchmarking
# brew "atuin"                 # optional: searchable shell history, syncable across machines
# brew "mosh"                  # optional: SSH-like shell that survives roaming and sleep

# --- Git and containers ---
brew "git-delta"               # syntax-highlighting pager for git diff/log
brew "lazygit"                 # terminal UI for git
brew "lazydocker"              # terminal UI for Docker
brew "dive"                    # explore Docker image layers
brew "gh"                      # GitHub CLI
brew "git-lfs"                 # large file storage for git (referenced in the git config filter)

# --- Languages and dev tools ---
brew "mise"                    # per-project runtime manager (node, go, python, ...)
brew "zig"                     # Zig compiler
brew "zls"                     # Zig language server (must match the zig version, so not from Mason)
brew "shellcheck"              # linter for shell scripts
brew "tree-sitter-cli"         # needed by nvim-treesitter (main branch) to compile parsers
brew "shfmt"                   # formatter for shell scripts
brew "golangci-lint"           # Go linter aggregator

# --- macOS-only apps and fonts ---
if OS.mac?
  cask "ghostty"                          # GPU-accelerated terminal emulator
  cask "font-monaspice-nerd-font"         # Monaspace (GitHub Next) Nerd Font, used by Ghostty and iTerm
end
