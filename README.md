# dotfiles

Personal, cross-platform (macOS + Linux) shell and editor setup, managed with [GNU Stow](https://www.gnu.org/software/stow/). Every config line has a short comment, so the files double as a learning reference.

Each top-level folder is a **stow package**: its contents mirror `$HOME`. For example `git/.config/git/config` becomes `~/.config/git/config`.

## Quick start

### macOS

```sh
xcode-select --install   # Git and compilers, if you do not have them yet
git clone https://github.com/pedrojimenezp/dotfiles ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./install.sh             # brew bundle, back up old files, stow, clone TPM, mise install
```

macOS apps (casks) install into `~/Applications`, so no admin rights are needed. `install.sh` only installs what is missing and never upgrades: run `brew upgrade` yourself when you want updates.

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
./install.sh --with-claude  # also clone and install the private Claude config (needs GitHub SSH access)
```

## Packages

| Package | Links to | What it does |
| --- | --- | --- |
| `zsh` | `~/.zshrc` | Plain zsh: history, completion, aliases, fzf, zoxide, mise, starship, autosuggestions, syntax highlighting. Sources `~/.zshrc.local` last. |
| `nvim` | `~/.config/nvim` | Neovim 0.12 config (lazy.nvim, LSP, treesitter, telescope, conform, blink.cmp). |
| `tmux` | `~/.config/tmux/tmux.conf` | tmux with prefix `Ctrl+Space`, vi copy mode, TPM plugins, minimal status line that follows the terminal palette. |
| `vim` | `~/.vimrc` | Small plugin-free vimrc for servers. |
| `git` | `~/.config/git/{config,ignore}` | Git defaults, delta pager, aliases, global ignores, `local` include. |
| `starship` | `~/.config/starship.toml` | Prompt layout. |
| `ghostty` | `~/.config/ghostty/config` | Ghostty terminal (optional; linked only if Ghostty is installed). Uses the Monaspice Nerd Font (Neon and Radon). |
| `iterm` | `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist` | iTerm2 Dynamic Profile "Dotfiles" (macOS only): Monaspace Neon font, Tokyo Night colors, Option as Esc+. |
| `mise` | `~/.config/mise/config.toml` | Global mise defaults: node (LTS) and go (latest), `.nvmrc` support. Zig stays in Homebrew. |
| `bin` | `~/.local/bin` | Scripts on PATH: `tmux-sessionizer`, `theme` (light/dark switch). |

### Server mode

`./install.sh --server` skips Homebrew and Ghostty, and stows only `zsh`, `tmux`, `vim`, `git` and `bin`. The zsh config guards every tool, so it works with only the tools the server has. Over SSH, tmux (`set-clipboard on`) and nvim (OSC 52) copy to your local clipboard.

## Runtimes (mise)

Global defaults (node LTS, latest go) live in the `mise` package, so `mise use -g <tool>@<version>` edits the repo file through the symlink: commit the change. Zig stays in Homebrew because the zig and zls versions must match.

- **Per project**: `mise use node@22 go@1.25` creates a `mise.toml` to commit. Versions switch on `cd`. It also supports `[env]`, `[tasks]` and an untracked `mise.local.toml` for secrets.
- **New machine**: `./install.sh` runs `mise install` (or run it yourself).
- **Updates**: `mise outdated` shows what is behind, `mise upgrade` updates it.
- **Go**: the `toolchain` line in `go.mod` still works. `go install` tools land in `~/go/bin`.
- **Old mise**: a standalone mise in `~/.local/bin` comes first on PATH and shadows the Homebrew one, so `./install.sh` renames it to `mise.backup-<stamp>` (full mode only).

## Claude Code

The Claude setup lives in a separate private repo (`claude-config`), because it changes every session and holds private rules and logs. `.zshrc` sources `~/.config/claude-shared/zsh/claude.zsh` only when it exists, so these dotfiles work without it.

On a new machine run `./install.sh --with-claude` (needs GitHub SSH access). It clones the repo to `~/.config/claude-shared` (or `$CLAUDE_SHARED_DIR`) and runs its `install.sh`. An existing clone is left alone, not pulled. Not available with `--server`.

## iTerm settings

The `iterm` package (macOS only, not in `--server` mode) installs a Dynamic Profile named "Dotfiles": font, colors, Option keys, `xterm-256color` and unlimited scrollback.

One manual step per machine: iTerm Settings > Profiles > select "Dotfiles" > Other Actions > Set as Default.

Dynamic Profiles are read-only in the UI: change `iterm/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist` in the repo (iTerm reloads it on save).

iTerm re-reads Dynamic Profiles only when a file inside its folder changes; after pulling a change to the profile, restart iTerm (Cmd+Q) to apply it.

## Light and dark themes

The palette is TokyoNight Day (light) and Night (dark), the same colors in Ghostty, iTerm, tmux and Neovim. The default is `auto`: the terminal follows the macOS appearance and the `theme` script does nothing.

```sh
theme dark     # force dark (saved)
theme light    # force light (saved)
theme toggle   # flip; from auto, go to the opposite of macOS
theme auto     # reset to the terminal's own profile (follows macOS)
theme status   # print the saved state: dark, light or auto
tt             # alias for theme toggle
```

Shortcuts: `prefix t` in tmux, `<leader>ut` in Neovim.

**How it works.** `theme` saves the choice in `~/.local/state/theme` and sends OSC escape sequences that change the terminal's own palette, background, foreground and cursor (`auto` sends the OSC resets). Because the colors live in the terminal, not in each program, it works over SSH and in tmux: inside tmux the sequences are wrapped in DCS passthrough (`allow-passthrough on`), and `prefix t` writes straight to the client's tty. New local shells run `theme apply` when the saved state is dark or light (not over SSH). tmux uses palette color names, so its status line adapts. Neovim (tokyonight `night` and `day`) follows `background`, bat uses `BAT_THEME_DARK` / `BAT_THEME_LIGHT`, and delta uses `detect-dark-light`. Ghostty and iTerm switch with macOS on their own.

**Limits.**

- A new window flashes the terminal's default colors for a moment before the saved theme applies.
- A tmux inside a remote tmux is not wrapped twice, so toggling from there only reaches the inner tmux.
- Open Neovim instances update on `<leader>ut` or when they regain focus.

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
| `prefix t` | Toggle light/dark theme |
| `prefix r` | Reload `tmux.conf` |
| `prefix I` | Install TPM plugins |
| `prefix Ctrl+s` / `Ctrl+r` | Save / restore sessions (resurrect) |
| `prefix Ctrl+l` | Clear the screen |

vim-tmux-navigator takes `Ctrl+L` without prefix, so clear the screen with `prefix` then `Ctrl+L`.

### Shell

| Command | Action |
| --- | --- |
| `tt` | Toggle light/dark theme |
| `theme dark`, `light`, `auto` | Set the theme (auto follows macOS) |

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
| `<leader>ut` | Toggle light/dark theme |
| `Alt+j` / `Alt+k` | Move line or selection |
| `sa` / `sd` / `sr` | mini.surround: add, delete, replace |

Press `<leader>` and wait: which-key lists the options.

## Fonts

[Monaspace](https://monaspace.githubnext.com) (GitHub Next): **Neon** for code and **Radon** (handwriting style) for italics. It is installed as the Monaspice Nerd Font (Nerd Fonts renames Monaspace): by the Brewfile cask on macOS and by `install.sh` on a Linux desktop (into `~/.local/share/fonts`, not `--server`; needs `fc-cache`).

- **Ghostty**: `font-family = MonaspiceNe Nerd Font` and `font-family-italic = MonaspiceRn Nerd Font`.
- **Ghostty CLI**: on macOS the `ghostty` command comes from the app bundle and `.zshrc` adds it to `PATH`. Handy: `ghostty +list-fonts`, `ghostty +show-config`, `ghostty +list-themes`.
- **iTerm**: the "Dotfiles" profile uses `MonaspiceNeNF 14` (the PostScript name; find it with `mdls -name com_apple_ats_name_postscript <font file>` when switching fonts).
- **Switch fonts**: change `NERD_FONT` and `NERD_FONT_FAMILY` in `install.sh`, the cask in the `Brewfile`, `font-family` and `font-family-italic` in the Ghostty config, and `Normal Font` in the iTerm plist.

## Tools

- **neovim**: editor. **tmux**: sessions and panes. **stow**: symlinks the packages.
- **zsh-autosuggestions** / **zsh-syntax-highlighting** / **zsh-completions**: zsh plugins.
- **starship**: prompt. **fzf**: fuzzy search for history and files. **zoxide**: smart `cd`.
- **eza**: better `ls`. **bat**: better `cat`. **ripgrep** (`rg`): fast grep. **fd**: fast find.
- **jq** / **yq**: JSON / YAML processors. **btop**: system monitor. **tealdeer** (`tldr`): command examples. **hyperfine**: benchmarks.
- **git-delta**: diff pager. **lazygit** / **lazydocker**: terminal UIs. **dive**: Docker layer explorer. **gh**: GitHub CLI. **git-lfs**: large files in git.
- **mise**: per-project runtimes. **zig** / **zls**: Zig toolchain and language server.
- **shellcheck** / **shfmt** / **golangci-lint**: shell and Go linters/formatters. **tree-sitter-cli**: builds treesitter parsers.
- macOS only (casks): **ghostty** terminal and the **Monaspice Nerd Font** (Monaspace, for Ghostty and iTerm).
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
