# Vim (servers)

A small Vim config **without plugins**: `vim/.vimrc`, linked to `~/.vimrc`. It is for machines where Neovim is not installed, such as a server.

You'll use it for: basic editing on a server with the same few keys as [nvim.md](nvim.md).

On a machine with Neovim, the `vim` and `vi` aliases open `nvim`. Use `command vim` to run the real Vim.

## Quick start

1. Press `i` to type text. Press `jk` to go back to normal mode.
2. Press `<leader>w` (`Space` then `w`) to save.
3. Press `<leader>q` (`Space` then `q`) to quit.

The [leader](glossary.md#leader) key is `Space`. Press the keys one after another.

## Keys

| Keys | Mode | What it does |
| --- | --- | --- |
| `jk` | insert | Leave insert mode |
| `<leader>w` | normal | Save |
| `<leader>q` | normal | Quit |
| `<leader>h` | normal | Clear search highlight |
| `Ctrl+h/j/k/l` | normal | Move between splits. At the edge, inside tmux, move to the tmux pane there |

Splits use the Vim defaults: `:split`, `:vsplit`, or `Ctrl+w s` / `Ctrl+w v`.

## What it sets

- Line numbers, relative numbers, cursor line, 8 lines of margin when scrolling.
- Smart-case search with live matches and highlight.
- Two-space indent with spaces (`expandtab`), mouse on.
- Persistent undo in `~/.vim/undo`, created on first start. No swap or backup files.
- Clipboard: yanks use the system clipboard (on Linux, both the clipboard and the selection). Over SSH the clipboard is left alone.

## Change it

1. Edit `vim/.vimrc` in the repo. The link points there.
2. Reopen Vim.

The file does not load a local override file, so machine-only settings are not supported. Add them to the repo file or run `:set` by hand.

## Related

- [nvim.md](nvim.md): the full editor config.
- [tmux.md](tmux.md): how `Ctrl+h/j/k/l` crosses panes.
