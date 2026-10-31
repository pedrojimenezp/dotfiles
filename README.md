# dotfiles

A complete terminal setup for macOS and Linux: zsh, tmux, Neovim, git and a set of command-line tools, installed with one script. Every config line has a short comment and every part has a doc, so the repo also works as a learning reference.

## Who it's for

Anyone. Fork it and use it as your own, or read it and copy the pieces you like. You don't need to know tmux or Neovim yet: [first-day.md](docs/first-day.md) gets you going.

## What you get

- **zsh** with history search on `Up`, fuzzy file and folder pickers, and a two-line prompt.
- **tmux** with `Ctrl+Space` as the prefix, project sessions, popups, and sessions that survive a reboot.
- **Neovim** with file search, language servers, formatting and git signs.
- **One light/dark theme** shared by the terminal, tmux and Neovim.
- **Built-in help**: `prefix ?` in tmux or `dotfiles-help` in a shell searches every key.
- **A safe installer**: it backs up your files, never uses sudo and never upgrades your tools.

## Quick start

One script installs everything: it backs up your old files, links the configs and installs the tools with mise, per user, the same on macOS and Linux.

- **macOS or a Linux desktop**: follow [install.md](docs/install.md).
- **A remote Ubuntu server**: follow [server.md](docs/server.md).

## Start here

1. [install.md](docs/install.md): install, check it worked, update, undo.
2. [first-day.md](docs/first-day.md): the keys you'll use most, and what to do when something breaks.
3. [tmux.md](docs/tmux.md), [zsh.md](docs/zsh.md) and [nvim.md](docs/nvim.md): every key, by tool.

Forgot a key? Press `prefix ?` in tmux (`Ctrl+Space`, then `?`) or run `dotfiles-help`.

## Docs

| Group | Page | What is in it |
| --- | --- | --- |
| Start here | [install.md](docs/install.md) | Install on each OS, flags, update, undo, troubleshooting |
| | [first-day.md](docs/first-day.md) | The keys you'll use most, help, recovery |
| | [server.md](docs/server.md) | A remote Ubuntu server over SSH, `tssh`, GitHub key forwarding |
| Everyday tools | [tmux.md](docs/tmux.md) | Prefix, every key, status bar, popups, saved sessions |
| | [tmux-sessionizer.md](docs/tmux-sessionizer.md) | The project session picker (`prefix f`) |
| | [zsh.md](docs/zsh.md) | Aliases, keys, history, fzf, zoxide, `~/.zshrc.local` |
| | [nvim.md](docs/nvim.md) | Neovim keys, plugins, language servers |
| | [git.md](docs/git.md) | Git settings, aliases, `~/.config/git/local` |
| | [tools.md](docs/tools.md) | Every tool with an example, starship, mise |
| | [migrate-to-mise.md](docs/migrate-to-mise.md) | Remove the old Homebrew copies after moving the tools to mise |
| Reference | [terminals.md](docs/terminals.md) | Ghostty, iTerm2, font, terminal keys |
| | [theme.md](docs/theme.md) | The `theme` command and light/dark mode |
| | [vim.md](docs/vim.md) | The small plugin-free `.vimrc` for servers |
| | [glossary.md](docs/glossary.md) | The terms these docs use |
| Contributing | [contributing.md](docs/contributing.md) | Add a key or tool so help and docs stay in sync |

## License

MIT. See [LICENSE](LICENSE).
