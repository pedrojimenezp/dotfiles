# Your first day

A short tour of the keys and commands you'll use most, how to find the rest, and what to do when something breaks. Read it after [install.md](install.md).

## Two keys to learn first

- **`prefix`** is `Ctrl+Space`. Press it, release it, then press the next key. `prefix c` means `Ctrl+Space`, then `c`. It is the [prefix](glossary.md#prefix) for every tmux key.
- **`<leader>`** is `Space` in Neovim. `<leader>sf` means `Space`, then `s`, then `f`. See [leader](glossary.md#leader).

## Find any key

You don't need to memorize anything on this page:

- In tmux, press `prefix ?`. A searchable list of every key, alias and command opens in a [popup](glossary.md#popup) (a floating box). Type to filter, `Esc` closes.
- Outside tmux, run `dotfiles-help`. It shows the same list.
- In Neovim, press `Space` and wait. which-key lists every leader key.
- tmux's own default keys are on `prefix k`.

## tmux: sessions, windows and panes

Start tmux with `tmux` in your terminal.

| Key | What it does |
| --- | --- |
| `prefix c` | New [window](glossary.md#window) (a tab inside tmux) |
| `prefix \|` / `prefix -` | Split into side-by-side / stacked [panes](glossary.md#pane) |
| `Ctrl+h/j/k/l` | Move between panes and Neovim splits, no prefix |
| `prefix f` | Pick a project folder and open a [session](glossary.md#session) for it |
| `prefix d` | Detach: leave tmux, everything keeps running. Run `tmux attach` to come back |

More in [tmux.md](tmux.md).

## zsh: the shell

| Key or command | What it does |
| --- | --- |
| `Up` or `Ctrl+R` | Search your command history ([atuin](glossary.md#atuin)) |
| `Ctrl+T` | Pick a file with [fzf](glossary.md#fzf) and paste its path |
| `z name` | Jump to a folder you visit often ([zoxide](glossary.md#zoxide)) |
| `Tab` | Completion list you can filter by typing |
| `Right` | Accept the grey suggestion |

More in [zsh.md](zsh.md).

## Neovim: the editor

Open it with `nvim` (or `vim`, which opens Neovim too).

| Key | What it does |
| --- | --- |
| `<leader>sf` | Search files by name |
| `<leader>sg` | Search text in all files |
| `-` | Browse the folder of the current file |
| `jk` | Leave insert mode (same as `Esc`) |
| `<leader>w` / `<leader>q` | Save / close the window |

More in [nvim.md](nvim.md).

## If something breaks

- **The shell acts strange after a change.** Open a fresh one:
  ```sh
  exec zsh
  ```
- **The shell still acts strange.** zsh caches the setup of its tools in `~/.cache/zsh`. Delete the cache and it rebuilds on the next start:
  ```sh
  rm -rf ~/.cache/zsh && exec zsh
  ```
- **tmux ignores your edit to `tmux.conf`.** Reload it with `prefix r`.
- **A tmux plugin is missing.** Press `prefix Shift+I` to install the plugins again. More in [tmux troubleshooting](tmux.md#troubleshooting).
- **Neovim shows errors on start.** Run `:Lazy` to check plugins, `:Mason` to check language tools, and `:checkhealth` for a full report. More in [nvim troubleshooting](nvim.md#troubleshooting).
- **Icons show as boxes or question marks.** Your terminal font is not a [Nerd Font](glossary.md#nerd-font). See [terminals.md](terminals.md).
- **You want an old config file back.** The installer renamed it to `<file>.backup-<date>-<time>` next to the original. See [Restore one file](install.md#restore-one-file).
- **The install itself failed.** See [install troubleshooting](install.md#troubleshooting). Your machine-only settings live in the [per-machine files](install.md#per-machine-files).

## Related pages

- [install.md](install.md): install, update and undo.
- [tmux.md](tmux.md), [zsh.md](zsh.md), [nvim.md](nvim.md): every key, by tool.
- [glossary.md](glossary.md): the terms these docs use.
