# dotfiles

Personal, cross-platform (macOS + Linux) shell and editor setup, managed with [GNU Stow](https://www.gnu.org/software/stow/). Every config line has a short comment, so the files double as a learning reference.

Each top-level folder is a **stow package**: its contents mirror `$HOME`. For example `git/.config/git/config` becomes `~/.config/git/config`.

## Quick start

### macOS

```sh
xcode-select --install   # Git and compilers, if you do not have them yet
git clone https://github.com/pedrojimenezp/dotfiles ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./install.sh             # brew bundle, back up old files, stow, clone TPM
```

Install [Homebrew](https://brew.sh) first if `brew` is missing (`install.sh` prints the command and stops).

### Linux

1. Install `git`, `curl`, `zsh` and build tools with your package manager (you run this).
2. Install Homebrew for Linux (no sudo needed after its prerequisites):
   `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`, then follow the "Next steps" it prints.
3. Clone this repo and run `./install.sh`.
4. Make zsh your login shell: `chsh -s "$(command -v zsh)"`, then log out and back in.

### After installing

1. In tmux press `Ctrl+Space`, then `Shift+i` to install the plugins.
2. Open `nvim` once and wait for lazy.nvim, Mason and treesitter to install everything.
3. Move secrets and machine settings into `~/.zshrc.local` (sourced last, not tracked).
4. Put machine-specific git settings in `~/.config/git/local`.

`install.sh` is idempotent. If `stow` is missing it falls back to plain symlinks. Existing real files are renamed to `<file>.backup-YYYYmmdd-HHMMSS`. `~/.gitconfig` is backed up too, because it takes precedence over `~/.config/git/config`.

```sh
./install.sh --dry-run   # show what would happen, change nothing
./install.sh --server    # no Homebrew: only zsh, tmux, vim, git, bin
```

## Packages

| Package | Links to | What it does |
| --- | --- | --- |
| `zsh` | `~/.zshrc` | Plain zsh: history, completion, aliases, fzf, zoxide, mise, starship, autosuggestions, syntax highlighting. Sources `~/.zshrc.local` last. |
| `nvim` | `~/.config/nvim` | Neovim 0.11+ config (lazy.nvim, LSP, treesitter, telescope, conform, blink.cmp). |
| `tmux` | `~/.config/tmux/tmux.conf` | tmux with prefix `Ctrl+Space`, vi copy mode, TPM plugins, minimal status line. |
| `vim` | `~/.vimrc` | Small plugin-free vimrc for servers. |
| `git` | `~/.config/git/{config,ignore}` | Git defaults, delta pager, aliases, global ignores, `local` include. |
| `starship` | `~/.config/starship.toml` | Prompt layout. |
| `ghostty` | `~/.config/ghostty/config` | Ghostty terminal (optional; linked only if Ghostty is installed). |
| `bin` | `~/.local/bin` | Scripts on PATH: `tmux-sessionizer`. |

### Server mode

`./install.sh --server` skips Homebrew and Ghostty, and stows only `zsh`, `tmux`, `vim`, `git` and `bin`. The zsh config guards every tool, so it works with only the tools the server has. Over SSH, tmux (`set-clipboard on`) and nvim (OSC 52) copy to your local clipboard.

## iTerm settings

No file needed. In iTerm2 > Settings > Profiles:

- **Keys > General**: set Left Option key to `Esc+` (so Alt maps work in nvim and tmux).
- **Text > Font**: pick `JetBrainsMono Nerd Font` (icons in the prompt, nvim and eza).
- **Terminal > Report terminal type**: `xterm-256color`. Colors are true color, set in the profile's color preset (try Tokyo Night).

## Key cheat sheet

### tmux (prefix: `Ctrl+Space`)

| Keys | Action |
| --- | --- |
| `prefix \|` / `prefix -` | Split left/right, top/bottom (current path) |
| `prefix c` | New window (current path) |
| `prefix H/J/K/L` | Resize pane (repeatable) |
| `Ctrl+h/j/k/l` | Move between panes and nvim splits (no prefix) |
| `prefix [` then `v`, `y` | Copy mode: select, copy (also to the system clipboard) |
| `prefix f` | Project session picker (fzf over `~/projects`, or `$SESSIONIZER_DIRS`) |
| `prefix r` | Reload `tmux.conf` |
| `prefix I` | Install TPM plugins |
| `prefix Ctrl+s` / `Ctrl+r` | Save / restore sessions (resurrect) |
| `prefix Ctrl+l` | Clear the screen |

vim-tmux-navigator takes `Ctrl+L` without prefix, so clear the screen with `prefix` then `Ctrl+L`.

### Neovim (leader: `Space`)

| Keys | Action |
| --- | --- |
| `jk` | Leave insert mode |
| `<leader>w` / `q` | Save / quit window |
| `Ctrl+w v` / `Ctrl+w s` | Split vertically / horizontally (built in) |
| `<leader>sf` / `sg` / `sw` | Search files / grep / word under cursor |
| `<leader><leader>` / `s.` | Open buffers / recent files |
| `<leader>/` | Fuzzy search in the current buffer |
| `<leader>sh` / `sk` / `sd` / `sr` | Help / keymaps / diagnostics / resume |
| `<leader>gc` / `gb` | Git commits / branches (telescope) |
| `-` | Open parent directory (oil) |
| `gd` / `grr` / `gri` | Definition / references / implementation |
| `<leader>D` | Type definition |
| `<leader>ds` / `ws` | Document / workspace symbols |
| `grn` / `gra` / `K` | Rename / code action / hover (Neovim defaults) |
| `<leader>rn` / `ca` / `th` | Rename / code action / toggle inlay hints |
| `<leader>f` | Format buffer (also on save) |
| `]c` / `[c`, `<leader>hs/hr/hp/hb` | Git hunks: next/prev, stage, reset, preview, blame |
| `<leader>e` / `dq` | Show diagnostic under cursor / send diagnostics to the location list |
| `Alt+j` / `Alt+k` | Move line or selection |
| `sa` / `sd` / `sr` | mini.surround: add, delete, replace |

Press `<leader>` and wait: which-key lists the options.

## Tools

- **neovim**: editor. **tmux**: sessions and panes. **stow**: symlinks the packages.
- **zsh-autosuggestions** / **zsh-syntax-highlighting** / **zsh-completions**: zsh plugins.
- **starship**: prompt. **fzf**: fuzzy search for history and files. **zoxide**: smart `cd`.
- **eza**: better `ls`. **bat**: better `cat`. **ripgrep** (`rg`): fast grep. **fd**: fast find.
- **jq** / **yq**: JSON / YAML processors. **btop**: system monitor. **tealdeer** (`tldr`): command examples. **hyperfine**: benchmarks.
- **git-delta**: diff pager. **lazygit** / **lazydocker**: terminal UIs. **dive**: Docker layer explorer. **gh**: GitHub CLI. **git-lfs**: large files in git.
- **mise**: per-project runtimes. **zig** / **zls**: Zig toolchain and language server.
- **shellcheck** / **shfmt** / **golangci-lint**: shell and Go linters/formatters. **tree-sitter-cli**: builds treesitter parsers.
- macOS only (casks): **ghostty** terminal and the **JetBrainsMono Nerd Font**.
- Optional (commented in `Brewfile`): **atuin** (shared shell history), **mosh** (roaming-proof SSH).

## SSH

Keep `~/.ssh/config` out of this repo (it is private). A good starting point, with host aliases and connection sharing so repeated `ssh`/`scp` is instant:

```sshconfig
# ~/.ssh/config (example, not stowed)
Host myserver
  # Server address
  HostName 203.0.113.10
  # Remote user
  User pedro
  # Key to use
  IdentityFile ~/.ssh/id_ed25519

Host *
  # Reuse one connection for many sessions
  ControlMaster auto
  # Socket file for the shared connection
  ControlPath ~/.ssh/cm-%r@%h:%p
  # Keep it open 10 minutes after the last use
  ControlPersist 10m
  # Keepalive so idle sessions do not drop
  ServerAliveInterval 30
```

For flaky networks or roaming laptops, install `mosh` (uncomment it in the `Brewfile`): `mosh myserver` survives sleep and IP changes. Run it inside tmux. Ghostty's `ssh-terminfo` feature installs its terminfo on servers you connect to.

## License

See [LICENSE](LICENSE).
