# Install

How to install these [dotfiles](glossary.md#dotfiles) on macOS or a Linux desktop, and how to update or remove them. You'll use it once per machine, then again to update.

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
- **Nothing is deleted.** The installer renames any file it would replace to `<file>.backup-<date>-<time>`. `./uninstall.sh` puts them back. See [Undo or uninstall](#undo-or-uninstall).
- **No sudo.** `install.sh` never uses sudo and never upgrades your tools. On Linux an admin installs a few system packages once; every user then installs their own tools into their home with [mise](tools.md#mise).

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
   sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1 xz-utils
   ```
   `xz-utils` unpacks the [Nerd Font](glossary.md#nerd-font). `install.sh` checks these and prints the exact `apt-get` line for anything missing, so the script is the source of truth. It needs no Homebrew: it installs [mise](tools.md#mise) into `~/.local/bin` and then every tool into your home.
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

The installer is safe to run again. It refreshes links, installs what is missing and fast-forwards the zsh plugins, but never upgrades your tools. Upgrade them yourself:

1. The tools in the mise config:
   ```sh
   mise outdated   # list what has a newer version
   mise upgrade    # install the newer versions
   ```
2. mise itself.

   **macOS** (mise comes from Homebrew):
   ```sh
   brew upgrade mise
   ```
   A plain `brew upgrade` also upgrades `stow`, `btop` and the apps, and every other Homebrew package you have.

   **Linux** (mise lives in `~/.local/bin`):
   ```sh
   mise self-update
   ```
3. Open a new shell. The tool cache refreshes by itself when a tool's version changes ([zsh.md](zsh.md#how-it-works)).

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

`uninstall.sh` puts the machine back as it was before `install.sh`. It works on macOS, Linux desktops and Linux servers, uses only tools every one of them has, and never uses sudo.

```sh
cd ~/dotfiles
./uninstall.sh --dry-run   # show the plan, change nothing
./uninstall.sh             # show the plan, ask "Continue? [y/N]", then do it
```

Flags:

| Flag | What it does |
| --- | --- |
| `--dry-run` | Print the plan and every command, change nothing. |
| `--yes` | Skip the "Continue?" question. |
| `--with-claude` | Also undo your Claude config (see below). Kept by default. |
| `--keep-repo` | Keep this clone. |

What it does, in order:

1. **Links.** Removes only [links](glossary.md#link) that point into this repo (`stow --delete`, then a sweep for the plain-symlink fallback). A real file is never deleted.
2. **Backups.** For each removed link, it puts back the newest `<file>.backup-<date>-<time>` if the path is free. It does the same for `~/.gitconfig` and `~/.local/bin/mise`. Older backups stay; the summary lists them.
3. **Generated data.** Deletes what the installer and the tools created: `~/.local/bin/mise` and mise's data, state and cache; the zsh plugins and zsh cache; the tmux plugins; atuin's data (the imported history, not `~/.zsh_history`); Neovim's data, state and cache; zoxide, lazygit and starship data; `~/.config/git/local` (your git name and email); the files `theme sync` generated (including the Ghostty theme files and, on macOS, the iTerm profile); and on a Linux desktop the Nerd Font in `~/.local/share/fonts`. Every delete refuses a path outside `$HOME`.
4. **Claude config** (only with `--with-claude`). Removes the links its own installer made in `~/.claude`, `~/.claude-personal` and `~/.pi/agent`, restores their `.bak-*` files, removes its line from `~/.zshrc.local`, then deletes `~/.config/claude-shared`. The `settings.json` copies in the two Claude folders stay (Claude Code writes them too).
5. **This clone**, last. If it has uncommitted changes or commits that are not on a remote branch, it is kept and the script says why.
6. **Final sweep.** Once the clone is deleted, it removes any link that is now broken and pointed into the clone, in the same places it scanned at the start. Skipped when the clone is kept.

It never uninstalls Homebrew packages (on macOS it prints the `brew uninstall` lines for the `Brewfile`), never changes your login shell (it prints the `chsh -s /bin/bash` line, and a `sudo chsh` variant, when the shell is zsh) and never starts or stops tmux. Open a new terminal afterwards.

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
