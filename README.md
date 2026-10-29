# dotfiles

Personal, cross-platform (macOS + Linux) shell and editor setup, managed with [GNU Stow](https://www.gnu.org/software/stow/). Every config line has a short comment, so the files double as a learning reference.

Each top-level folder is a **stow package**: its contents mirror `$HOME`. For example `git/.config/git/config` becomes `~/.config/git/config`.

## Quick start

### macOS

```sh
xcode-select --install   # Git and compilers, if you do not have them yet
git clone https://github.com/pedrojimenezp/dotfiles ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./install.sh             # brew bundle, back up old files, stow, clone TPM and its plugins, mise install, theme sync
```

macOS apps (casks) install into `~/Applications`, so no admin rights are needed. `install.sh` only installs what is missing and never upgrades: run `brew upgrade` yourself when you want updates.

Install [Homebrew](https://brew.sh) first if `brew` is missing (`install.sh` prints the command and stops).

### Linux

1. Install `git`, `curl`, `zsh` and build tools with your package manager (you run this).
2. Install Homebrew for Linux (no sudo needed after its prerequisites):
   `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`, then follow the "Next steps" it prints.
3. Clone this repo and run `./install.sh`.
4. Make zsh your login shell: `chsh -s "$(command -v zsh)"` (on Ubuntu, `sudo chsh -s /usr/bin/zsh "$USER"`), then log out and back in. The installer prints this command when needed.

### Ubuntu server

Full step-by-step guide, including the SSH setup on your Mac and daily use: [docs/server.md](docs/server.md).

A headless Ubuntu Server (for example an EC2 instance, 22.04 or 24.04) uses the full install. The Nerd Font step is skipped there (your local terminal renders the font). Run as a normal user with sudo; `install.sh` itself never uses sudo. The git config only rewrites GitHub pushes to SSH; fetches and clones stay on https, so a server without a GitHub key still installs everything except `--with-claude`.

```sh
# 1. Prerequisites (the only step that needs sudo)
sudo apt-get update && sudo apt-get install -y build-essential procps curl file git zsh

# 2. Homebrew (non-interactive) and its PATH
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 3. Clone and install (add --with-claude if you have GitHub SSH access)
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh

# 4. Make the system zsh the login shell (sudo: EC2 users have no password), then log out and back in
sudo chsh -s /usr/bin/zsh "$USER"

# 5. Claude Code (optional, native installer), then run `claude` to log in
curl -fsSL https://claude.ai/install.sh | bash
```

### After installing

1. tmux plugins are already installed; `Ctrl+Space`, then `Shift+i` retries if one failed.
2. Open `nvim` once and wait for lazy.nvim, Mason and treesitter to install everything.
3. Move secrets and machine settings into `~/.zshrc.local` (sourced last, not tracked).
4. Put machine-specific git settings in `~/.config/git/local`.

`install.sh` is idempotent. It stows with `--no-folding`, so every file is its own link and folders like `~/.config/ghostty` stay real (generated files never land in the repo). If `stow` is missing it falls back to plain symlinks. Existing real files are renamed to `<file>.backup-YYYYmmdd-HHMMSS`. `~/.gitconfig` is backed up too, because it takes precedence over `~/.config/git/config`.

```sh
./install.sh --dry-run   # show what would happen, change nothing
./install.sh --server    # no Homebrew: only zsh, tmux, vim, git, bin, theme
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
| `ghostty` | `~/.config/ghostty/config` | Ghostty terminal (optional; linked only if Ghostty is installed). Uses the Monaspice Nerd Font (Neon and Radon). Colors come from the generated `theme.conf` next to it. |
| `iterm` | `~/.config/iterm/dotfiles-profile.plist` | Template for the iTerm2 Dynamic Profile "Dotfiles" (macOS only): Monaspace Neon font, Option as Esc+. `theme sync` adds the colors and writes the real profile. |
| `mise` | `~/.config/mise/config.toml` | Global mise defaults: node (LTS) and go (latest), `.nvmrc` support. Zig stays in Homebrew. |
| `bin` | `~/.local/bin` | Scripts on PATH: `tmux-sessionizer`, `theme` (theme picker and light/dark switch). |
| `theme` | `~/.config/theme/config` | The light/dark theme pair (tracked), used by the terminals, tmux and Neovim. |

When Neovim is installed, the `vim` and `vi` aliases open `nvim`; `command vim` runs the real Vim.

### Server mode

`./install.sh --server` skips Homebrew and Ghostty, and stows only `zsh`, `tmux`, `vim`, `git`, `bin` and `theme`. The zsh config guards every tool, so it works with only the tools the server has. Over SSH, tmux (`set-clipboard on`) and nvim (OSC 52) copy to your local clipboard.

`tssh <ssh args>` (any host alias, `user@host`, `-i`, `-p`) connects and attaches to the remote tmux session `main`, creating it if needed. Use one terminal tab per server and run tmux only on the server, never tmux inside tmux. A tmux started from an SSH session shows a magenta status bar with the hostname, so it never looks like the local one.

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

The `iterm` package (macOS only, not in `--server` mode) installs a profile template, `~/.config/iterm/dotfiles-profile.plist`: font, Option keys, `xterm-256color` and unlimited scrollback, no colors. `theme sync` (run by `install.sh`, `theme set` and `theme pick`) adds the colors of the light/dark pair and writes a real file, `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.plist`, a Dynamic Profile named "Dotfiles" with separate light and dark colors.

One manual step per machine: iTerm Settings > Profiles > select "Dotfiles" > Other Actions > Set as Default. The profile keeps the same Guid, so this survives every sync.

Dynamic Profiles are read-only in the UI: change the template in the repo, then run `theme sync`. iTerm watches the DynamicProfiles folder and reloads the profile when `theme sync` rewrites it. Older installs linked that file into the repo; `install.sh` removes the old link. If iTerm ever misses a change, restart it (Cmd+Q).

## Light and dark themes

Two settings decide the colors:

- **The theme pair** (tracked): `~/.config/theme/config` names one theme for light mode and one for dark mode. It is part of the repo, so every machine gets the same pair.
- **The mode** (per machine): `auto`, `light` or `dark`, saved in `~/.local/state/theme`. In `auto` the terminal follows the macOS appearance.

```
# ~/.config/theme/config
light = GitHub Light Default
dark = TokyoNight Night
```

Theme names come from Ghostty's collection (several hundred themes, the [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) project). The `theme` script looks a name up in this order: its own cache (`~/.local/share/theme/themes`), the themes bundled with Ghostty (the macOS app, or `/usr/share/ghostty/themes` on Linux), then downloads it from GitHub into the cache. So servers without Ghostty work too, with `curl`.

```sh
theme pick             # choose the theme for the current mode with fzf (live preview)
theme pick dark        # choose the dark theme, even while in light mode
theme set light "Flexoki Light"  # same without fzf
theme list             # every theme name
theme file "Nord"      # path of a theme file (downloads it if needed)
theme sync             # regenerate the Ghostty and iTerm files from the pair
theme dark             # force dark (saved)
theme light            # force light (saved)
theme toggle           # flip; from auto, go to the opposite of macOS
theme auto             # back to the terminal's own profile (follows macOS)
theme status           # print the mode and the light/dark picks (* marks the one in use)
tt                     # alias for theme toggle
```

Shortcuts: `prefix t` in tmux and `<leader>ut` in Neovim toggle the mode.

**Picking a theme.** `theme pick` opens fzf over `theme list`. Moving through the list recolors the terminal right away, and the preview pane shows the 16 colors and some sample code. Enter saves the name in `~/.config/theme/config`, runs `theme sync` and applies the current mode. Esc puts the previous colors back. Without fzf, use `theme set`. The config file is a link into the repo, so a pick changes a tracked file: **commit it** to keep the choice on every machine.

**How each tool follows.**

- **Terminal (any, also over SSH)**: `theme dark`/`light` send OSC escape sequences that set the terminal's palette, background, foreground and cursor from the theme file (`auto` sends the resets). Inside tmux they are wrapped in DCS passthrough (`allow-passthrough on`); `prefix t` writes straight to the client's tty. New local shells run `theme apply` when the mode is dark or light (not over SSH).
- **Ghostty**: the tracked config includes `config-file = ?theme.conf`; `theme sync` writes `~/.config/ghostty/theme.conf` with `theme = light:<light>,dark:<dark>`, so Ghostty switches with macOS by itself. Downloaded themes are copied to `~/.config/ghostty/themes` (colors only). `theme sync` sends Ghostty `SIGUSR2` to reload; if a window keeps the old colors, reload with `Cmd+Shift+,` (or `Cmd+Shift+R` from this config).
- **iTerm**: `theme sync` writes the "Dotfiles" Dynamic Profile with light and dark colors (see [iTerm settings](#iterm-settings)); iTerm reloads it by itself.
- **tmux**: the status line uses palette color names, so it follows the terminal.
- **Neovim**: `background` picks the slot, the slot's name picks the colorscheme: `TokyoNight …` uses tokyonight.nvim, `GitHub …` uses github-nvim-theme, and any other theme is built with `mini.base16` from the theme file. Open instances update on `<leader>ut` and when they regain focus (so a `theme pick` in the shell shows up when you return).
- **bat and delta**: both use the `ansi` theme, which draws with the terminal's 16 colors, so they match any theme. delta still uses `detect-dark-light` for its diff backgrounds.

**Limits.**

- A new window flashes the terminal's default colors for a moment before the saved mode applies.
- A tmux inside a remote tmux is not wrapped twice, so toggling from there only reaches the inner tmux.
- `theme list` without Ghostty uses the GitHub contents API (cached for a day), which returns at most 1000 names.
- Downloaded themes are not updated; delete `~/.local/share/theme/themes/<name>` to fetch one again.
- Neovim's base16 fallback is an approximation of the terminal theme, not a hand-made colorscheme.

## Key cheat sheet

### tmux (prefix: `Ctrl+Space`)

| Keys | Action |
| --- | --- |
| `prefix \|` / `prefix -` | Split left/right, top/bottom (current path) |
| `prefix c` | New window (current path) |
| `prefix H/J/K/L` | Resize pane (repeatable) |
| `Ctrl+h/j/k/l` | Move between panes and nvim splits (no prefix) |
| `prefix [` then `v`, `y` | Copy mode: select, copy (also to the system clipboard) |
| `prefix f` | Project session picker (fzf over `~/projects`, else `$HOME` two levels deep, or `$SESSIONIZER_DIRS`); git worktrees are listed first as `branch  [repo]` and open a session named after the branch |
| `prefix t` | Toggle light/dark mode |
| `prefix X` | Kill the current session (asks first); tmux switches to another session and exits only when none are left |
| `prefix r` | Reload `tmux.conf` |
| `prefix I` | Install TPM plugins |
| `prefix Ctrl+s` / `Ctrl+r` | Save / restore sessions (resurrect); continuum also saves every 15 minutes and restores on tmux start, so sessions survive `tmux kill-server` and reboots (panes running `ssh` re-run it) |
| `prefix Ctrl+l` | Clear the screen |

vim-tmux-navigator takes `Ctrl+L` without prefix, so clear the screen with `prefix` then `Ctrl+L`.

### Shell

| Command | Action |
| --- | --- |
| `tt` | Toggle light/dark mode |
| `theme dark`, `light`, `auto` | Set the mode (auto follows macOS) |
| `theme pick` | Choose the theme for the current mode (fzf, live preview) |
| `theme set light NAME` | Save a theme without fzf (`dark` for the dark slot) |
| `theme list` | List every theme name |

### Neovim (leader: `Space`)

`<leader>` is the Space key. Press the keys one after another, not together: `<leader>ut` means Space, then `u`, then `t`. After you press Space, the which-key menu appears and lists the next keys. The menu waits for you; `timeoutlen` (0.4 s) only limits key sequences that have no menu.

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
| `<leader>ut` | Toggle light/dark mode (terminal and Neovim) |
| `Alt+j` / `Alt+k` | Move line or selection |
| `sa` / `sd` / `sr` | mini.surround: add, delete, replace |

Press Space and wait: which-key lists the options.

## Fonts

[Monaspace](https://monaspace.githubnext.com) (GitHub Next): **Neon** for code and **Radon** (handwriting style) for italics. It is installed as the Monaspice Nerd Font (Nerd Fonts renames Monaspace): by the Brewfile cask on macOS and by `install.sh` on a Linux desktop (into `~/.local/share/fonts`, not `--server`; needs `fc-cache`).

- **Ghostty**: `font-family = MonaspiceNe Nerd Font` and `font-family-italic = MonaspiceRn Nerd Font`.
- **Ghostty CLI**: on macOS the `ghostty` command comes from the app bundle and `.zshrc` adds it to `PATH`. Handy: `ghostty +list-fonts`, `ghostty +show-config`, `ghostty +list-themes`.
- **iTerm**: the "Dotfiles" profile uses `MonaspiceNeNF 14` (the PostScript name; find it with `mdls -name com_apple_ats_name_postscript <font file>` when switching fonts).
- **Switch fonts**: change `NERD_FONT` and `NERD_FONT_FAMILY` in `install.sh`, the cask in the `Brewfile`, `font-family` and `font-family-italic` in the Ghostty config, and `Normal Font` in the iTerm template (`iterm/.config/iterm/dotfiles-profile.plist`).

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
