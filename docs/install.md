# Install

How to install these dotfiles, what `install.sh` does, and what to do when something fails. For a remote Ubuntu server, the full guide is [server.md](server.md).

The packages are linked with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level folder is a **package** whose contents mirror `$HOME`. For example `git/.config/git/config` becomes `~/.config/git/config`.

## macOS

```sh
xcode-select --install   # Git and compilers, if you do not have them yet
git clone https://github.com/pedrojimenezp/dotfiles ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./install.sh
```

Install [Homebrew](https://brew.sh) first if `brew` is missing. `install.sh` prints the command and stops. Apps (casks) go into `~/Applications`, so no admin rights are needed.

## Linux desktop

1. Install `git`, `curl`, `zsh` and build tools with your package manager. You run this, with sudo if needed.
2. Install Homebrew for Linux, then follow the "Next steps" it prints:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. Clone this repo and run `./install.sh`.
4. Make zsh your login shell: `chsh -s "$(command -v zsh)"`. On Ubuntu: `sudo chsh -s /usr/bin/zsh "$USER"`. Then log out and in. The installer prints the right command at the end.

Ghostty is not in the Brewfile on Linux. Install it with your distro's package if you want it; `install.sh` links its config when the `ghostty` command exists. The Nerd Font is installed for you on desktops.

## Ubuntu server

Run as a normal user with sudo. `install.sh` itself never uses sudo. This is the short version (Ubuntu 22.04 or 24.04); the step-by-step guide with SSH setup and daily use is [server.md](server.md).

```sh
# 1. Prerequisites (the only step that needs sudo)
sudo apt-get update && sudo apt-get install -y build-essential procps curl file git zsh

# 2. Homebrew (non-interactive) and its PATH
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 3. Clone and install (add --with-claude if you have GitHub SSH access)
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh

# 4. Make the system zsh the login shell, then log out and in
sudo chsh -s /usr/bin/zsh "$USER"
```

The Nerd Font step is skipped on a headless server (your local terminal draws the font). Git fetches stay on https, so the install works without a GitHub key (only `--with-claude` and `git push` need one).

## Flags

```sh
./install.sh --dry-run      # print what would happen, change nothing
./install.sh --with-claude  # also clone and install the private Claude config
./install.sh --help         # usage
```

Flags can be combined (`--dry-run --with-claude`).

- **`--dry-run`**: every action is printed with a `[dry-run]` prefix. Use it first on a new machine.
- **`--with-claude`**: clones the private `claude-config` repo to `~/.config/claude-shared` (or `$CLAUDE_SHARED_DIR`) and runs its own `install.sh`. It needs GitHub SSH access. If the clone already exists it is not pulled. With no access, or when the folder exists but is not a git repo, the step is skipped (its `install.sh` does not run), everything else finishes, and the script exits with an error at the end. In `--dry-run` it only prints that it would check GitHub access and clone. The zsh config loads `~/.config/claude-shared/zsh/claude.zsh` only if that file exists, so these dotfiles work without it.

## What `install.sh` does, in order

1. Checks that `zsh` exists. Without it the script stops (with `--dry-run` it continues).
2. **Homebrew packages**: `brew bundle --no-upgrade`. It installs what is missing and never upgrades. If `brew` is missing it prints the install command and stops (with `--dry-run` it continues).
3. Decides the package list. `zsh nvim tmux vim git starship mise atuin bin theme`, plus `iterm` on macOS, plus `ghostty` when Ghostty is installed.
4. Renames an old standalone `~/.local/bin/mise` that would shadow the Homebrew one.
5. **Backs up** every real file a package would link: `<file>.backup-YYYYmmdd-HHMMSS`. Files that are already links into this repo are left alone. `~/.gitconfig` is backed up too, because it beats `~/.config/git/config`.
6. Removes the old iTerm profile link from earlier installs.
7. **Links** the packages with `stow --restow --no-folding`. `--no-folding` makes each file its own link, so folders like `~/.config/ghostty` stay real folders and generated files never land in the repo. Without `stow` it uses plain symlinks.
8. `mise install` for the global runtimes.
   Then, only when `~/.local/share/atuin/history.db` does not exist yet, `atuin import zsh` copies `~/.zsh_history` into atuin once. A failure only prints a warning.
9. Removes the old `~/.config/git/local` https override, but only if an older installer wrote it.
10. Clones **TPM** into `~/.config/tmux/plugins/tpm` and installs the tmux plugins.
11. Linux desktop only: installs the Monaspace Nerd Font into `~/.local/share/fonts`.
12. `theme sync`: writes the Ghostty and iTerm theme files. A failure here only prints a warning.
13. `--with-claude` step, if asked.
14. Prints the next steps and, if zsh is not your login shell, the `chsh` command.

## Idempotent and safe

You can run `./install.sh` again at any time (for example after `git pull`). Links are refreshed, installed things are skipped, nothing is upgraded, and your own files are backed up, never deleted. It never uses sudo.

To update a machine:

```sh
cd ~/projects/personal/dotfiles && git pull && ./install.sh
```

## After installing

1. Start a new shell: `exec zsh`.
2. tmux plugins are installed already. If one failed, open tmux and press `Ctrl+Space`, then `Shift+i`.
3. Open `nvim` once and wait for lazy.nvim, Mason and treesitter to finish.
4. Put secrets and machine settings in `~/.zshrc.local` ([zsh.md](zsh.md)).
5. Put machine-specific git settings in `~/.config/git/local` ([git.md](git.md)).
6. iTerm only: set the **Dotfiles** profile as default ([terminals.md](terminals.md)).

## Per-machine files (not in the repo)

| File | For |
| --- | --- |
| `~/.zshrc.local` | Secrets, paths, aliases ([zsh.md](zsh.md)) |
| `~/.config/git/local` | Work email, signing, local git rules ([git.md](git.md)) |
| `~/.local/state/theme` | Saved light/dark mode ([theme.md](theme.md)) |
| `~/.config/ghostty/theme.conf` | Generated by `theme sync` ([theme.md](theme.md)) |
| `mise.local.toml` (per project) | Untracked project environment ([tools.md](tools.md)) |
| `~/.ssh/config` | SSH hosts ([server.md](server.md)) |

## Troubleshooting

- **"zsh was not found"**: install zsh with your package manager and run the script again.
- **"Homebrew was not found"**: install it (command above), open a new shell, run again.
- **stow reports a conflict**: a real file blocks a link. The backup step normally moves it away. Look for the path in the message, rename it, and run the script again.
- **A tmux plugin is missing**: in tmux press `Ctrl+Space`, then `Shift+i`.
- **Icons look wrong**: the terminal font is not a Nerd Font ([terminals.md](terminals.md)).
- **Colors did not change after `theme sync`**: see [theme.md](theme.md).
- **`--with-claude` says "no GitHub SSH access"**: forward or add your GitHub key, see [server.md](server.md), then run it again.
- **Go back to the old files**: the backups are next to the links: `ls ~/.zshrc.backup-*`. Remove the link and rename the backup.
- **Remove everything**: `stow --delete --dir=$HOME/projects/personal/dotfiles --target=$HOME zsh nvim tmux vim git starship mise atuin bin theme` (add `ghostty iterm` if linked). It removes only the links.
