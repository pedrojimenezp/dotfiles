# Remote Ubuntu dev server

A step-by-step guide to set up an Ubuntu server (for example an EC2 instance) with these dotfiles and work on it over SSH.

Every command says where it runs: "On your laptop" or "On the server". Your laptop can be a Mac or a Linux machine. Where a step is different, it is marked **macOS** or **Linux**. If a step has no mark, it is the same on both.

## 1. What you get

- The same dev environment as your laptop: zsh, nvim, tmux, mise and Claude Code.
- tmux runs on the server. If your laptop disconnects or sleeps, your work keeps running.
- tmux continuum saves your sessions every 15 minutes. After a server reboot, run `tssh my-ec2` and they come back.

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

You do not need `SetEnv TERM=...` or `RequestTTY` in the entry. Ghostty's ssh-terminfo and `tssh -t` already cover them.

### Share your GitHub key with the server

Why: on your laptop, `ssh` can read a key file directly, so GitHub works even if the key is not in the agent. But `ForwardAgent` only shares keys that are loaded in the agent. If the key is not loaded, the server gets "Permission denied (publickey)" even though GitHub works on your laptop. `gh auth login` does not help here: it sets up https tokens, and `ssh -T` only uses SSH keys.

1. On your laptop (macOS and Linux), find which key GitHub uses:
   ```sh
   ssh -vT git@github.com 2>&1 | grep -E "Offering public key|Authenticated to"
   ```
   The path printed just before "Authenticated to github.com" is your GitHub key. Only file names are printed, never the key itself.
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

On the server, install the prerequisites (the only step that needs sudo besides `chsh`):

```sh
sudo apt-get update && sudo apt-get install -y build-essential procps curl file git zsh
```

On the server, install Homebrew and add it to your PATH for this session:

```sh
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

On the server, clone the dotfiles and install them:

```sh
git clone https://github.com/pedrojimenezp/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh --with-claude <git-url>
```

Use `./install.sh` without `--with-claude <git-url>` if the server has no GitHub access (no forwarded key). Everything else (Homebrew, plugins, `git pull`) uses https and needs no key; only a private `--with-claude` repo and `git push` need SSH.

If zsh is missing or is not your login shell, `install.sh` prints the exact command to run.

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
3. On the server, name this machine (optional). EC2 hostnames look like `ip-172-32-4-187`. Add one line to `~/.zshrc.local`:
   ```sh
   export HOST_LABEL=bravo.example.com
   ```
   Open a new shell: the prompt and the tmux SSH badge show this name instead of the hostname. It only affects your user, so it is safe on a shared box. tmux reads it when its server starts: for a running tmux, run `tmux kill-server` (this ends its sessions) or `tmux set -g @host_label "$HOST_LABEL"` and `tmux source-file ~/.config/tmux/tmux.conf`.
4. On the server, run `claude` once and log in.
5. On the server, inside a project that needs other tool versions, run:
   ```sh
   mise install
   ```
6. On the server, type `exit` to go back to your laptop.

## 4. Daily use

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
- To leave, press `Ctrl+Space`, then `d` (detach). Or just close the tab. Everything keeps running on the server.
- To come back, open a tab and run `tssh my-ec2` again.

## 5. Updating the server later

On the server:

```sh
cd ~/dotfiles && git pull && ./install.sh
```

`install.sh` is safe to run again.

## 6. Troubleshooting

- **`tssh` says tmux not found.** Your login shell is not zsh. On the server, run the `chsh` step from section 3, then log out and in.
- **GitHub clone asks for a password, or "permission denied".** Follow "Share your GitHub key with the server" in section 2, then reconnect.
- **`--with-claude <git-url>` says "no GitHub SSH access on this machine" and exits with an error.** The installer tested `ssh git@github.com` and GitHub did not accept a key. It skips the Claude step and finishes the rest. Fix the forwarding as in the item above, reconnect, then run `./install.sh --with-claude <git-url>` again.
- **Homebrew install or `git pull` says "Permission denied (publickey)".** This only happens with the old git config, which sent all GitHub traffic over SSH. Run `git pull` in the dotfiles clone (or re-run `./install.sh`) to get the current config. Now only pushes use SSH. Where SSH is needed (a private `--with-claude` repo, `git push`), see "Share your GitHub key with the server" in section 2: if `echo $SSH_AUTH_SOCK` on the server is set but access is denied, the key is not in the laptop's agent; if it is empty, `ForwardAgent yes` is missing.
- **Colors or icons look wrong.** This is your laptop's terminal font or profile, not the server. The server sends text only; your laptop's terminal draws the icons. On macOS, check the terminal profile (for example iTerm) uses the Nerd Font. On Linux, the Nerd Font must be installed on the laptop (`install.sh` does this on Linux desktops; run `fc-cache -f` and restart the terminal) and selected in your terminal.
