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

The key must be loaded in the Mac's SSH agent. On your Mac, check:

```sh
ssh-add -l
```

If your GitHub key is not in the list, add it:

```sh
ssh-add --apple-use-keychain ~/.ssh/<your github key>
```

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

Use `./install.sh` without `--with-claude` if the server has no GitHub access (no forwarded key). Without GitHub SSH access the installer keeps GitHub on https. If you reconnect later with the key forwarded, the next `./install.sh` removes that https override by itself (only the file it wrote, marked on its first line).

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
- **GitHub clone asks for a password, or "permission denied".** On your Mac, run `ssh-add -l` and check that your GitHub key is listed. Check that `ForwardAgent yes` is in the host entry. Then reconnect.
- **`--with-claude` says "no GitHub SSH access on this machine" and exits with an error.** The installer tested `ssh git@github.com` and GitHub did not accept a key. It skips the Claude step and finishes the rest. Fix the forwarding as in the item above, reconnect, then run `./install.sh --with-claude` again.
- **`git push` asks for a password on a server that used to have no key.** `~/.config/git/local` may still force https. Run `./install.sh` again: when `ssh -T git@github.com` works, it removes that file if the installer wrote it. A file you wrote yourself is never touched.
- **Colors or icons look wrong.** This is the Mac terminal font or profile, not the server. The server sends text only; your Mac terminal draws the icons.
