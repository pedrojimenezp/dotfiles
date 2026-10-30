# dotfiles

Personal, cross-platform (macOS + Linux) shell and editor setup, managed with [GNU Stow](https://www.gnu.org/software/stow/). Every config line has a short comment, and every part has a doc in [docs/](docs/), so the repo is also a learning reference.

## Help

Forgot a key? Press `prefix ?` (`Ctrl+Space`, then `?`) in tmux, or run `dotfiles-help` in a shell. It opens a searchable list of the tmux keys of this config, zsh aliases, keys and functions, scripts and plugin keys (like which-key in Neovim); tmux's own defaults are on `prefix k`. `dotfiles-help --list` prints the same list as a table.

The list is read from the configs themselves, so adding something means describing it where it is defined:

- tmux key: `bind -N "short description" ...` in `tmux.conf`.
- zsh alias or key: an end-of-line comment on the `alias` or `bindkey` line in `.zshrc`; a shell function: a comment line above it.
- script in `bin/.local/bin`: a one-line description on line 2 and `# Usage:` lines.
- Only keys no config states (plugin, tool and terminal keys) go in [docs/cheatsheet.tsv](docs/cheatsheet.tsv).

Each top-level folder is a **stow package**: its contents mirror `$HOME`. For example `git/.config/git/config` becomes `~/.config/git/config`.

## Install

### macOS

```sh
xcode-select --install   # Git and compilers, if you do not have them yet
git clone https://github.com/pedrojimenezp/dotfiles ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./install.sh             # brew bundle, back up old files, stow, TPM, mise install, theme sync
```

Install [Homebrew](https://brew.sh) first if `brew` is missing (`install.sh` prints the command and stops). Apps install into `~/Applications`, so no admin rights are needed. `install.sh` never upgrades anything and never uses sudo.

### Linux desktop

Install `git`, `curl`, `zsh` and build tools, then Homebrew for Linux, clone this repo and run `./install.sh`. Finally make zsh your login shell. Full steps: [docs/install.md](docs/install.md#linux-desktop).

### Ubuntu server

Step-by-step guide with SSH setup and daily use: [docs/server.md](docs/server.md). Short commands: [docs/install.md](docs/install.md#ubuntu-server).

### Flags and details

```sh
./install.sh --dry-run      # show what would happen, change nothing
./install.sh --with-claude <git-url>  # optional: also clone and install your own Claude config repo
```

What each step does, backups, idempotency and troubleshooting: [docs/install.md](docs/install.md).

### After installing

1. Start a new shell (`exec zsh`).
2. tmux plugins are installed already; `Ctrl+Space`, then `Shift+i` retries if one failed.
3. Open `nvim` once and wait for lazy.nvim, Mason and treesitter to install everything.
4. Put secrets and machine settings in `~/.zshrc.local` (loaded near the end, after all other settings; not tracked).
5. Set your git name and email in `~/.config/git/local` (the installer asks for them), plus any other machine-specific git settings.

## Docs

| Doc | What is in it |
| --- | --- |
| [docs/install.md](docs/install.md) | Install on each OS, flags, what each step does, backups, troubleshooting |
| [docs/server.md](docs/server.md) | Remote Ubuntu server over SSH, `tssh`, GitHub key forwarding |
| [docs/zsh.md](docs/zsh.md) | Aliases, key bindings, fzf, zoxide, history, `~/.zshrc.local` |
| [docs/tmux.md](docs/tmux.md) | Prefix, every custom key, status bar, panes, resurrect and continuum, plugins |
| [docs/tmux-sessionizer.md](docs/tmux-sessionizer.md) | The project session picker (`prefix f`) |
| [docs/nvim.md](docs/nvim.md) | Neovim keymaps, plugins, LSP, how to add a plugin or a language server |
| [docs/vim.md](docs/vim.md) | The small plugin-free `.vimrc` for servers |
| [docs/git.md](docs/git.md) | Git settings and why, aliases, `~/.config/git/local`, global ignore list |
| [docs/theme.md](docs/theme.md) | The `theme` command, light/dark, how each tool follows |
| [docs/terminals.md](docs/terminals.md) | Ghostty, iTerm2, font, keybinds, SSH config tips |
| [docs/tools.md](docs/tools.md) | Every Brewfile tool with an example, starship, mise |

## Packages

| Package | Links to | What it does |
| --- | --- | --- |
| `zsh` | `~/.zshrc` | Plain zsh: history, completion, aliases, fzf, atuin, zoxide, mise, starship, autosuggestions, syntax highlighting. Sources `~/.zshrc.local` near the end (only syntax highlighting loads after it). |
| `nvim` | `~/.config/nvim` | Neovim config (lazy.nvim, LSP, treesitter, telescope, conform, blink.cmp). |
| `tmux` | `~/.config/tmux/tmux.conf` | tmux with prefix `Ctrl+Space`, vi copy mode, TPM plugins, minimal status line that follows the terminal palette, with SSH badge, prefix, bell, zoom and git branch indicators. |
| `vim` | `~/.vimrc` | Small plugin-free vimrc for servers. |
| `git` | `~/.config/git/{config,ignore}` | Git defaults, delta pager, aliases, global ignores, `local` include. |
| `lazygit` | `~/.config/lazygit/config.yml` | lazygit renders diffs with delta (`\|` cycles side by side and inline). `.zshrc` sets `LG_CONFIG_FILE` so macOS reads it too. |
| `starship` | `~/.config/starship.toml` | Two-line framed prompt. |
| `atuin` | `~/.config/atuin/config.toml` | Shell history search on `Up` and `Ctrl+R`, local only (no sync). |
| `ghostty` | `~/.config/ghostty/config` | Ghostty terminal (optional; linked only if Ghostty is installed). Colors come from the generated `theme.conf` next to it. |
| `iterm` | `~/.config/iterm/dotfiles-profile.plist` | Template for the iTerm2 Dynamic Profile "Dotfiles" (macOS only). `theme sync` adds the colors. |
| `mise` | `~/.config/mise/config.toml` | Global mise defaults: node (LTS) and go (latest), `.nvmrc` support. |
| `bin` | `~/.local/bin` | Scripts on PATH: `tmux-sessionizer`, `tmux-popup`, `theme`, `dotfiles-help`, `dotfiles-usage`, `dotfiles-log`. |
| `theme` | `~/.config/theme/config` | The light/dark theme pair (tracked), used by the terminals, tmux and Neovim. |

## Cheat sheet

The full, searchable list is `prefix ?` or `dotfiles-help` (see [Help](#help)); this is a short selection. Details are in the docs above. `prefix` is `Ctrl+Space`. In Neovim, `<leader>` is `Space`.

### Shell

| Keys / command | Action |
| --- | --- |
| `Up` | atuin history search, all shells (`Esc` cancels, `Enter` pastes) |
| `Down` | History that starts with what you typed |
| `Ctrl+R` | atuin history search (same list; `Ctrl+R` again cycles filter) |
| `Ctrl+T` / `Alt+C` | fzf: file path / change folder |
| `Tab` | Fuzzy completion list (fzf-tab) |
| `Ctrl+X` `Ctrl+E` | Edit the command line in nvim |
| `Ctrl+L` | Clear screen and scrollback |
| `z name`, `zi` | Jump to a frequent folder (zoxide) |
| `Right arrow` | Accept the grey suggestion |
| long command ends | Bell (30 s or more); tmux flags the window |
| `tssh host` | SSH and attach to remote tmux session `main` |
| `tt` | Toggle light/dark |
| `lg`, `lzd` | lazygit, lazydocker |
| `ll`, `la`, `lt` | eza: long, with hidden, tree |
| `theme pick` | Choose a theme with live preview |
| `dotfiles-help` | Search every shortcut (fzf) |
| `dotfiles-usage [week\|2weeks\|month]` | Uses per tool, to find what to remove ([docs](docs/tools.md#usage-report-dotfiles-usage)) |

### tmux

| Keys | Action |
| --- | --- |
| `prefix ?` | Search every shortcut (this list and more) |
| `prefix k` | tmux's own key list (the old `prefix ?`) |
| `prefix \|` / `prefix -` | Split left/right, top/bottom (current path) |
| `prefix c` | New window (current path) |
| `prefix H/J/K/L` | Resize pane (repeatable) |
| `Ctrl+h/j/k/l` | Move between panes and nvim splits (no prefix) |
| `prefix [` then `v`, `y` | Copy mode: select, copy |
| `prefix f` | Project session picker |
| `prefix t` | Toggle light/dark |
| `prefix G` | lazygit popup (pane's folder) |
| `` prefix ` `` / `prefix A` | Toggle a persistent shell / Claude Code popup (same key or `prefix d` closes) |
| `prefix Space` | Copy with hints: press a letter to copy a URL, path or hash (replaces `next-layout`) |
| `prefix s` | Pick a session (popup sessions hidden) |
| `prefix N` | New session by name; the folder is picked with fzf (this pane's, zoxide's, projects, or any typed path) |
| `prefix X` | Kill the current session (asks first) |
| `prefix d` | Detach (default) |
| `prefix r` | Reload `tmux.conf` |
| `prefix I` | Install TPM plugins |
| `prefix Ctrl+s` / `Ctrl+r` | Save / restore sessions (also automatic every 15 minutes) |
| `Cmd+K` | Clear the pane (macOS terminals) |

### Neovim

| Keys | Action |
| --- | --- |
| `jk` | Leave insert mode |
| `<leader>w` / `q` | Save / quit window |
| `<leader>sf` / `sg` / `sw` | Search files / grep / word under cursor |
| `<leader><leader>` / `s.` | Open buffers / recent files |
| `-` | Open parent folder (oil) |
| `gd` / `grr` / `gri` | Definition / references / implementation |
| `K` / `grn` / `gra` | Hover / rename / code action |
| `<leader>f` | Format buffer (also on save) |
| `]c` / `[c`, `<leader>hs` | Next / previous git hunk, stage hunk |
| `<leader>ut` | Toggle light/dark |
| `Alt+j` / `Alt+k` | Move line or selection |

Press `Space` and wait: which-key lists the options.

## License

See [LICENSE](LICENSE).
