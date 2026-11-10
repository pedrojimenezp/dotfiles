# zsh

Config: `zsh/.zshrc`, plain zsh with no framework. Aliases, keys and functions: `dotfiles-help` (from the `.zshrc` comments) or `alias`. Aliases for a missing tool aren't defined; `command vim` / `command cat` reach the real ones.

`tt` (theme toggle) and `lg` (lazygit) are the shell versions of tmux `prefix t` and `prefix G`, for use outside tmux (for example, over SSH in a Ghostty split).

## Per-machine settings

`~/.zshrc.local` loads near the end, untracked and globally git-ignored: secrets, machine paths and aliases, `TZ` and `HOST_LABEL` on a server. `~/.zshenv` loads before `.zshrc`, for things needed early (`PATH`, `HISTFILE`). `~/.config/claude-shared/claude.sh` loads only if present.

Optional settings:

```sh
export LONG_CMD_BELL_SECONDS=10                      # default 30
export LONG_CMD_BELL_IGNORE="nvim vim less man ssh"  # replaces the default list
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup       # fzf-tab list as a tmux popup
```

## Completions for mise tools

mise tools bring no zsh completions. Load the ones you use in `~/.zshrc.local` (it runs after `compinit`); each costs one tool run per shell start:

```sh
(( $+commands[gh] )) && source <(gh completion -s zsh)
```

## Bell after long commands

A command of 30 s or more rings the bell, so tmux marks the window. Interactive programs (editors, pagers, `ssh`, `tmux`, `claude`, `top`) never ring. The program name is the first word after `VAR=value` prefixes and wrappers (`sudo`, `env`, `time`, `nohup`, ...) and their options. It rings only when stdout is a terminal.

## `tssh`

`tssh <ssh args>` runs `ssh -t` and attaches to (or creates) the tmux session `main` on the server. tmux is the connection's only command, so detaching ends the connection. See [server.md](server.md#3-daily-use).

## `Ctrl+l`

Outside tmux it clears the screen and the scrollback. Inside tmux it moves to the right pane (vim-tmux-navigator); use `prefix Ctrl+l` or `Cmd+K` to clear.

## Load order

The order in `.zshrc` matters:

1. Homebrew, `PATH` (`~/.local/bin` first), mise, options, key bindings. mise comes early so its tools beat Homebrew copies.
2. Extra completions on `fpath`, `compinit`, then fzf, zoxide, starship.
3. fzf-tab (after `compinit` and fzf), then autosuggestions: both wrap widgets.
4. `claude.sh`, then `~/.zshrc.local`.
5. Syntax highlighting, last: it must see every widget.

## Caches

- **Tool init.** `fzf --zsh`, `zoxide init zsh` and `starship init zsh` are cached in `~/.cache/zsh` (about 30 ms each otherwise). Each file's first line records the tool's resolved path (with its mise version), so it refreshes on an upgrade, a newer binary or a changed `.zshrc`. `mise activate` isn't cached: its PATH snapshot would overwrite earlier entries.
- **compinit.** `compinit -C` skips the security scan while the dump is under 24 h old, then a full scan runs once. If `compaudit` lists only paths owned by you or root, it runs `compinit -u` without prompting.
- **History** uses `HIST_FCNTL_LOCK`, so a new shell never waits on a stale `.zsh_history.LOCK`. A command starting with a space isn't saved.

## Theme at start

In a new local, non-tmux shell with a saved `dark` or `light`, `.zshrc` runs `theme apply`. Over SSH or in tmux it does nothing, so a server never changes local colors. `BAT_THEME=ansi` follows any terminal theme.

## Troubleshooting

- **A tool's init looks stale** (after adding, removing or moving a tool): `rm -rf ~/.cache/zsh && exec zsh`.
- **Command not found:** `mise ls`, then `mise install`.
- **No autosuggestions or highlighting:** check `~/.local/share/zsh-plugins/<name>`; `./install.sh` clones it.
- **Slow start:** `time zsh -i -c exit`.
- **`compinit: insecure directories`:** see [install.md](install.md#troubleshooting).
