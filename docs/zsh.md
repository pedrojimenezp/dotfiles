# zsh

The [shell](glossary.md#shell) config: `zsh/.zshrc`, linked to `~/.zshrc`. It is plain zsh with no framework, so the shell starts fast. Every line in the file has a comment.

You'll use it for: aliases, fuzzy history and Tab completion, jumping between folders, and a bell when a long command ends.

- [Quick start](#quick-start)
- [Aliases](#aliases)
- [Key bindings](#key-bindings)
- [Tab completion with fzf-tab](#tab-completion-with-fzf-tab)
- [History search with atuin](#history-search-with-atuin)
- [Jump to folders with zoxide](#jump-to-folders-with-zoxide)
- [Bell after long commands](#bell-after-long-commands)
- [Remote tmux: `tssh`](#remote-tmux-tssh)
- [Per-machine settings](#per-machine-settings-zshrclocal)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)

## Quick start

Open a new terminal, then try:

- `Ctrl+r` or `Up`: search your whole command history.
- `Tab`: pick a completion from a fuzzy list.
- `Right`: accept the grey suggestion shown while you type.
- `z dotfiles`: jump to a folder you visited before.
- `Ctrl+t`: pick a file and paste its path.
- `dotfiles-help`: list every alias and key (`prefix ?` inside tmux).

## What it sets up

- **Homebrew** (macOS): finds `brew` and adds it to `PATH`. Skipped where brew is absent.
- **PATH**: `~/.local/bin` first (the mise binary and the `theme` and `tmux-sessionizer` scripts), then `~/go/bin`. mise is activated right after, so its tools come before any Homebrew copy.

- **Editor**: `EDITOR` and `VISUAL` are `nvim` if installed, else `vim`. `PAGER` is `less`.
- **History**: 100000 entries in `~/.zsh_history`, shared between open shells, no duplicates. A command that starts with a space is not saved, which helps with secrets.
- **Options**:
  - `AUTO_CD`: type a folder name on its own, such as `projects`, and the shell enters it. No `cd` needed.
  - Comments are allowed at the prompt.
  - No terminal beep: the shell stays silent on errors like a failed completion. The long-command bell below is separate and on purpose.
  - Emacs key style: `Ctrl+a` goes to the start of the line, `Ctrl+e` to the end, `Ctrl+w` deletes a word. This is the zsh default. The other style is vi mode.
- **Completion**: case-insensitive matching, colored like `ls`, grouped with headers. With fzf-tab installed, Tab opens an fzf list.
- **Tools**: [fzf](glossary.md#fzf), [atuin](glossary.md#atuin), [zoxide](glossary.md#zoxide), [mise](glossary.md#mise) and [starship](glossary.md#starship) start only when installed. A missing tool never gives an error.
- **Plugins** (git clones in `~/.local/share/zsh-plugins`, made by `install.sh`): fzf-tab, autosuggestions, syntax highlighting and extra completions.
- **OS parts**: **macOS:** `o` is `open`, `ls -G`, and the Ghostty command is added to `PATH`. **Linux:** `o` is `xdg-open` and `ls --color=auto`.

## Aliases

Some aliases exist only if the tool is installed. `dotfiles-help` lists every alias, key and shell function with its description, see [Find any key](first-day.md#find-any-key). Keys of tools that bind their own (fzf, atuin, fzf-tab, zoxide, autosuggestions) are in [cheatsheet.tsv](cheatsheet.tsv).

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
| `Up` | With atuin: open the history search (all shells). Without atuin: commands that start with what you typed. | atuin / this config |
| `Down` | Commands that start with what you typed, going forward | This config |
| `Ctrl+r` | Fuzzy search the whole history | atuin (fzf if atuin is missing) |
| `Ctrl+t` | Fuzzy pick files and paste the path | fzf |
| `Alt+c` | Fuzzy pick a folder and `cd` into it | fzf |
| `Tab` | Fuzzy completion list (`Enter` accepts, `,` / `.` switch group) | fzf-tab |
| `**` then `Tab` | Fuzzy completion, for example `vim **<Tab>` | fzf |
| `Ctrl+x Ctrl+e` | Edit the current command line in `$VISUAL` (nvim if installed) | This config |
| `Ctrl+l` | Clear the screen **and** the [scrollback](glossary.md#scrollback) | This config |
| `Right` | Accept the grey suggestion (`End` also works) | zsh-autosuggestions |
| `Ctrl+a` / `Ctrl+e` | Start / end of line | Default (emacs style) |
| `Ctrl+w` / `Ctrl+u` | Delete the last word / the whole line before the cursor | Default (emacs style) |

Notes:

- **macOS:** `Alt` is the `Option` key. Ghostty and the iTerm profile make `Option` work as `Alt`, see [terminals.md](terminals.md).
- Inside tmux, `Ctrl+l` moves to the [pane](glossary.md#pane) on the right, unless the pane runs vim, nvim or fzf. To clear a tmux pane, press the [prefix](glossary.md#prefix) (`Ctrl+Space`), then `Ctrl+l`, or press `Cmd+K` in Ghostty or iTerm. See [tmux.md](tmux.md).
- To change a binding, edit the `bindkey` lines in `zsh/.zshrc`, then run `exec zsh`.

## Tab completion with fzf-tab

[fzf-tab](https://github.com/Aloxaf/fzf-tab) replaces the completion menu with an fzf list. Without it, Tab still works as a plain list.

- `cd <Tab>` previews the folder with `eza` (only if eza is installed).
- Group headers like `[file]` are on. Press `,` or `.` to jump between groups.
- Matching stays case-insensitive.

To open the list as a tmux [popup](glossary.md#popup) (needs tmux 3.2+), add this line to `~/.zshrc.local`. It is off by default.

```sh
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
```

## History search with atuin

[atuin](https://docs.atuin.sh/) stores every command, with folder, time and exit code, in a local SQLite database. It is local only: no account, no sync, no update checks.

`Up` and `Ctrl+r` open the same atuin list under the prompt. Both search the history of **all** shells, tabs and folders.

- Type letters: they match anywhere, in order.
- `Up` / `Down` (or `Ctrl+p` / `Ctrl+n`) move in the list. `Esc` or `Ctrl+c` cancels.
- `Enter` or `Tab` paste the command on the prompt. You press `Enter` again to run it, so nothing runs by surprise.
- `Ctrl+r` inside the list cycles the filter: global, host, session, workspace (current git repo), directory. Try `directory` to see only what you ran in this folder.

Without atuin installed, `Up` uses the prefix search and `Ctrl+r` uses fzf.

### Import your old history

`install.sh` runs `atuin import zsh` once, when the database does not exist yet and `~/.zsh_history` has content ([install.md](install.md#what-installsh-does-in-order)). To import again by hand, run it yourself. It may add duplicates.

```sh
atuin import zsh
```

### Keep `Up` as prefix search

1. Add `export ATUIN_NO_UP=1` to `~/.zshenv`. `~/.zshrc.local` is read too late for this.
2. Open a new shell.

Check it worked: `Up` now shows the previous command that starts with what you typed. `Ctrl+r` still opens atuin.

Undo: remove the line and open a new shell.

### Turn on sync

Sync is off by default. History is end-to-end encrypted.

1. Run `atuin register` (or `atuin login`).
2. Set `auto_sync = true` in `atuin/.config/atuin/config.toml`.
3. Run `atuin sync`.

## Jump to folders with zoxide

zoxide learns the folders you use. After a few visits:

```sh
z dotfiles               # jump to the most used folder that matches "dotfiles"
z proj api               # several words: all must match
zi                       # pick from the list with fzf
z dotfiles<Space><Tab>   # type "z", a word, Space, then Tab: pick a match with fzf
```

## Bell after long commands

When a command takes 30 seconds or more, the prompt rings the terminal bell. tmux then marks the window with a bell icon, so you can switch away while a build or test runs.

Commands that are long by nature never ring: editors, pagers, `ssh`, `tmux`, `claude`, `top` and similar. Change either setting in `~/.zshrc.local`:

```sh
export LONG_CMD_BELL_SECONDS=10
export LONG_CMD_BELL_IGNORE="nvim vim less man ssh"
```

The default ignore list is `nvim vim vi less man lazygit lg lzd tmux ssh tssh claude top btop htop fzf`. Open a new shell to apply the change.

## Remote tmux: `tssh`

```sh
tssh my-server          # any ssh arguments work: host alias, user@host, -i key, -p port
```

It runs `ssh -t` and starts (or attaches to) the tmux session named `main` on the server. Tab completion works like `ssh`. Rules and setup are in [server.md](server.md).

## Per-machine settings: `~/.zshrc.local`

`.zshrc` reads `~/.zshrc.local` if it exists. That file is **not** in the repo, and the global git ignore also skips it. Put here:

- secrets and API keys (`export TOKEN=...`)
- machine paths (`export PATH="$HOME/tools/bin:$PATH"`)
- aliases only for this machine
- the time zone on a server (`export TZ=America/Bogota`), see [server.md](server.md#set-the-time-zone)

```sh
# ~/.zshrc.local
export WORK_API_URL="https://example.invalid"
alias kprod='kubectl --context prod'
```

Open a new shell or run `exec zsh` to load it.

Two more optional files:

- `~/.config/claude-shared/zsh/claude.zsh` is read only if it exists (private Claude Code helpers). See [install.md](install.md).
- `~/.zshenv` is read before `.zshrc`. Use it for settings that must exist early, such as `ATUIN_NO_UP`.

## Troubleshooting

- **No icons in `ls`**: the terminal font is not a [Nerd Font](glossary.md#nerd-font), see [terminals.md](terminals.md).
- **Command not found for a tool**: open a new shell, then run `mise ls` to see if it is installed and `mise install` if not.
- **No autosuggestions or highlighting**: check that `~/.local/share/zsh-plugins/<name>` exists; `./install.sh` clones it.
- **A tool's init looks stale**: delete `~/.cache/zsh` and open a new shell.
- **Slow start**: run `time zsh -i -c exit`.

## How it works

**Load order.** `.zshrc` runs top to bottom, and the order matters:

1. Homebrew, `PATH`, mise, options and your key bindings.
2. The extra completions on `fpath`, `compinit` (the completion system), then fzf, atuin, zoxide and starship.
3. fzf-tab, after `compinit` and fzf, then autosuggestions. Both wrap widgets, so they come after the tools.
4. `claude.zsh`, then `~/.zshrc.local`.
5. Syntax highlighting, last. It must load after everything that defines widgets.

atuin loads after fzf so its `Ctrl+r` wins, and after the `Up` binding so its `Up` wins. `Down` stays with this config because atuin does not bind it.

**Tool init cache.** Starting each tool on every shell would cost about 30 ms each. `.zshrc` saves the output of `fzf --zsh`, `atuin init zsh`, `zoxide init zsh`, `mise activate zsh` and `starship init zsh` in `~/.cache/zsh`. A file refreshes when the tool is upgraded or `.zshrc` changes. Delete the folder to force a refresh.

**Completion cache.** `compinit -C` skips the security scan while the dump file is under 24 hours old. When it is older, a full `compinit` runs and the shell touches the dump, so the full scan happens once a day. If `compaudit` lists only paths owned by you or root, the scan runs `compinit -u` and does not prompt; a path owned by someone else still prompts (see [install.md](install.md#troubleshooting)). The config sets `menu no`, which fzf-tab requires.

**Bell hooks.** Two zsh hooks drive the bell. `preexec` records the start time and the program name. `precmd` runs before the next prompt: it rings `\a` if the command took `LONG_CMD_BELL_SECONDS` or more, stdout is a terminal and the program is not in `LONG_CMD_BELL_IGNORE`.

The program name is the first word of the line, after skipping:

- leading `VAR=value` assignments,
- the wrappers `sudo`, `command`, `env`, `nocorrect`, `noglob`, `time` and `nohup`,
- the options of those wrappers, such as `-E` or `-u USER`.

**Theme at start.** In a new local terminal, if you saved `dark` or `light`, `.zshrc` runs `theme apply`. It does nothing over SSH or inside tmux, so a server never changes your local colors. `bat` uses `BAT_THEME=ansi`, so it follows any terminal theme.

**Help list.** `dotfiles-help` reads `.zshrc` comments; a line without one is left out. The comment format is in [contributing.md](contributing.md#add-a-zsh-alias-key-or-function).

## Related

- [tmux.md](tmux.md): the bell icon, panes and the help popup.
- [terminals.md](terminals.md): fonts and the `Option` key.
- [tools.md](tools.md): the tools this config starts.
- [git.md](git.md): the git aliases.
- [server.md](server.md): `tssh` and working on a remote server.
