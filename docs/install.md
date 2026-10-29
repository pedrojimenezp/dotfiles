# Install

How to install these [dotfiles](glossary.md#dotfiles) on macOS, a Linux desktop or an Ubuntu server, and how to update or remove them. You'll use it once per machine, then again to update.

- [Before you start](#before-you-start)
- [macOS](#macos)
- [Linux desktop](#linux-desktop)
- [Ubuntu server](#ubuntu-server)
- [Check it worked](#check-it-worked)
- [After installing](#after-installing)
- [Update](#update)
- [Flags](#flags)
- [Undo or uninstall](#undo-or-uninstall)
- [Per-machine files](#per-machine-files)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)

## Before you start

- **Fork it if you want your own copy.** Fork the repo on GitHub and clone your fork instead of the URL below. Then you can commit your changes and pull them on every machine.
- **Pick any folder.** These steps clone into `~/dotfiles`, but any path works. Commands below that start with `cd ~/dotfiles` mean "the folder you cloned to".
- **Have your git name and email ready.** If git has no identity yet, the installer asks for both. It stores them in `~/.config/git/local`, outside the repo.
- **Nothing is deleted.** The installer renames any file it would replace to `<file>.backup-<date>-<time>`. See [Undo or uninstall](#undo-or-uninstall).
- **No sudo.** `install.sh` never uses sudo and never upgrades what you already have. You install the prerequisites yourself.

## macOS

1. Install Apple's command-line tools (git and compilers), if you don't have them yet:
   ```sh
   xcode-select --install
   ```
2. Install [Homebrew](https://brew.sh) if `brew` is missing. The installer prints the command and stops without it.
3. Clone the repo and run the installer:
   ```sh
   git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

Apps go into `~/Applications`, so you need no admin rights.

## Linux desktop

1. Install `git`, `curl`, `zsh` and build tools with your package manager. Use sudo if your system needs it.
2. Install Homebrew for Linux, then follow the "Next steps" it prints:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. Clone the repo and run the installer:
   ```sh
   git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```
4. Make zsh your login shell, then log out and in. The installer prints the right command at the end. On most systems:
   ```sh
   chsh -s "$(command -v zsh)"
   ```
   **Linux (Ubuntu):** use `sudo chsh -s /usr/bin/zsh "$USER"`.

Ghostty is not in the Brewfile on Linux. Install it from your distro if you want it; the installer links its config when the `ghostty` command exists. The [Nerd Font](glossary.md#nerd-font) is installed for you on desktops.

## Ubuntu server

This is the short version for Ubuntu 22.04 or 24.04. For SSH setup and daily use, follow the full guide in [server.md](server.md).

Run these on the server, as a normal user with sudo:

```sh
# 1. Prerequisites (the only step that needs sudo)
sudo apt-get update && sudo apt-get install -y build-essential procps curl file git zsh

# 2. Homebrew and its PATH
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 3. Clone and install
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh

# 4. Make zsh the login shell, then log out and in
sudo chsh -s /usr/bin/zsh "$USER"
```

The server skips the Nerd Font: your laptop's terminal draws the icons. Git fetches use https, so the install works without a GitHub key.

## Check it worked

1. Open a new shell:
   ```sh
   exec zsh
   ```
   The two-line [prompt](glossary.md#prompt) appears, with the folder name and git branch.
2. Start tmux:
   ```sh
   tmux
   ```
   A status bar appears at the bottom. Press `prefix ?` to open the help list. `prefix` means `Ctrl+Space`, pressed and released before the next key.
3. Start Neovim:
   ```sh
   nvim
   ```
   The first start installs plugins, then language tools. Wait until the messages stop, then quit with `:q`.

If any step fails, see [Troubleshooting](#troubleshooting).

## After installing

1. Put secrets and machine settings in `~/.zshrc.local`. It loads near the end of `.zshrc` and is not in the repo ([zsh.md](zsh.md)).
2. Put machine-only git settings, such as a work email or signing, in `~/.config/git/local` ([git.md](git.md)).
3. **macOS:** in iTerm, set the **Dotfiles** profile as the default ([terminals.md](terminals.md)).
4. Read [first-day.md](first-day.md) for the keys you'll use most.

## Update

Run this in the folder you cloned to:

```sh
cd ~/dotfiles && git pull && ./install.sh
```

The installer is safe to run again. It refreshes links, skips what is installed, and never upgrades. Upgrade Homebrew packages yourself with `brew upgrade`.

## Flags

```sh
./install.sh --dry-run                # print what would happen, change nothing
./install.sh --with-claude <git-url>  # also clone and install your own Claude config repo
./install.sh --help                   # usage
```

- **`--dry-run`** prints every action with a `[dry-run]` prefix. Use it first on a new machine.
- **`--with-claude <git-url>`** is for people who keep their own Claude Code config in a git repo. It clones that repo to `~/.config/claude-shared` and runs its `install.sh`. Set `CLAUDE_SHARED_DIR` to use another folder. A private GitHub repo needs SSH access.

You can combine flags: `--dry-run --with-claude <git-url>`. `--with-claude=<git-url>` works too.

## Undo or uninstall

Run these in the folder you cloned to. The installer only made [links](glossary.md#link) and renamed your old files, so undoing it is safe.

1. Remove the links. List the same packages the installer printed after "Linking packages":
   ```sh
   cd ~/dotfiles
   stow --delete --dir="$PWD" --target="$HOME" zsh nvim tmux vim git starship mise atuin bin theme
   ```
   **macOS:** add `iterm`. Add `ghostty` if Ghostty was installed.
2. Find the backups the installer made:
   ```sh
   find ~ -maxdepth 5 -name '*.backup-*' 2>/dev/null
   ```
3. Put back the files you want. For each one, remove the `.backup-<date>-<time>` part of the name:
   ```sh
   mv ~/.zshrc.backup-20260101-120000 ~/.zshrc
   ```
4. Remove what the installer added, if you no longer want it: tmux plugins in `~/.config/tmux/plugins`, and the Homebrew packages from the `Brewfile`.
5. Delete the clone folder.
6. Open a new terminal.

## Per-machine files

These files belong to one machine and are never in the repo.

| File | For |
| --- | --- |
| `~/.zshrc.local` | Secrets, paths, aliases ([zsh.md](zsh.md)) |
| `~/.config/git/local` | Name and email, work email, signing ([git.md](git.md)) |
| `~/.local/state/theme` | Saved light/dark mode ([theme.md](theme.md)) |
| `~/.config/ghostty/theme.conf` | Generated by `theme sync` ([theme.md](theme.md)) |
| `mise.local.toml` (per project) | Untracked project environment ([tools.md](tools.md)) |
| `~/.ssh/config` | SSH hosts ([server.md](server.md)) |

## Troubleshooting

- **"zsh was not found."** Install zsh with your package manager and run the installer again.
- **"Homebrew was not found."** Install it (see your OS above), open a new shell, and run the installer again.
- **stow reports a conflict.** A real file blocks a link. Find its path in the message, rename it, and run the installer again.
- **A tmux plugin is missing.** In tmux, press `prefix Shift+I`.
- **Icons look wrong.** Your terminal font is not a Nerd Font ([terminals.md](terminals.md)).
- **Colors did not change after `theme sync`.** See [theme.md](theme.md).
- **`--with-claude` says "no GitHub SSH access".** Forward or add your GitHub key as in [server.md](server.md), then run it again.

For more recovery steps, see [first-day.md](first-day.md#if-something-breaks).

## How it works

Each top-level folder of the repo is a [package](glossary.md#package) whose contents mirror your home folder. For example, `git/.config/git/config` becomes `~/.config/git/config`. [GNU Stow](https://www.gnu.org/software/stow/) creates the links.

### Packages

| Package | Links to | What it holds |
| --- | --- | --- |
| `zsh` | `~/.zshrc` | zsh: history, completion, aliases, fzf, atuin, zoxide, mise, starship, autosuggestions, syntax highlighting |
| `nvim` | `~/.config/nvim` | Neovim: lazy.nvim, LSP, treesitter, telescope, conform, blink.cmp |
| `tmux` | `~/.config/tmux/tmux.conf` | tmux with prefix `Ctrl+Space`, vi copy mode, plugins, status bar |
| `vim` | `~/.vimrc` | Small plugin-free vimrc for servers |
| `git` | `~/.config/git/{config,ignore}` | Git defaults, delta pager, aliases, global ignores |
| `starship` | `~/.config/starship.toml` | Two-line framed prompt |
| `atuin` | `~/.config/atuin/config.toml` | Shell history search, local only (no sync) |
| `mise` | `~/.config/mise/config.toml` | Global node (LTS) and go (latest) |
| `bin` | `~/.local/bin` | Scripts: `tmux-sessionizer`, `tmux-popup`, `theme`, `dotfiles-help`, `dotfiles-usage`, `dotfiles-log` |
| `theme` | `~/.config/theme/config` | The light/dark theme pair |
| `ghostty` | `~/.config/ghostty/config` | Ghostty terminal; linked only when Ghostty is installed |
| `iterm` | `~/.config/iterm/dotfiles-profile.plist` | iTerm2 profile template; macOS only |

### What `install.sh` does, in order

1. Checks that `zsh` exists. Without it, the script stops.
2. Runs `brew bundle --no-upgrade` to install what is missing. Without `brew`, it prints the install command and stops.
3. Picks the packages: the ten above, plus `iterm` on macOS and `ghostty` when Ghostty is installed.
4. Backs up an old standalone `~/.local/bin/mise` that would hide the Homebrew one.
5. Backs up every real file a package would replace, as `<file>.backup-YYYYmmdd-HHMMSS`. Links that already point into the repo stay. `~/.gitconfig` is backed up too, because git reads it before `~/.config/git/config`.
6. Links the packages with `stow --restow --no-folding`. Without `stow`, it makes plain links.
7. Runs `mise install` for the global runtimes.
8. On the first run only, imports `~/.zsh_history` into atuin. A failure only prints a warning.
9. Clones [TPM](glossary.md#tpm) into `~/.config/tmux/plugins/tpm` and installs the tmux plugins.
10. **Linux desktop:** installs the Monaspace Nerd Font into `~/.local/share/fonts`.
11. Runs `theme sync` to write the Ghostty and iTerm color files. A failure only prints a warning.
12. Runs the `--with-claude` step, if you asked for it.
13. Asks for your git name and email if none is set. A piped or `--dry-run` run prints the two commands instead.
14. Prints the next steps and, if zsh is not your login shell, the `chsh` command.

With `--dry-run`, steps 1 and 2 continue instead of stopping, so you see the whole plan.

### Why `--no-folding`

By default, stow links a whole folder when it can. `--no-folding` links each file on its own, so folders such as `~/.config/ghostty` stay real folders. Files that tools generate there, such as `theme.conf`, never land in the repo.

### The `--with-claude` step in detail

- If the target folder already holds a git repo, it is not pulled.
- Before cloning, the installer tests GitHub SSH access. Without access, it skips this step, finishes the rest, and exits with an error at the end.
- If the folder exists but is not a git repo, the step is skipped the same way.
- In `--dry-run`, it only prints that it would check access and clone.
- `.zshrc` loads `~/.config/claude-shared/zsh/claude.zsh` only if that file exists, so the dotfiles work without it.

## Related pages

- [first-day.md](first-day.md): the keys you'll use most.
- [server.md](server.md): full guide for a remote Ubuntu server.
- [terminals.md](terminals.md): fonts and terminal settings.
- [glossary.md](glossary.md): the terms these docs use.
