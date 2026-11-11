# Install

macOS or a Linux desktop. For a server, see [server.md](server.md).

The installer never uses sudo and never upgrades tools. It renames any file it would replace to `<file>.backup-<date>-<time>`, and asks for a git name and email if none is set (stored in `~/.config/git/local`).

## macOS

1. `xcode-select --install`, and [Homebrew](https://brew.sh). Homebrew installs only `mise`, `stow`, `btop`, `pngpaste`, `chafa`, `skhd-zig` and the apps (into `~/Applications`); mise installs the rest.
2. Clone and run:
   ```sh
   git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
   cd ~/dotfiles && ./install.sh
   ```
3. In iTerm2, make the **Dotfiles** profile the default ([terminals.md](terminals.md#iterm2)).

## Linux desktop

1. System packages, once per machine:
   ```sh
   sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1 xz-utils
   ```
   `install.sh` prints the exact line for anything missing. `xz-utils` unpacks the Nerd Font, which is installed for you.
2. Clone and run `./install.sh`, as on macOS.
3. `chsh -s "$(command -v zsh)"` (Ubuntu: `sudo chsh -s /usr/bin/zsh "$USER"`), then log out and in.

Ghostty isn't installed on Linux; its config is linked when `ghostty` exists.

## Check it worked

`exec zsh` shows the two-line prompt; `tmux` shows the status bar; the first `nvim` installs plugins and language tools: wait until the messages stop.

## Flags

```sh
./install.sh --dry-run                # print every action, change nothing
./install.sh --with-claude <git-url>  # also clone ~/.config/claude-shared and run its pull.sh --install
```

`--with-claude` clones only if the folder is missing; a private repo needs a GitHub SSH key. Claude Code itself is in that repo's README. `.zshrc` loads its `claude.sh` only when present.

## Update

```sh
cd ~/dotfiles && git pull && ./install.sh
```

This refreshes links, installs what's missing and fast-forwards the zsh plugins. Upgrade tools yourself:

```sh
mise outdated && mise upgrade
brew upgrade mise    # macOS (a plain brew upgrade upgrades everything)
mise self-update     # Linux
```

The zsh tool cache rebuilds when a tool's version changes.

## Per-machine files

Never in the repo:

| File | For |
| --- | --- |
| `~/.zshrc.local` | Secrets, paths, aliases |
| `~/.config/git/local` | Identity, work email, signing ([git.md](git.md)) |
| `~/.config/tmux/local.conf` | tmux overrides |
| `~/.local/state/theme` | Forced light/dark mode ([theme.md](theme.md)) |
| `mise.local.toml` | Untracked project env ([tools.md](tools.md)) |

## Uninstall

```sh
./uninstall.sh --dry-run   # show the plan
./uninstall.sh             # asks "Continue? [y/N]"; --yes skips it
```

It runs `stow --delete` and puts back the newest backup of each file (and `~/.gitconfig`) when the path is free. `--with-claude` also runs `~/.config/claude-shared/install.sh --uninstall` and deletes the clone unless it has unsaved work or that uninstall is missing or fails (then it keeps the clone and says so). The summary lists what it removed, restored and skipped. It keeps the clone, tool data and caches, Homebrew packages, the login shell and running tmux.

To restore one file: `ls ~/.zshrc.backup-*`, then `rm ~/.zshrc && mv ~/.zshrc.backup-<stamp> ~/.zshrc`. The next `./install.sh` links it again.

## Layout

Each top-level folder is a stow package mirroring `$HOME` (`git/.config/git/config` → `~/.config/git/config`). `iterm` and `skhd` are linked on macOS only, `ghostty` when Ghostty is installed. To add a package, add it to `PACKAGES` in `install.sh` and `uninstall.sh`.

stow runs with `--no-folding`, so folders like `~/.config/ghostty` stay real and generated files (`theme.conf`) never land in the repo. tmux plugins install on a private, throwaway tmux server, so a running tmux is never touched.

## Troubleshooting

`install.sh` keeps no log file; rerun with `--dry-run` to see the plan.

- **"Missing: ..."** (Linux): run the `apt-get` line it prints.
- **"Homebrew was not found."**: install it, open a new shell, rerun.
- **"brew bundle failed"**: one formula or app failed; the install went on. Run `brew bundle` in the repo to see which, then rerun it.
- **"some mise tools failed"**: `mise install` shows which and why (often the network).
- **`zsh compinit: insecure directories`**: a completion folder is group- or world-writable. `install.sh` runs `chmod go-w` on Homebrew's, but `brew` can restore the bits: `compaudit`, then `chmod go-w` each path. A path owned by another user still prompts: check it first.
- **stow conflict**: a real file blocks a link. Rename it and rerun.
- **tmux plugin missing**: `prefix I`.
- **Shell acts strange after a change**: `rm -rf ~/.cache/zsh && exec zsh`.
- **Icons are boxes**: the terminal font isn't a Nerd Font ([terminals.md](terminals.md)).
- **`--with-claude` "could not clone"**: share the GitHub key as in [server.md](server.md#share-the-github-key).
