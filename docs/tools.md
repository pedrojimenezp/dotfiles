# Tools

Everything below is installed by the `Brewfile` (`brew bundle`, run by `install.sh`). A tool that is missing never breaks the shell config. Run `tldr <tool>` for more examples.

## Editor, terminal, shell

| Tool | What it is for | Example |
| --- | --- | --- |
| `neovim` | Main editor ([nvim.md](nvim.md)) | `nvim file.go` (or `vim file.go`) |
| `tmux` | Sessions, windows, panes ([tmux.md](tmux.md)) | `tmux new-session -A -s work` |
| `tmux-fingers` | Binary behind the tmux hint-copy plugin ([tmux.md](tmux.md#copy-with-hints)) | `prefix Space`, then a hint letter |
| `stow` | Links each package into `$HOME` | `stow --restow --no-folding -d ~/dotfiles -t ~ zsh` |
| `starship` | Prompt (see below) | `starship explain` |
| `zsh-autosuggestions` | Grey history suggestion while you type | Press `Right arrow` to accept |
| `zsh-syntax-highlighting` | Colors valid and invalid commands | Type `foo` (red) vs `ls` (green) |
| `zsh-completions` | More Tab completions | `git <Tab>` |
| `fzf-tab` | Tab completion through fzf, with a folder preview for `cd` | `cd <Tab>` |

## Shell productivity

| Tool | What it is for | Example |
| --- | --- | --- |
| `fzf` | Fuzzy finder | `Ctrl+R` history, `Ctrl+T` files, `Alt+C` folders; `git log --oneline \| fzf` |
| `atuin` | Searchable shell history in a local database (`Up`, `Ctrl+R`); no sync | `Ctrl+R`, `atuin stats` |
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

- `atuin`: searchable shell history, can sync between machines.
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

- Add a line `brew "name"  # what it does` to the `Brewfile`, then run `brew bundle --file ~/projects/personal/dotfiles/Brewfile` (or `./install.sh`).
- `install.sh` runs `brew bundle --no-upgrade`: it never upgrades. Upgrade yourself with `brew upgrade`.
- List what is installed but not in the `Brewfile`: `brew bundle cleanup --file Brewfile` (it only lists; add `--force` to remove).

## Prompt: starship

File: `starship/.config/starship.toml`, linked to `~/.config/starship.toml`. Docs: <https://starship.rs/config/>.

The prompt has two lines. First line: folder (at most 3 segments, relative to the git repo root), git branch, git status (compact, like `[!?⇡]`), the language versions for Go, Node, Zig and Python when the folder uses them, and the command time when a command took more than 2 seconds. Second line: `❯`, green after success, red after an error. A blank line separates prompts. Icons need a Nerd Font.

To change it, edit the `format` string or a section in the file, and open a new prompt (no restart needed). Run `starship explain` to see what each part shows. Prompt modules time out at 500 ms.

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

`dotfiles-usage [week|2weeks|month]` (default `week`) lists how often each tool of this repo was used in that period, most used first. Tools never used are last, marked `← unused`: candidates to remove. The footer shows the period and the data source.

- **Tool list**: nothing is kept by hand. It reads the `brew` lines of the `Brewfile` (plugins, libraries and helpers like `zsh-*`, `fzf-tab` and `tree-sitter-cli` have no command, so they are skipped), the scripts in `bin/.local/bin` and the `tssh` function. Aliases in `zsh/.zshrc` count for their tool (`lg` is `lazygit`, `vim` is `nvim`, `tt` is `theme`, `ls` is `eza`, `z` is `zoxide`).
- **History**: atuin (`atuin search --filter-mode global --after "N days ago"`) when installed, else `~/.zsh_history` (needs `EXTENDED_HISTORY`, set in `.zshrc`). The zsh fallback undercounts repeated commands because `HIST_IGNORE_ALL_DUPS` keeps only the latest copy of each command line; atuin keeps every run and is the accurate source. `DOTFILES_USAGE_HISTFILE=file` reads another zsh history file; `ATUIN_DB_PATH` points atuin at another database.
- **Key-launched tools** do not reach shell history, so `tmux-popup`, `tmux-sessionizer` and `dotfiles-help` call `dotfiles-log <tool>`, which appends `<epoch> <tool>` to `${XDG_STATE_HOME:-~/.local/state}/dotfiles/usage.log` and never fails (`dotfiles-log --path` prints the file). Any script that calls `dotfiles-log` is counted from that log only. Delete the file to reset it.
- **Approximation**: the first word of each command counts, and so does each part of a pipe or chain (`a | b`, `a && b`), after `FOO=1` prefixes and `sudo`. Tools run from scripts, `xargs` or `$(...)`, and keys handled by a tool itself (fzf `Ctrl+R`, `Ctrl+T`) are not seen.
