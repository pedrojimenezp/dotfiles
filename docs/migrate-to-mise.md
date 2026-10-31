# Move from Homebrew tools to mise

Older versions of these dotfiles installed the tools and zsh plugins with Homebrew (on Linux, one shared Homebrew). The current setup installs the tools with [mise](tools.md#mise), per user, and clones the zsh plugins with git. This page removes the Homebrew copies from a machine that ran the older install.

You'll use it once per machine, after you `git pull` and rerun `./install.sh`.

- [Before you remove anything](#before-you-remove-anything)
- [macOS](#macos)
- [Linux](#linux)
- [Existing server](#existing-server)
- [Check it worked](#check-it-worked)

## Before you remove anything

1. Update the dotfiles and rerun the installer. It installs the mise tools and clones the zsh plugins, and removes nothing:
   ```sh
   cd ~/dotfiles && git pull && ./install.sh
   ```
2. Clear the shell cache, which holds the old `PATH`, then open a new shell and check that each tool now comes from mise:
   ```sh
   rm -rf ~/.cache/zsh
   exec zsh
   which nvim tmux fzf rg
   ```
   Every path should be under `~/.local/share/mise` (a `shims` or `installs` folder), not `/opt/homebrew` or `/home/linuxbrew`. If one is not, stop: run `mise install`, open a new shell and check again before removing it.
3. Quit tmux first (`tmux kill-server`, which ends its sessions; continuum restores the last save). The running server is still the old Homebrew tmux until you do.

## macOS

The `Brewfile` holds only `mise`, `stow`, `btop` and the casks. Uninstall the formulae that moved:

```sh
brew uninstall neovim tmux tmux-fingers starship fzf zoxide eza bat ripgrep fd jq yq tealdeer hyperfine atuin git-delta lazygit lazydocker dive gh git-lfs shellcheck shfmt tree-sitter-cli golangci-lint zig zls zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab
brew autoremove
```

Notes:

- `brew uninstall` refuses a formula that another formula needs. Leave that one in place (it does no harm: mise comes first on `PATH`) or uninstall the dependent one too.
- `btop` stays in Homebrew because mise has no macOS build of it.
- Run `exec zsh` in every tab and pane that was open. Otherwise the old shell prints `zsh: no such file or directory: .../bin/starship`, because it still has the old starship path.
- To preview what the shorter `Brewfile` would remove, run `brew bundle cleanup --file=Brewfile`. Without `--force` it only lists. **Do not add `--force`:** it removes every formula that is not in the `Brewfile`, including ones you installed yourself outside these dotfiles.

## Linux

The old install put everything in one shared Homebrew at `/home/linuxbrew/.linuxbrew`, owned by one user. Remove it only after every user of the machine has rerun `./install.sh` and checked their tools as above, because the other users' old tools may still point there.

1. **The Homebrew owner** (the user who installed it) runs Homebrew's uninstall script:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   ```
   It lists what it will remove and asks before it does anything.
2. **The admin** removes what is left of the shared folder (the script cannot delete the `/home/linuxbrew` folder itself):
   ```sh
   sudo rm -rf /home/linuxbrew
   ```
3. **Each user** removes any `brew shellenv` line they added to their own files, such as `~/.zshrc.local`, `~/.zprofile` or `~/.bashrc`. Look for them with:
   ```sh
   grep -n "linuxbrew" ~/.zshrc.local ~/.zprofile ~/.zshenv ~/.bashrc ~/.profile 2>/dev/null
   ```
   The dotfiles' own `.zshrc` needs no change: it looks for `brew` and carries on without it.
4. The old zsh plugins (autosuggestions, syntax highlighting, completions, fzf-tab) came from Homebrew. They now come from `~/.local/share/zsh-plugins`, which `install.sh` clones for each user, so nothing is left to do for them.
5. Run `exec zsh` in every tab and pane that was open, or the prompt prints `zsh: no such file or directory: .../bin/starship` (the old shell keeps the old starship path).

## Existing server

A Linux server that ran the old Homebrew install, possibly with several users: an admin with sudo (for example `ubuntu`, who owns `/home/linuxbrew/.linuxbrew`) and other users without it. Do the steps in this order.

Connect with plain `ssh`, not `tssh`. `tssh` runs inside the remote tmux, and `tmux kill-server` would end the connection you are typing in.

1. **Admin:** install the system packages ([server.md](server.md#7-several-users)):
   ```sh
   sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1
   ```
2. **Admin:** update your own setup, then follow [Before you remove anything](#before-you-remove-anything):
   ```sh
   cd ~/dotfiles && git pull && ./install.sh
   ```
3. **Each other user:** the admin sets zsh as their shell if needed (`sudo chsh -s /usr/bin/zsh <name>`). The user then pulls (or clones, the first time) and runs `./install.sh`, then does the same checks. On the first login zsh may show a setup menu: the user presses `q` ([details](server.md#7-several-users)).
4. **Only after every user is done,** remove Homebrew as described in [Linux](#linux).

## Check it worked

1. Open a new shell: `exec zsh`.
2. List the mise tools. Each line should show a version, not `(missing)`:
   ```sh
   mise ls
   ```
3. Check where a few tools come from:
   ```sh
   which nvim tmux fzf rg starship
   ```
   All under `~/.local/share/mise`.
4. Check the plugins: `ls ~/.local/share/zsh-plugins` shows four folders, and typing a command shows grey suggestions and colors.
5. **Linux:** `command -v brew` prints nothing.
6. Start `tmux` and `nvim` once. If something is missing, run `mise install`.

## Related pages

- [install.md](install.md): what `install.sh` does.
- [server.md](server.md#7-several-users): one server, several users.
- [tools.md](tools.md#mise): how mise is set up here.
