# Remote Ubuntu server

Set up an Ubuntu 22.04/24.04 server (for example EC2) and work on it over SSH. tmux runs on the server, so work survives a disconnect, and continuum restores sessions after a reboot.

## 1. On the laptop, once

Add a host to `~/.ssh/config` (not in this repo):

```
Host my-ec2
  HostName <server address>
  User ubuntu
  IdentityFile ~/.ssh/my-ec2.pem
  ForwardAgent yes
```

`ForwardAgent` lets the server use the laptop's GitHub key for `git push` and a private `--with-claude` repo. Anyone with root on the server can use the forwarded keys while you're connected: only trusted servers. No `SetEnv TERM` or `RequestTTY` needed: `tssh -t` and the terminfo step cover them.

Optional, for every host:

```sshconfig
Host *
  ControlMaster auto
  ControlPath ~/.ssh/cm-%r@%h:%p
  ControlPersist 10m
  ServerAliveInterval 30
```

A shared connection keeps what the server read at login: after a `chsh` or a new group, run `ssh -O exit <user>@<host>` on the laptop and reconnect. For flaky networks, `mosh` survives sleep and IP changes; run tmux inside it.

### Share the GitHub key

`ForwardAgent` shares only keys loaded in the agent. Locally `ssh` reads the key file directly, so GitHub works on the laptop but the server gets "Permission denied (publickey)". `gh auth login` doesn't help: it sets up HTTPS tokens.

1. Find the key GitHub uses (the path printed before "Authenticated to"):
   ```sh
   ssh -vT git@github.com 2>&1 | grep -E "Offering public key|Authenticated to"
   ```
2. Load it. **macOS:** `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`. **Linux:** `ssh-add ~/.ssh/id_ed25519` (if it can't reach an agent, `eval "$(ssh-agent -s)"` first).
3. Keep it loaded: add at the end of `~/.ssh/config`:
   ```
   Host *
     AddKeysToAgent yes
     UseKeychain yes
   ```
   Drop `UseKeychain` on Linux: it's a "Bad configuration option" there.
4. Check with `ssh-add -l`, then on the server: `echo $SSH_AUTH_SOCK` prints a path and `ssh -T git@github.com` says "Hi".

## 2. On the server, once

```sh
ssh my-ec2
sudo apt-get update && sudo apt-get install -y zsh git curl unzip stow libatomic1
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh --with-claude <git-url>
sudo chsh -s /usr/bin/zsh "$USER"
exit
```

- `install.sh` prints the `apt-get` line for anything missing. No Homebrew; mise installs every tool into the home folder.
- Without a forwarded key, drop `--with-claude`: everything else uses HTTPS.
- No Nerd Font on a server: the laptop's terminal draws the icons.
- `sudo chsh` because EC2 users have no password.
- Claude Code itself: the "New machine" section of the [Claude config repo](https://github.com/pedrojimenezp/claude-config#new-machine).

Then:

1. **Ghostty terminfo** (once per server and user; skip for iTerm2 only). Ghostty sends `TERM=xterm-ghostty`; without the entry, tmux, nvim, less and backspace misbehave. In a Ghostty tab on the laptop (`infocmp` finds it through Ghostty's `TERMINFO`):
   ```sh
   infocmp -x xterm-ghostty | ssh <user>@<host> -- tic -x -
   ssh <user>@<host> 'infocmp xterm-ghostty >/dev/null && echo ok'
   ```
   A user you `sudo -iu` into needs it too. For all users: `... | ssh <user>@<host> -- sudo tic -x -o /usr/share/terminfo -`.
2. Secrets in `~/.zshrc.local`, then `chmod 600 ~/.zshrc.local`.
3. Optional: [name the server](#4-name-this-server) and set `TZ`.

## 3. Daily use

`tssh my-ec2` in a new tab connects and attaches to the tmux session `main`. The red **SSH** badge means you're on the server.

- One tab per server. Never `tssh` from inside a local tmux.
- `prefix d` or closing the tab leaves everything running.
- Plain `ssh my-ec2` for a shell without tmux (for example to run `tmux kill-server`).
- `Ctrl+Cmd+V` pastes a screenshot to Claude on the server: [terminals.md](terminals.md#paste-an-image-to-a-server).
- Update: `cd ~/dotfiles && git pull && ./install.sh`, then upgrade tools as in [install.md](install.md#update). Remove: `./uninstall.sh`.

## 4. Name this server

EC2 hostnames look like `ip-172-32-4-187`. In `~/.zshrc.local`:

```sh
export HOST_LABEL=bravo.example.com
export TZ=America/Bogota
```

Over SSH, `HOST_LABEL` shows in the prompt and in the tmux SSH badge. tmux reads both only when its server starts. To update a running tmux:

```sh
tmux set-environment -g HOST_LABEL "$HOST_LABEL"
tmux set -g @host_label "$HOST_LABEL"
```

The status clock picks up `TZ` only on restart: `tmux kill-server`, then `tssh my-ec2` (continuum restores the sessions). A tmux-only name goes in `~/.config/tmux/local.conf` as `set -g @host_label "dev-box"`; it wins over `HOST_LABEL`.

## 5. Several users

Each user has their own home, tools, tmux server and dotfiles clone; only the apt packages are shared.

- **Admin, once:** the `apt-get` line above. **Per user:** `sudo adduser <name> && sudo chsh -s /usr/bin/zsh <name>`.
- **Each user**, no sudo: clone and `./install.sh`. The admin runs `sudo apt-get upgrade`.
- A first login may show "This is the Z Shell configuration function for new users": press `q`. If you created a `~/.zshrc` there, `install.sh` backs it up.
- mise tools take about 1.3 GB per user.

## 6. Troubleshooting

- **`tssh` says tmux not found:** the login shell isn't zsh. Run the `chsh` step, then `ssh -O exit <user>@<host>` if you share connections, and reconnect.
- **Unknown tmux options after login, or install ends with "logins start the system tmux":** bash is still the login shell, so it starts apt's `/usr/bin/tmux`. `chsh`, log out and in, then `tmux kill-server`.
- **`git pull` says "Permission denied (publickey)":** an old git config sent all GitHub traffic over SSH. Pull or rerun `./install.sh`; the current one uses SSH for pushes only.
- **`git push` or `--with-claude` "Permission denied (publickey)":** if `echo $SSH_AUTH_SOCK` prints a path, the key isn't in the laptop's agent ([steps 2-4](#share-the-github-key)); if empty, add `ForwardAgent yes`. Then rerun `./install.sh --with-claude <git-url>`.
- **Ghostty prompts alternate between laptop and server, or keys go nowhere after a drop:** a leftover ssh master. Close the tab, then `ssh -O exit <host>`.
- **Wrong icons or colors:** the laptop's terminal font or profile. On a Linux laptop, `fc-cache -f` and restart the terminal.
