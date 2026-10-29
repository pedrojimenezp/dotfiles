# zsh

File: `zsh/.zshrc`, linked to `~/.zshrc`. It is plain zsh with no framework, so the shell starts fast. Every line in the file has a comment.

## What it sets up

- **Homebrew**: finds `brew` (macOS Apple Silicon or Intel, or Linux) and adds it to `PATH`.
- **PATH**: `~/.local/bin` first (the `theme` and `tmux-sessionizer` scripts), then `~/go/bin`.
- **Editor**: `EDITOR` and `VISUAL` are `nvim` if installed, else `vim`. `PAGER` is `less`.
- **History**: 100000 entries in `~/.zsh_history`, shared between open shells, no duplicates. A command that starts with a space is not saved (handy for secrets).
- **Bell**: rings after commands that run 30 seconds or more (see below).
- **Options**: `AUTO_CD` (type a folder name to enter it), comments allowed at the prompt, no bell, emacs key style.
- **Completion**: case-insensitive matching, colored like `ls`, grouped with headers. With fzf-tab installed, Tab opens an fzf list (see below).
- **Tools**: fzf, zoxide, mise and starship are started only when installed. A missing tool never gives an error.
- **Plugins** (from Homebrew): fzf-tab, autosuggestions and syntax highlighting.
- **OS parts**: macOS (`o` = `open`, `ls -G`, Ghostty command added to `PATH`) and Linux (`o` = `xdg-open`, `ls --color=auto`).

## Aliases

Some aliases exist only if the tool is installed.

| Alias | Runs | Notes |
| --- | --- | --- |
| `vim`, `vi` | `nvim` | Only where Neovim exists. Use `command vim` for the real Vim. |
| `ls` | `eza --icons --group-directories-first` | Needs eza. Without it, plain `ls` with colors. |
| `ll` | `eza -l ... --git` | Long list with git status. Without eza: `ls -lh`. |
| `la` | `eza -la ... --git` | Also hidden files. Without eza: `ls -lah`. |
| `lt` | `eza --tree --level=2` | Tree, two levels. Needs eza. |
| `cat` | `bat --paging=never` | Highlighted output. Needs bat. Use `command cat` for the real one. |
| `lg` | `lazygit` | Git UI. (Git has its own alias `git lg`, see [git.md](git.md).) |
| `lzd` | `lazydocker` | Docker UI. |
| `dcu` | `docker compose up` | Needs docker. |
| `dcd` | `docker compose down` | Needs docker. |
| `..` | `cd ..` | Go up one folder. |
| `gs` | `git status -sb` | Short status. |
| `gd` | `git diff` | Unstaged changes. |
| `gl` | `git log --oneline --graph -20` | Last 20 commits as a graph. |
| `gp` | `git pull` | Rebases, because of the git config. |
| `o` | `open` (macOS) / `xdg-open` (Linux) | Open a file or URL with the default app. |
| `tt` | `theme toggle` | Light/dark switch, see [theme.md](theme.md). |

Run `alias` to list what is active on this machine.

## Key bindings

| Keys | What it does | Source |
| --- | --- | --- |
| `Up` / `Down` | Search history for commands that start with what you typed. Empty line: walk the history. | This config |
| `Ctrl+R` | Fuzzy search the whole history | fzf |
| `Ctrl+T` | Fuzzy pick files and paste the path | fzf |
| `Alt+C` | Fuzzy pick a folder and `cd` into it | fzf |
| `Tab` | Fuzzy completion list (`Enter` accepts, `,` / `.` switch group) | fzf-tab |
| `**` then `Tab` | Fuzzy completion, for example `vim **<Tab>` | fzf |
| `Ctrl+X` `Ctrl+E` | Edit the current command line in `$VISUAL` (nvim if installed) | This config |
| `Ctrl+L` | Clear the screen **and** the scrollback | This config |
| `Right arrow` | Accept the grey suggestion | Default of zsh-autosuggestions (`End` also works) |
| `Ctrl+A` / `Ctrl+E` | Start / end of line | Default (emacs style) |
| `Ctrl+W` / `Ctrl+U` | Delete the last word / the whole line before the cursor | Default (emacs style) |

Notes:

- On macOS, `Alt` is the `Option` key. Ghostty and the iTerm profile are set so `Option` works as `Alt`, see [terminals.md](terminals.md).
- Inside tmux, `Ctrl+L` (no prefix) moves to the pane on the right, unless the pane runs vim, nvim or fzf (vim-tmux-navigator). To clear a tmux pane, press `Ctrl+Space`, then `Ctrl+L` (or `Cmd+K` in Ghostty/iTerm). See [tmux.md](tmux.md). Outside tmux, `Ctrl+L` clears.
- To change a binding, edit the `bindkey` lines in `zsh/.zshrc`, then run `exec zsh`.

## Tab completion with fzf-tab

[fzf-tab](https://github.com/Aloxaf/fzf-tab) replaces the completion menu with fzf. It comes from the Brewfile (`brew "fzf-tab"`), and `.zshrc` sources it from `$HOMEBREW_PREFIX/opt/fzf-tab` only if the file exists. Without it Tab still works, but as a plain list: the config sets `menu no`, which fzf-tab requires. On a `--server` machine (no Homebrew) the plugin is not installed.

- Load order: after `compinit` and fzf, before autosuggestions and syntax highlighting (they wrap widgets).
- `cd <Tab>` previews the folder with `eza` (only if eza is installed).
- Group headers like `[file]` are on. Press `,` or `.` to jump between groups.
- Matching stays case-insensitive.
- Optional: inside tmux, add `zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup` to `~/.zshrc.local` to open the list as a tmux popup (needs tmux 3.2+). Not enabled by default.

## Jump to folders with zoxide

zoxide learns the folders you use. After a few visits:

```sh
z dotfiles        # jump to the most used folder that matches "dotfiles"
z proj api        # several words: all must match
zi                # pick from the list with fzf
z dotfiles<Space><Tab>   # type "z", a word, Space, then Tab: pick a match with fzf
```

`z` and `zi` are added by `zoxide init zsh` (default commands of zoxide). Space+Tab is zoxide's own completion and needs fzf.

## Bell after long commands

When a command takes `LONG_CMD_BELL_SECONDS` or more (default 30) and stdout is a terminal, the prompt rings the bell (`\a`). tmux's `monitor-bell` then marks the window with a bell icon, so you can switch away while a build or test runs. Commands that are long by nature are skipped: the list is `LONG_CMD_BELL_IGNORE` (default: `nvim vim vi less man lazygit lg lzd tmux ssh tssh claude top btop htop fzf`, matched on the first word). Change either in `~/.zshrc.local`:

```sh
export LONG_CMD_BELL_SECONDS=10
export LONG_CMD_BELL_IGNORE="nvim vim less man ssh"
```

## Remote tmux: `tssh`

```sh
tssh my-server          # any ssh arguments work: host alias, user@host, -i key, -p port
```

It runs `ssh -t` and starts (or attaches to) the tmux session named `main` on the server. Tab completion works like `ssh`. Rules and setup are in [server.md](server.md).

## Light/dark theme at start

In a new local terminal, if you saved `dark` or `light`, `.zshrc` runs `theme apply`. It does nothing over SSH, so a server never changes your local colors. `bat` uses `BAT_THEME=ansi`, so it follows any terminal theme.

## Per-machine settings: `~/.zshrc.local`

The last line of `.zshrc` sources `~/.zshrc.local` if it exists. That file is **not** in the repo (it is also in the global git ignore). Put here:

- secrets and API keys (`export TOKEN=...`)
- machine paths (`export PATH="$HOME/tools/bin:$PATH"`)
- aliases only for this machine

Example:

```sh
# ~/.zshrc.local
export WORK_API_URL="https://example.invalid"
alias kprod='kubectl --context prod'
```

Open a new shell or run `exec zsh` to load it.

## Optional extras

- `~/.config/claude-shared/zsh/claude.zsh` is sourced only if it exists (private Claude Code helpers). See [install.md](install.md).

## Troubleshooting

- **No icons in `ls`**: the terminal font is not a Nerd Font, see [terminals.md](terminals.md).
- **Command not found for a Homebrew tool**: open a new shell. On Linux check that `/home/linuxbrew/.linuxbrew/bin/brew` exists.
- **Slow start**: run `time zsh -i -c exit`. The config avoids slow steps (`compinit -C`).
