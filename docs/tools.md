# Tools

The command-line tools this repo installs and configures. Everything below comes from the `Brewfile` (`brew bundle`, run by `install.sh`). A missing tool never breaks the shell config.

You'll use it for: finding what a tool is for and how to start it. Run `tldr <tool>` for more examples.

- [Editor, terminal, shell](#editor-terminal-shell)
- [Shell productivity](#shell-productivity)
- [Git and containers](#git-and-containers)
- [Languages and dev tools](#languages-and-dev-tools)
- [macOS-only (casks)](#macos-only-casks)
- [Add or update a tool](#add-or-update-a-tool)
- [Prompt: starship](#prompt-starship)
- [Runtimes: mise](#runtimes-mise)
- [Usage report: dotfiles-usage](#usage-report-dotfiles-usage)
- [How it works](#how-it-works)

## Quick start

1. Run `brew bundle --file Brewfile` in the folder you cloned to (or `./install.sh`).
2. Open a new terminal.
3. Try `ll`, `z <folder>`, `Ctrl+r` and `dotfiles-help`.

## Editor, terminal, shell

| Tool | What it is for | Example |
| --- | --- | --- |
| `neovim` | Main editor ([nvim.md](nvim.md)) | `nvim file.go` (or `vim file.go`) |
| `tmux` | [Sessions](glossary.md#session), [windows](glossary.md#window), [panes](glossary.md#pane) ([tmux.md](tmux.md)) | `tmux new-session -A -s work` |
| `tmux-fingers` | Binary behind the tmux hint-copy plugin ([tmux.md](tmux.md#copy-with-hints)) | `prefix Space`, then a hint letter (see [tmux.md](tmux.md)) |
| `stow` | [Links](glossary.md#link) each [package](glossary.md#package) into `$HOME` | `stow --restow --no-folding -d ~/dotfiles -t ~ zsh` |
| `starship` | [Prompt](glossary.md#prompt) (see below) | `starship explain` |
| `zsh-autosuggestions` | Grey history suggestion while you type | Press `Right` to accept |
| `zsh-syntax-highlighting` | Colors valid and invalid commands | Type `foo` (red) vs `ls` (green) |
| `zsh-completions` | More Tab completions | `git <Tab>` |
| `fzf-tab` | Tab completion through fzf, with a folder preview for `cd` | `cd <Tab>` |

## Shell productivity

| Tool | What it is for | Example |
| --- | --- | --- |
| `fzf` | Fuzzy finder | `Ctrl+r` history, `Ctrl+t` files, `Alt+c` folders; `git log --oneline \| fzf` |
| `atuin` | Searchable shell history in a local database (`Up`, `Ctrl+r`); no sync | `Ctrl+r`, `atuin stats` |
| `zoxide` | Smart `cd` | `z dotfiles`, `zi` |
| `eza` | Better `ls` (aliases `ls`, `ll`, `la`, `lt`) | `ll`, `lt` |
| `bat` | `cat` with colors (alias `cat`) | `bat README.md` |
| `ripgrep` (`rg`) | Very fast text search (used by nvim grep) | `rg "TODO" src/` |
| `fd` | Simple, fast `find` | `fd '\.lua$'` |
| `jq` | JSON on the command line | `curl -s url \| jq '.items[0]'` |
| `yq` | Same for YAML, TOML, XML | `yq '.services' compose.yaml` |
| `btop` | System monitor | `btop` (`q` quits) |
| `tealdeer` (`tldr`) | Short command examples | `tldr tar` (first run: `tldr --update`) |
| `hyperfine` | Benchmark commands | `hyperfine 'zsh -i -c exit'` |

Optional, commented in the `Brewfile` (remove the `#` and run `brew bundle`):

- `mosh`: SSH-like shell that survives sleep and roaming (`mosh myserver`).

## Git and containers

| Tool | What it is for | Example |
| --- | --- | --- |
| `git-delta` | Diff pager ([git.md](git.md)) | `git diff` |
| `lazygit` | Git UI (alias `lg`) | `lg` (`?` shows keys, `q` quits) |
| `lazydocker` | Docker UI (alias `lzd`) | `lzd` |
| `dive` | Explore Docker image layers | `dive my-image:latest` |
| `gh` | GitHub CLI | `gh pr create --draft`, `gh auth login` |
| `git-lfs` | Large files in git (used by the git config filter) | `git lfs track "*.psd"` |

## Languages and dev tools

| Tool | What it is for | Example |
| --- | --- | --- |
| `mise` | Per-project runtimes (see below) | `mise use node@22` |
| `zig`, `zls` | Zig compiler and language server (kept in Homebrew so versions match) | `zig build` |
| `shellcheck` | Lints shell scripts (nvim runs it on save) | `shellcheck install.sh` |
| `shfmt` | Formats shell scripts | `shfmt -w script.sh` |
| `golangci-lint` | Go linters | `golangci-lint run` |
| `tree-sitter-cli` | Builds treesitter parsers for nvim | Used by nvim; no manual command |

## macOS-only (casks)

- `ghostty`: terminal, see [terminals.md](terminals.md).
- `font-monaspice-nerd-font`: the font. Casks install into `~/Applications`, so no admin rights are needed.

On Linux, install Ghostty with your distro's package if you want it; the font is installed by `install.sh` on desktops.

## Add or update a tool

- Add a line `brew "name"  # what it does` to the `Brewfile`, then run `brew bundle` in the folder you cloned to (or `./install.sh`).
- Upgrade tools yourself with `brew upgrade`. `install.sh` never upgrades them.
- List what is installed but not in the `Brewfile`: `brew bundle cleanup --file Brewfile` (it only lists; add `--force` to remove).

## Prompt: starship

File: `starship/.config/starship.toml`, linked to `~/.config/starship.toml`. Docs: <https://starship.rs/config/>. Icons need a [Nerd Font](glossary.md#nerd-font).

Example of the two-line prompt (`<os>` and `<branch>` stand for icons):

```text
╭─ <os> ~/dotfiles on <branch> main !1?2⇡ via <go> 1.25 3s ········ ✔ at 14:32:05
╰─❯
```

First line, left to right:

- the OS icon,
- the folder, at most 3 segments, relative to the git repo root,
- `on` and the git branch,
- git status as counts: `!` modified, `?` untracked, `+` staged, `⇡` ahead,
- `via` and the version of Go, Node, Zig or Python, when the folder uses them,
- the command time, when a command took more than 2 seconds.

A dotted fill then pushes the rest to the right edge: `✔` after success, or `✘` and the exit code after an error, then `at` and the time. The second line is `❯`, green after success and red after an error. A blank line separates prompts.

Over SSH only, the host shows after the OS icon in bold purple, followed by `in`. It is `HOST_LABEL` from `~/.zshrc.local`, else the short hostname. Locally nothing shows.

To change the prompt:

1. Edit the `format` string or a section in the file.
2. Open a new prompt. No restart is needed.
3. Run `starship explain` to see what each part shows.

## Runtimes: mise

mise installs and switches versions of node, go and other tools per project.

- **Global config**: `mise/.config/mise/config.toml`, linked to `~/.config/mise/config.toml`. It sets `node = "lts"` and `go = "latest"` as defaults. It also reads `.nvmrc` and `.node-version` files (`idiomatic_version_file_enable_tools = ["node"]`).
- **New machine**: `install.sh` runs `mise install`. You can run it yourself any time.
- **Per project**: inside the project, `mise use node@22 go@1.25` creates `mise.toml`; commit it. Versions switch when you `cd`. A project with `.nvmrc` works without `mise.toml`: run `mise install` there.
- **Global change**: `mise use -g node@22` edits the repo file through the link, so commit the change.
- **Secrets per project**: an untracked `mise.local.toml`. mise also supports `[env]` and `[tasks]` in `mise.toml`.
- **See / update**: `mise ls` (installed and active), `mise outdated`, `mise upgrade`.
- **Go**: the `toolchain` line in `go.mod` still works. `go install` tools land in `~/go/bin` (on `PATH`).
- **Old mise**: a standalone mise in `~/.local/bin` would shadow the Homebrew one, so `install.sh` renames it to `mise.backup-<stamp>`.
- Zig is not managed by mise: the zig and zls versions must match, so both come from Homebrew.

## Usage report: dotfiles-usage

```sh
dotfiles-usage            # last 7 days
dotfiles-usage month      # also: 2weeks
```

It lists how often each tool of this repo was used in that period, most used first. Tools never used come last, marked `← unused`: candidates to remove. The footer shows the period and the data source.

## How it works

**Prompt.** Icons are written as `\uXXXX` escapes in the toml, so tools cannot strip them. `zsh/.zshrc` exports `PROMPT_HOST` over SSH only, and starship shows it. Prompt modules time out at 500 ms. The first line uses plain connector words (`in`, `on`, `via`) like starship's classic style.

**Installs.** `install.sh` runs `brew bundle --no-upgrade`, so it never upgrades. The cask font installs into `~/Applications`, so no admin rights are needed.

**dotfiles-usage internals.**

- **Tool list.** Nothing is kept by hand. It reads the `brew` lines of the `Brewfile`, the scripts in `bin/.local/bin` and the `tssh` function. Plugins, libraries and helpers such as `zsh-*`, `fzf-tab` and `tree-sitter-cli` have no command, so they are skipped. Aliases in `zsh/.zshrc` count for their tool: `lg` is `lazygit`, `vim` is `nvim`, `tt` is `theme`, `ls` is `eza`, `z` is `zoxide`.
- **History.** It uses atuin (`atuin search --filter-mode global --after "N days ago"`) when installed, else `~/.zsh_history`. The zsh fallback needs `EXTENDED_HISTORY` and undercounts repeated commands, because `HIST_IGNORE_ALL_DUPS` keeps only the latest copy of each line. atuin keeps every run. `DOTFILES_USAGE_HISTFILE=file` reads another zsh history file, and `ATUIN_DB_PATH` points atuin at another database.
- **Key-launched tools.** They do not reach shell history, so `tmux-popup`, `tmux-sessionizer`, `dotfiles-help` and `theme` call `dotfiles-log <tool>`. It appends `<epoch> <tool>` to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/usage.log` and never fails. `dotfiles-log --path` prints the file, and deleting it resets the counts. A script that calls `dotfiles-log` is counted from that log only.
- **What `theme` counts.** Only runs you start: `toggle`, `dark`, `light`, `auto`, `pick` and `set`, including nvim's `<leader>ut` and the `tt` alias. Automatic calls such as `theme apply` at shell start, `theme file`, `theme mode` and `sync` are not counted.
- **Approximation.** The first word of each command counts, and so does each part of a pipe or chain (`a | b`, `a && b`), after `FOO=1` prefixes and `sudo`. Tools run from scripts, `xargs` or `$(...)` are not seen. Keys handled by a tool itself, such as fzf `Ctrl+r` and `Ctrl+t`, are not seen either.

## Related

- [zsh.md](zsh.md): aliases and the tool init.
- [git.md](git.md): delta and the git config.
- [nvim.md](nvim.md), [tmux.md](tmux.md), [terminals.md](terminals.md): the editor, multiplexer and terminal.
