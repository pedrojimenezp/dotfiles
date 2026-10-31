# Install

How to install these [dotfiles](glossary.md#dotfiles) on macOS or a Linux desktop, and how to update or remove them. You'll use it once per machine, then again to update.

- [Before you start](#before-you-start)
- [macOS](#macos)
- [Linux desktop](#linux-desktop)
- [Ubuntu server](#ubuntu-server)
- [Check it worked](#check-it-worked)
- [After installing](#after-installing)
- [Update](#update)
- [Move an older Brew-based install to mise](migrate-to-mise.md)
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
- **No sudo.** `install.sh` never uses sudo and never upgrades what you already have. On Linux an admin installs a few system packages once; every user then installs their own tools into their home with [mise](tools.md#mise).

## macOS

1. Install Apple's command-line tools (git and compilers), if you don't have them yet:
   ```sh
   xcode-select --install
   ```
2. Install [Homebrew](https://brew.sh) if `brew` is missing. The installer looks in the standard prefixes (`/opt/homebrew`, `/usr/local`) first; if it finds none, it prints the install command and stops. Homebrew only installs `mise`, `stow`, `btop` and the apps; mise installs the other tools.
3. Clone the repo and run the installer:
   ```sh
   git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

Apps go into `~/Applications`, so you need no admin rights.

## Linux desktop

1. Install the system packages (once per machine; use sudo if your system needs it). On Ubuntu or Debian:
   ```sh
   sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1
   ```
   If one is missing, the installer stops and prints this line with the missing names. It needs no Homebrew: it installs [mise](tools.md#mise) into `~/.local/bin` and then every tool into your home.
2. Clone the repo and run the installer:
   ```sh
   git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```
3. Make zsh your login shell, then log out and in. The installer prints the right command at the end. On most systems:
   ```sh
   chsh -s "$(command -v zsh)"
   ```
   **Linux (Ubuntu):** use `sudo chsh -s /usr/bin/zsh "$USER"`.

Ghostty is not installed on Linux. Install it from your distro if you want it; the installer links its config when the `ghostty` command exists. The [Nerd Font](glossary.md#nerd-font) is installed for you on desktops.

## Ubuntu server

Follow [server.md](server.md): SSH setup on your laptop, the install steps on the server, and daily use.

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

The installer is safe to run again. It refreshes links, skips what is installed, and never upgrades. Upgrade the tools with `mise upgrade`, and on macOS the Homebrew packages with `brew upgrade`.

Already ran the older Brew-based install? See [migrate-to-mise.md](migrate-to-mise.md) to remove the Homebrew copies of the tools that moved.

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
   stow --delete --dir="$PWD" --target="$HOME" zsh nvim tmux vim git lazygit starship mise atuin bin theme
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
4. Remove what the installer added, if you no longer want it: tmux plugins in `~/.config/tmux/plugins`, the zsh plugins in `~/.local/share/zsh-plugins`, the tools in `~/.local/share/mise` (`mise implode` removes mise and everything it installed), and on macOS the Homebrew packages from the `Brewfile`.
5. Delete the clone folder.
6. Open a new terminal.

### Restore one file

To get back a single file without undoing the rest, for example `~/.zshrc`:

1. Find its backups:
   ```sh
   ls ~/.zshrc.backup-*
   ```
2. Remove the [link](glossary.md#link) and put the backup back. Use the name the first step printed:
   ```sh
   rm ~/.zshrc
   mv ~/.zshrc.backup-20260101-120000 ~/.zshrc
   ```
3. Open a new shell to load it: `exec zsh`.

A later `./install.sh` backs it up again and puts the link back.

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

`install.sh` prints every step to the terminal and keeps no log file. Run `./install.sh --dry-run` to see what it would do.

- **"Missing: ..."** (Linux). Run the `sudo apt-get install` line it prints, or ask your admin to, then run the installer again.
- **"Homebrew was not found."** (macOS) Install it (see above), open a new shell, and run the installer again.
- **"some mise tools failed".** Run `mise install` to see which one and why (often a network error), then run it again.
- **`zsh compinit: insecure directories` prompt.** A completion folder (on macOS often `$(brew --prefix)/share`) is writable by group or others. On macOS `install.sh` runs `chmod go-w` on Homebrew's folders, and `.zshrc` skips the prompt when you or root own every insecure path. Brew can restore the permissions: run `compaudit`, then `chmod go-w` on each path it lists. A path owned by another user still prompts: check it first.
- **stow reports a conflict.** A real file blocks a link. Find its path in the message, rename it, and run the installer again.
- **A tmux plugin is missing.** The installer says so when the plugin install failed. In tmux, press `prefix Shift+I`.
- **Icons look wrong.** Your terminal font is not a Nerd Font ([terminals.md](terminals.md)).
- **Colors did not change after `theme sync`.** See [theme.md](theme.md).
- **`--with-claude` says "no GitHub SSH access".** Forward or add your GitHub key as in [server.md](server.md#share-your-github-key-with-the-server), then run it again.

For more recovery steps, see [first-day.md](first-day.md#if-something-breaks).

## How it works

Each top-level folder of the repo is a [package](glossary.md#package) whose contents mirror your home folder. For example, `git/.config/git/config` becomes `~/.config/git/config`. [GNU Stow](https://www.gnu.org/software/stow/) creates the links.

### Packages

| Package | Links to | What it holds |
| --- | --- | --- |
| `zsh` | `~/.zshrc` | zsh: history, completion, aliases, fzf, atuin, zoxide, mise, starship, autosuggestions, syntax highlighting (the plugins are git clones) |
| `nvim` | `~/.config/nvim` | Neovim: lazy.nvim, LSP, treesitter, telescope, conform, blink.cmp |
| `tmux` | `~/.config/tmux/tmux.conf` | tmux with prefix `Ctrl+Space`, vi copy mode, plugins, status bar |
| `vim` | `~/.vimrc` | Small plugin-free vimrc for servers |
| `git` | `~/.config/git/{config,ignore}` | Git defaults, delta pager, aliases, global ignores |
| `lazygit` | `~/.config/lazygit/config.yml` | lazygit renders diffs with delta; `.zshrc` sets `LG_CONFIG_FILE` so macOS reads it too |
| `starship` | `~/.config/starship.toml` | Two-line framed prompt |
| `atuin` | `~/.config/atuin/config.toml` | Shell history search, local only (no sync) |
| `mise` | `~/.config/mise/config.toml` | Global tools: node, go and the CLI tools of [tools.md](tools.md) |
| `bin` | `~/.local/bin` | Scripts: `tmux-sessionizer`, `tmux-new-session`, `tmux-popup`, `theme`, `dotfiles-help`, `dotfiles-usage`, `dotfiles-log` |
| `theme` | `~/.config/theme/config` | The light/dark theme pair |
| `ghostty` | `~/.config/ghostty/config` | Ghostty terminal; linked only when Ghostty is installed |
| `iterm` | `~/.config/iterm/dotfiles-profile.plist` | iTerm2 profile template; macOS only |

### What `install.sh` does, in order

1. Checks the system packages. `zsh` is always needed; Linux also needs `git`, `curl`, `unzip`, `stow` and `libatomic1` (and `xz` on a desktop). Anything missing stops the script, which prints the `apt-get` line for an admin.
2. **macOS:** runs `brew bundle --no-upgrade` to install what is missing (`mise`, `stow`, `btop`, the apps), then `chmod go-w` on Homebrew's zsh completion folders. `brew` is found in the standard prefixes even when it is not on `PATH`. Without it, the script prints the install command and stops. Linux skips this step.
3. Picks the packages: the first eleven above, plus `iterm` on macOS and `ghostty` when Ghostty is installed.
4. Backs up an old standalone `~/.local/bin/mise` that would hide the Homebrew one (macOS).
5. Backs up every real file a package would replace, as `<file>.backup-YYYYmmdd-HHMMSS`. Links that already point into the repo stay. `~/.gitconfig` is backed up too, because git reads it before `~/.config/git/config`.
6. Links the packages with `stow --restow --no-folding`. Without `stow`, it makes plain links.
7. Installs mise into `~/.local/bin` if it is missing (the official installer from `https://mise.run`), runs `mise install` for every tool in the config, and puts those tools on `PATH` for the rest of the script. A failure only prints a warning.
8. Clones the zsh plugins (autosuggestions, syntax-highlighting, completions, fzf-tab) into `~/.local/share/zsh-plugins`, or fast-forwards the ones already there.
9. On the first run only (no atuin database yet), imports `~/.zsh_history` (or `$HISTFILE`) into atuin. With no zsh history yet it skips the import, so a later run imports once history exists. A failure only prints a warning.
10. Clones [TPM](glossary.md#tpm) into `~/.config/tmux/plugins/tpm` and installs the tmux plugins. TPM needs a tmux server that has loaded the config, so this runs on a private, throwaway tmux server. It never touches a tmux you already have running, and works even when the installer runs inside tmux.
11. **Linux desktop:** installs the Monaspace Nerd Font into `~/.local/share/fonts`.
12. Runs `theme sync` to write the Ghostty and iTerm color files. A failure only prints a warning.
13. Runs the `--with-claude` step, if you asked for it.
14. Asks for your git name and email if none is set. A piped or `--dry-run` run prints the two commands instead.
15. Prints the next steps (it says so when the tmux plugin install failed) and, if zsh is not your login shell, the `chsh` command. When `/usr/bin/tmux` is also older than 3.5, it warns that logins start that system tmux until you switch (bash does not put mise's tools on `PATH`), and tells you to run `tmux kill-server` after switching.

With `--dry-run`, a failed step 1 or 2 continues instead of stopping, so you see the whole plan.

### Why `--no-folding`

By default, stow links a whole folder when it can. `--no-folding` links each file on its own, so folders such as `~/.config/ghostty` stay real folders. Files that tools generate there, such as `theme.conf`, never land in the repo.

### The `--with-claude` step in detail

- If the target folder already holds a git repo, it is updated with `git pull --rebase --autostash`. When the pull fails (no GitHub SSH access, conflicts), a warning is printed, the clone stays as it is, and its `install.sh` still runs.
- Before cloning, the installer tests GitHub SSH access. Without access, it skips this step, finishes the rest, and exits with an error at the end.
- If the folder exists but is not a git repo, the step is skipped the same way.
- In `--dry-run`, it only prints that it would check access and clone or pull.
- `.zshrc` loads `~/.config/claude-shared/zsh/claude.zsh` only if that file exists, so the dotfiles work without it.

## Related pages

- [first-day.md](first-day.md): the keys you'll use most.
- [server.md](server.md): full guide for a remote Ubuntu server.
- [terminals.md](terminals.md): fonts and terminal settings.
- [glossary.md](glossary.md): the terms these docs use.
