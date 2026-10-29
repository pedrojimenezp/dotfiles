# Remote Ubuntu dev server

A step-by-step guide to set up an Ubuntu server (for example an EC2 instance) with these dotfiles and work on it over SSH.

Every command says where it runs: "On your Mac" or "On the server".

## 1. What you get

- The same dev environment as your laptop: zsh, nvim, tmux, mise and Claude Code.
- tmux runs on the server. If your laptop disconnects or sleeps, your work keeps running.
- tmux continuum saves your sessions every 15 minutes. After a server reboot, run `tssh my-ec2` and they come back.

## 2. On your Mac, once

Add a host entry to `~/.ssh/config`. Replace the placeholders:

```
Host my-ec2
  HostName <server address>
  User ubuntu
  IdentityFile <path to your key, e.g. ~/.ssh/my-ec2.pem>
  ForwardAgent yes
```

`ForwardAgent yes` lets the server use your Mac's GitHub key without copying the key to the server. You need it for `--with-claude` and for `git push` from the server.

You do not need `SetEnv TERM=...` or `RequestTTY` in the entry. Ghostty's ssh-terminfo and `tssh -t` already cover them.

### Share your GitHub key with the server

Why: on your Mac, `ssh` can read a key file directly, so GitHub works even if the key is not in the agent. But `ForwardAgent` only shares keys that are loaded in the agent. If the key is not loaded, the server gets "Permission denied (publickey)" even though GitHub works on your Mac. `gh auth login` does not help here: it sets up https tokens, and `ssh -T` only uses SSH keys.

1. On your Mac, find which key GitHub uses:
   ```sh
   ssh -vT git@github.com 2>&1 | grep -E "Offering public key|Authenticated to"
   ```
   The path printed just before "Authenticated to github.com" is your GitHub key. Only file names are printed, never the key itself.
2. On your Mac, load that key into the agent. Use your own path:
   ```sh
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   ```
   It asks for the passphrase once and saves it in the macOS Keychain.
3. On your Mac, keep the key loaded after a reboot. Add this at the END of `~/.ssh/config`:
   ```
   Host *
     AddKeysToAgent yes
     UseKeychain yes
   ```
4. On your Mac, check that the agent lists the key:
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

On your Mac, connect:

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
./install.sh --with-claude
```

Use `./install.sh` without `--with-claude` if the server has no GitHub access (no forwarded key). Everything else (Homebrew, plugins, `git pull`) uses https and needs no key; only `--with-claude` and `git push` need SSH.

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

1. On your Mac, log in again: `ssh my-ec2`. You are now in zsh.
2. On the server, put your secrets in `~/.zshrc.local` (it is sourced last and not tracked by git), then lock it:
   ```sh
   chmod 600 ~/.zshrc.local
   ```
3. On the server, run `claude` once and log in.
4. On the server, inside a project that needs other tool versions, run:
   ```sh
   mise install
   ```
5. On the server, type `exit` to go back to your Mac.

## 4. Daily use

1. On your Mac, open a new terminal tab (`Cmd+T`).
2. On your Mac, run:
   ```sh
   tssh my-ec2
   ```
   `tssh` connects and attaches to the tmux session `main` (it creates it if needed).
3. Look at the status bar. A **magenta** block with the server name means you are on the server.

Rules:

- Use one tab per server.
- Never run `tssh` inside a local tmux. No tmux inside tmux.
- Switch between tabs with `Cmd+1`, `Cmd+2`, and so on.
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
- **`--with-claude` says "no GitHub SSH access on this machine" and exits with an error.** The installer tested `ssh git@github.com` and GitHub did not accept a key. It skips the Claude step and finishes the rest. Fix the forwarding as in the item above, reconnect, then run `./install.sh --with-claude` again.
- **Homebrew install or `git pull` says "Permission denied (publickey)".** This only happens with the old git config, which sent all GitHub traffic over SSH. Run `git pull` in the dotfiles clone (or re-run `./install.sh`) to get the current config. Now only pushes use SSH. Where SSH is needed (`--with-claude`, `git push`), see "Share your GitHub key with the server" in section 2: if `echo $SSH_AUTH_SOCK` on the server is set but access is denied, the key is not in the Mac agent; if it is empty, `ForwardAgent yes` is missing.
- **Colors or icons look wrong.** This is the Mac terminal font or profile, not the server. The server sends text only; your Mac terminal draws the icons.
