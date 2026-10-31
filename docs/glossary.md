# Glossary

Short definitions of the terms the other pages use. Each page links here the first time a term appears.

## atuin

A shell history tool. It keeps every command in a local database and opens a searchable list on `Up` or `Ctrl+R`. See [zsh.md](zsh.md).

## dotfiles

Configuration files in your home folder, usually named with a leading dot (`.zshrc`). This repo keeps them in git so every machine gets the same setup.

## fzf

A fuzzy finder: type a few letters and it narrows a list as you go. Many keys here open an fzf list, such as `Ctrl+T` for files.

## hunk

One block of changed lines in a git diff. In Neovim you can jump between hunks and stage one at a time. See [nvim.md](nvim.md).

## keybinding

A key, or sequence of keys, mapped to an action. Also called a "key" in these docs.

## leader

A prefix key for your own Neovim shortcuts. Here it is `Space`, so `<leader>sf` means `Space`, then `s`, then `f`.

## link

A small file that points to another file. Its full name is "symbolic link" (symlink). The installer creates links in your home folder that point into this repo, so editing either place edits the same file.

## lsp

Language Server Protocol. A language server reads your code and gives Neovim go-to-definition, rename, errors and completion. See [nvim.md](nvim.md).

## mason

A Neovim plugin that downloads language servers, formatters and linters for you. Run `:Mason` in Neovim to see them.

## mise

A tool version manager. It installs node, go and other runtimes, and switches versions per project from a `mise.toml` file. See [tools.md](tools.md).

## nerd-font

A font patched with extra icons (file types, git, folders). The prompt, tmux and Neovim use these icons, so your terminal needs a Nerd Font. See [terminals.md](terminals.md).

## osc-52

A terminal escape code that copies text to your computer's clipboard. It works over SSH, so copying on a server lands on your laptop.

## package

One top-level folder of this repo, such as `zsh/` or `nvim/`. Its contents mirror your home folder, and [stow](#stow) links them into place.

## pane

One rectangle inside a tmux [window](#window). Split a window to get several panes side by side.

## popup

A floating tmux box drawn over your panes. Here popups show the help list, lazygit, a scratch shell or Claude Code.

## prefix

The key you press before a tmux command. Here it is `Ctrl+Space`: press it, release it, then press the next key. `prefix c` means `Ctrl+Space`, then `c`.

## prompt

The text the shell prints before your cursor, waiting for a command. Here [starship](#starship) draws it.

## scrollback

The lines that scrolled off the top of the screen and that you can scroll back to. See [tmux.md](tmux.md#status-bar-and-pane-labels) for how much tmux keeps.

## session

A named group of tmux [windows](#window). Sessions keep running when you close the terminal, and you can reattach later.

## shell

The program that reads the commands you type, such as zsh or bash. These dotfiles configure zsh.

## starship

The program that draws the [prompt](#prompt). It shows the folder, git branch, tool versions and the last command's status. See [tools.md](tools.md).

## stow

GNU Stow, the tool that creates the [links](#link) from your home folder into this repo. The installer runs it for every [package](#package).

## tpm

Tmux Plugin Manager. It downloads the tmux plugins listed in `tmux.conf`. Its keys are in [tmux.md](tmux.md#add-a-plugin).

## treesitter

A parser that understands code structure. Neovim uses it for accurate syntax colors and indentation.

## window

A full-screen tab inside a tmux [session](#session). Each window holds one or more [panes](#pane).

## worktree

An extra checkout of a git repo in its own folder, on its own branch. You can work on two branches at once without stashing.

## zoxide

A smarter `cd`. It remembers the folders you visit, so `z proj` jumps to the best match. See [zsh.md](zsh.md).
