# Remote Ubuntu dev server

A step-by-step guide to set up an Ubuntu server (22.04 or 24.04, for example an EC2 instance) with these dotfiles and work on it over SSH. This page is the only home for server setup; [install.md](install.md) covers macOS and Linux desktops and the installer reference.

Every command says where it runs: "On your laptop" or "On the server". Your laptop can be a Mac or a Linux machine. Where a step is different, it is marked **macOS** or **Linux**. If a step has no mark, it is the same on both.

- [1. What you get](#1-what-you-get)
- [2. On your laptop, once](#2-on-your-laptop-once)
- [3. On the server, once](#3-on-the-server-once)
- [4. Name this server](#4-name-this-server)
- [5. Daily use](#5-daily-use)
- [6. Updating the server later](#6-updating-the-server-later)
- [7. Several users](#7-several-users)
- [8. Troubleshooting](#8-troubleshooting)

## 1. What you get

- The same dev environment as your laptop: zsh, nvim, tmux, mise and Claude Code.
- tmux runs on the server. If your laptop disconnects or sleeps, your work keeps running.
- tmux continuum saves your [sessions](glossary.md#session) every 15 minutes. After a server reboot, run `tssh my-ec2` and they come back.

## 2. On your laptop, once

Add a host entry to `~/.ssh/config`. Replace the placeholders:

```
Host my-ec2
  HostName <server address>
  User ubuntu
  IdentityFile <path to your key, e.g. ~/.ssh/my-ec2.pem>
  ForwardAgent yes
```

`ForwardAgent yes` lets the server use your laptop's GitHub key without copying the key to the server. You need it for a private `--with-claude` repo and for `git push` from the server.

Security trade-off: while you are connected, anyone with root on the server can use your forwarded keys. Only enable it for servers you trust.

You do not need `SetEnv TERM=...` or `RequestTTY` in the entry. Ghostty's ssh-terminfo ([terminals.md](terminals.md#how-it-works)) and `tssh -t` already cover them.

### Optional: faster, steadier SSH

Keep `~/.ssh/config` out of this repo (it is private). These settings help for every host:

```sshconfig
# ~/.ssh/config (example, not stowed)
Host *
  # Reuse one connection for many sessions
  ControlMaster auto
  # Socket file for the shared connection
  ControlPath ~/.ssh/cm-%r@%h:%p
  # Keep it open 10 minutes after the last use
  ControlPersist 10m
  # Keepalive so idle sessions do not drop
  ServerAliveInterval 30
```

For flaky networks, install `mosh` (`sudo apt-get install -y mosh` on the server, and on your Mac uncomment it in the `Brewfile`): `mosh myserver` survives sleep and IP changes. Run tmux inside it.

### Share your GitHub key with the server

Why: on your laptop, `ssh` can read a key file directly, so GitHub works even if the key is not in the agent. But `ForwardAgent` only shares keys that are loaded in the agent. If the key is not loaded, the server gets "Permission denied (publickey)" even though GitHub works on your laptop. `gh auth login` does not help here: it sets up https tokens, and `ssh -T` only uses SSH keys.

1. On your laptop (macOS and Linux), find which key GitHub uses:
   ```sh
   ssh -vT git@github.com 2>&1 | grep -E "Offering public key|Authenticated to"
   ```
   The path printed right before "Authenticated to github.com" is your GitHub key. Only file names are printed, never the key itself.
2. On your laptop, load that key into the agent. Use your own path.

   **macOS only:**
   ```sh
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```
   It asks for the passphrase once and saves it in the macOS Keychain.

   **Linux:**
   ```sh
   ssh-add ~/.ssh/id_ed25519
   ```
   Most Linux desktops (GNOME Keyring, ssh-agent) start an agent for you. If `ssh-add -l` says it cannot connect to the agent, start one first, then run `ssh-add` again:
   ```sh
   eval "$(ssh-agent -s)"
   ```
3. On your laptop, keep the key loaded after a reboot. Add this at the END of `~/.ssh/config`. `UseKeychain` only exists on macOS. On Linux it is an error ("Bad configuration option: usekeychain"), so use the Linux block there.

   **macOS only:**
   ```
   Host *
     AddKeysToAgent yes
     UseKeychain yes
   ```
   **Linux:**
   ```
   Host *
     AddKeysToAgent yes
   ```
   On Linux, `AddKeysToAgent yes` loads the key into the agent the first time you use it in a session. You type the passphrase once per login.
4. On your laptop, check that the agent lists the key:
   ```sh
   ssh-add -l
   ```
5. On the server, after you connect with `ForwardAgent yes` (section 3), check two things:
   ```sh
   echo $SSH_AUTH_SOCK
   ssh -T git@github.com
   ```
   The first prints a path (forwarding works). The second says "Hi <your-user>! You've successfully authenticated".

## 3. On the server, once

The first run takes a few minutes.

On your laptop, connect:

```sh
ssh my-ec2
```

On the server, install the system packages (the only step that needs sudo besides `chsh`):

```sh
sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1
```

No Homebrew is needed. `install.sh` installs [mise](tools.md#mise) into `~/.local/bin` and then every tool into your own home, so a user without sudo can do it too ([section 7](#7-several-users)).

On the server, clone the dotfiles and install them:

```sh
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh --with-claude <git-url>
```

Use `./install.sh` without `--with-claude <git-url>` if the server has no GitHub access (no forwarded key). Everything else (mise, tools, plugins, `git pull`) uses https and needs no key; only a private `--with-claude` repo and `git push` need SSH.

The installer skips the Nerd Font on a server: your laptop's terminal draws the icons. If zsh is missing or is not your login shell, `install.sh` prints the exact command to run. Flags and every step it takes are in [install.md](install.md#flags).

On the server, make zsh your login shell (EC2 users have no password, so use sudo):

```sh
sudo chsh -s /usr/bin/zsh "$USER"
```

On the server, install Claude Code:

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

On the server, log out:

```sh
exit
```

Then finish the setup:

1. On your laptop, log in again: `ssh my-ec2`. You are now in zsh.
2. On the server, put your secrets in `~/.zshrc.local` (it loads near the end, after all other settings, and is not tracked by git), then lock it:
   ```sh
   chmod 600 ~/.zshrc.local
   ```
3. On the server, name this machine and set its time zone (both optional), as in [section 4](#4-name-this-server).
4. On the server, run `claude` once and log in.
5. On the server, inside a project that pins other tool versions, run:
   ```sh
   mise install
   ```
6. On the server, type `exit` to go back to your laptop.

## 4. Name this server

Optional. EC2 hostnames look like `ip-172-32-4-187`. Give the server a name you recognize instead.

On the server, add one line to `~/.zshrc.local`:

```sh
export HOST_LABEL=bravo.example.com
```

Where the name shows, over SSH only (without `HOST_LABEL`, both show the short hostname):

- **The starship prompt**: `user@host` after the OS icon, in bold purple. See [tools.md](tools.md#prompt-starship).
- **The tmux SSH badge**: the red **SSH** block `user@host` at the left of the status bar. See [tmux.md](tmux.md#status-bar-and-pane-labels).

It only affects your user, so it is safe on a shared box. Open a new shell and the prompt shows it.

tmux reads `HOST_LABEL` when its server starts, so a tmux that is already running keeps the old name. Either:

- **Update the running tmux**, on the server:
  ```sh
  tmux set-environment -g HOST_LABEL "$HOST_LABEL"   # a later reload reads the new name
  tmux set -g @host_label "$HOST_LABEL"              # the badge changes within 5 seconds
  ```
  Then reload with `prefix r` (or `tmux source-file ~/.config/tmux/tmux.conf`).
- **Or restart tmux**: `tmux kill-server`, then `tssh my-ec2`. This ends its sessions; continuum restores the last save.

**A name for tmux only.** The untracked `~/.config/tmux/local.conf` (not part of the dotfiles; tmux loads it if present) overrides the badge:

```tmux
set -g @host_label "dev-box"
```

Reload with `prefix r`. `local.conf` loads after the status settings, so it wins over `HOST_LABEL`.

### Set the time zone

Optional. A new EC2 server uses UTC. On the server, add one line to `~/.zshrc.local`:

```sh
export TZ=America/Bogota
```

The shell and the tools it starts, such as `date` and the prompt, then show that zone. Any IANA name works: `ls /usr/share/zoneinfo` or `timedatectl list-timezones` lists them. Like `HOST_LABEL`, it only affects your user (no sudo), so it is safe on a shared box. Open a new shell to see it.

The tmux status bar clock reads `TZ` only when the tmux server starts. In a running tmux, `tmux set-environment -g TZ "$TZ"` changes new panes and windows, but not the clock. To change the clock, restart tmux: `tmux kill-server`, then `tssh my-ec2`. This ends its sessions; continuum restores the last save.

## 5. Daily use

1. On your laptop, open a new terminal tab. On macOS press `Cmd+T`. On Linux press `Ctrl+Shift+T` (the default in Ghostty and most Linux terminals; if it does not work, use your terminal's new-tab shortcut).
2. On your laptop, run:
   ```sh
   tssh my-ec2
   ```
   `tssh` connects and attaches to the tmux session `main` (it creates it if needed).
3. Look at the status bar. A red **SSH** badge with the server name at the left of the bar means you are on the server (the session block after it is blue, yellow while the prefix is pressed).

Rules:

- Use one tab per server.
- Never run `tssh` inside a local tmux. No tmux inside tmux.
- Switch between tabs. On macOS use `Cmd+1`, `Cmd+2`, and so on. On Linux use `Alt+1`, `Alt+2`, and so on, or `Ctrl+PageUp` and `Ctrl+PageDown` (Ghostty defaults; other terminals may differ).
- To leave, press `Ctrl+Space`, then `d` (detach). Or close the tab. Everything keeps running on the server, and the SSH connection ends with it.
- For a shell on the server without tmux (for example to run `tmux kill-server`), use plain `ssh my-ec2`.
- To come back, open a tab and run `tssh my-ec2` again.
- To show Claude Code on the server a screenshot, copy the image and press `Cmd+V` in the `tssh` tab: it uploads the image and types its path. **iTerm2 only**, not Ghostty. See [terminals.md](terminals.md#paste-an-image-to-a-server-iterm2-only).

## 6. Updating the server later

On the server:

```sh
cd ~/dotfiles && git pull && ./install.sh
```

`install.sh` is safe to run again, but it never upgrades tools. To upgrade them and mise itself (`mise upgrade`, then `mise self-update`), follow [Update](install.md#update).

If this server ran the older Brew-based install, see [migrate-to-mise.md](migrate-to-mise.md#linux) to remove Homebrew.

## 7. Several users

Several people can share one server. Each user has their own home, their own tools and their own copy of the dotfiles. Only the system packages are shared, so only the admin needs sudo.

**Admin, once** (a user with sudo):

```sh
sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1
```

**Admin, for each new user:**

```sh
sudo adduser <name>
sudo chsh -s /usr/bin/zsh <name>
```

**Each user** (no sudo needed), logged in as themselves.

On the first login, zsh may show a menu that starts with "This is the Z Shell configuration function for new users". Press `q`. It creates nothing and shows again at the next login until `install.sh` has run. If you pressed `0`, `1` or `2`, no harm: `install.sh` moves that `~/.zshrc` to `~/.zshrc.backup-<date>-<time>` (same folder), links the dotfiles' `.zshrc`, and the menu does not return.

Then:

```sh
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

Moving a server that ran the old Homebrew install? Follow the [Existing server checklist](migrate-to-mise.md#existing-server).

If a package is missing, `install.sh` stops and prints the `apt-get` line for the admin. It never uses sudo.

**Upgrades.** Each user upgrades their own dotfiles, tools and mise as in [section 6](#6-updating-the-server-later). The admin upgrades the system packages with `sudo apt-get upgrade`.

**Good to know:**

- Tools live in `~/.local/share/mise` and `~/.local/bin/mise`, about 1.3 GB per user with all the tools.
- tmux comes from mise (apt's tmux is older than 3.5), so each user runs their own tmux and server. A user's sessions are private.
- Everyone's `~/.zshrc.local`, git identity and `HOST_LABEL` are separate.

## 8. Troubleshooting

- **A menu says "This is the Z Shell configuration function for new users".** zsh is your login shell but you have no `~/.zshrc` yet. Press `q`, then clone the dotfiles and run `./install.sh` (section 7). Any `~/.zshrc` the menu created is moved to `~/.zshrc.backup-<date>-<time>`.
- **`tssh` says tmux not found.** Your login shell is not zsh. On the server, run the `chsh` step from section 3, then log out and in.
- **tmux shows errors about unknown options right after login, or the install ended with "logins start the system tmux".** Your login shell is still bash, which does not put mise's tools on `PATH`, so logins start Ubuntu's older `/usr/bin/tmux` (tmux.conf needs 3.5+). Run the `chsh` step from section 3, log out and in, then stop the old server with `tmux kill-server` (this ends its sessions).
- **GitHub clone asks for a password, or "permission denied".** Follow "Share your GitHub key with the server" in section 2, then reconnect.
- **`--with-claude <git-url>` says "no GitHub SSH access on this machine" and exits with an error.** The installer tested `ssh git@github.com` and GitHub did not accept a key. It skips the Claude step and finishes the rest. Fix the forwarding as in the item above, reconnect, then run `./install.sh --with-claude <git-url>` again.
- **`git pull` says "Permission denied (publickey)".** An older copy of the git config sends all GitHub traffic over SSH. Run `git pull` in the dotfiles clone, or run `./install.sh` again, to get the current config, which sends only pushes over SSH.
- **`git push` or a private `--with-claude` repo says "Permission denied (publickey)", and `echo $SSH_AUTH_SOCK` on the server prints a path.** Forwarding works, but the key is not in your laptop's agent. Do steps 2-4 of "Share your GitHub key with the server" in section 2.
- **Same error, and `echo $SSH_AUTH_SOCK` on the server prints nothing.** Forwarding is off. Add `ForwardAgent yes` to the host entry (section 2), then reconnect.
- **Colors or icons look wrong.** This is your laptop's terminal font or profile, not the server. The server sends text only; your laptop's terminal draws the icons. On macOS, check the terminal profile (for example iTerm) uses the Nerd Font. On Linux, the Nerd Font must be installed on the laptop (`install.sh` does this on Linux desktops; run `fc-cache -f` and restart the terminal) and selected in your terminal.

## Related pages

- [install.md](install.md): what `install.sh` does, flags, and how to undo it.
- [migrate-to-mise.md](migrate-to-mise.md): remove the old shared Homebrew.
- [first-day.md](first-day.md): the keys you'll use most.
- [tmux.md](tmux.md): every tmux key and the status bar.
- [zsh.md](zsh.md#remote-tmux-tssh): the `tssh` function.
- [terminals.md](terminals.md): your laptop's terminal, its Nerd Font, and pasting images to the server (iTerm2).
- [vim.md](vim.md): the plugin-free Vim for servers without Neovim.
