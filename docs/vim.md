# Vim (servers)

File: `vim/.vimrc`, linked to `~/.vimrc`. It is a small config **without plugins**, for machines where Neovim is not installed (for example a server). On a machine with Neovim, the `vim` and `vi` aliases open `nvim` (see [nvim.md](nvim.md)). Use `command vim` to run the real Vim.

## Keys

The leader key is `Space`. Press the keys one after another.

| Keys | Mode | What it does |
| --- | --- | --- |
| `jk` | insert | Leave insert mode |
| `Space` then `w` | normal | Save |
| `Space` then `q` | normal | Quit |
| `Space` then `h` | normal | Clear search highlight |
| `Ctrl+h/j/k/l` | normal | Move between splits |

Splits use the Vim defaults: `:split`, `:vsplit`, or `Ctrl+w s` / `Ctrl+w v`.

## What it sets

- Line numbers, relative numbers, cursor line, 8 lines of margin when scrolling.
- Smart-case search with live matches and highlight.
- Two-space indent with spaces (`expandtab`), mouse on.
- Persistent undo in `~/.vim/undo` (created on first start). No swap or backup files.
- Clipboard: the system clipboard locally; not touched over SSH.

## Change it

Edit `vim/.vimrc` in the repo (the link points there), then reopen Vim. The file does not load a local override file, so machine-only settings are not supported: add them to the repo file or run `:set` by hand.
