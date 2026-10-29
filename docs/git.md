# Git

Files: `git/.config/git/config` (settings) and `git/.config/git/ignore` (global ignore list). They are linked to `~/.config/git/`. Do not keep a `~/.gitconfig`: it wins over `~/.config/git/config`. `install.sh` moves an existing one to a backup.

## What the config sets and why

| Setting | Value | Why |
| --- | --- | --- |
| `user.name`, `user.email` | owner's name and email | Default author. Override per machine in `~/.config/git/local`. |
| `init.defaultBranch` | `main` | New repos start on `main`. |
| `core.pager` | `delta` | Colored, readable diffs and logs. Needs `git-delta`. |
| `core.editor` | `nvim` | Commit messages open in Neovim. |
| `core.excludesFile` | `~/.config/git/ignore` | Global ignore list. |
| `interactive.diffFilter` | `delta --color-only` | `git add -p` is colored too. |
| `delta.*` | navigate, line numbers, unified view, `ansi` syntax theme, auto light/dark | In a diff, `n` / `N` jump between files. `ansi` follows the terminal's colors, so any theme works. |
| `pull.rebase` | `true` | `git pull` rebases, so a plain update makes no merge commit. |
| `rebase.autoStash` | `true` | Dirty changes are stashed and restored around a rebase. |
| `rebase.autoSquash` | `true` | `fixup!` / `squash!` commits are placed automatically in `git rebase -i`. |
| `push.autoSetupRemote` | `true` | The first `git push` creates the upstream branch. No `-u` needed. |
| `fetch.prune` | `true` | Remote branches deleted upstream disappear locally. |
| `diff.algorithm` | `histogram` | Better diffs than the default. |
| `diff.colorMoved` | `default` | Moved lines have their own color. |
| `merge.conflictstyle` | `diff3` | Conflict markers also show the base text. (`zdiff3` is not used: it fails on git older than 2.35, for example Ubuntu 22.04.) |
| `rerere.enabled` | `true` | Git remembers how you solved a conflict and reuses it. |
| `url."ssh://git@github.com".pushInsteadOf` | `https://github.com` | **Pushes** to GitHub go over SSH. Fetch, clone and pull stay on https, so public repos need no key. |
| `filter.lfs.*` | git-lfs commands | Git LFS for big files (`required = true`: fails if git-lfs is missing). |
| `include.path` | `~/.config/git/local` | Machine-specific overrides, not tracked. |

For pushes over SSH you need a GitHub key. On a server, forward your laptop key, see [server.md](server.md).

## Aliases

Git aliases (type `git <alias>`):

| Alias | Runs |
| --- | --- |
| `git st` | `status -sb` (short status) |
| `git co` | `checkout` |
| `git sw` | `switch` |
| `git br` | `branch -vv` (with upstream info) |
| `git lg` | `log --oneline --graph --decorate -20` |
| `git last` | `log -1 --stat` (last commit) |
| `git unstage` | `restore --staged` (remove files from the index) |
| `git amend` | `commit --amend --no-edit` (add staged changes to the last commit) |

Shell aliases from `.zshrc` (`gs`, `gd`, `gl`, `gp`, `lg`) are in [zsh.md](zsh.md). The shell `lg` is lazygit, and `git lg` is the log.

## Per-machine settings: `~/.config/git/local`

This file is included at the end of the config, so it wins over everything above. It is not in the repo. Use it for a work email on a work machine, signing keys, or other local rules:

```gitconfig
# ~/.config/git/local
[user]
	email = me@work.example
```

Check which value is active and where it comes from:

```sh
git config --show-origin user.email
```

For one project only, run `git config user.email me@work.example` inside that repo (stored in the repo's `.git/config`).

`install.sh` deletes the `local` file only when it is the old https override that an older installer wrote itself. A hand-written file is never touched.

## Global ignore list

`~/.config/git/ignore` applies to every repo on this machine. It ignores: `.DS_Store`, `Thumbs.db`, Vim swap files (`*.swp`, `*.swo`, `*~`), `.idea/`, `.vscode/`, `.env.local`, `.zshrc.local`, `.claude/` and `CLAUDE.local.md`. For a rule that is only yours in one repo, add it to that repo's `.git/info/exclude` (not committed).

## Useful commands with this config

```sh
git add -p                 # choose changes one by one (colored by delta)
git commit --fixup <sha>   # later: git rebase -i --autosquash <sha>~
git pull                   # fetch and rebase
git push                   # the first push sets the upstream by itself
git rerere diff            # show what rerere remembers
lg                         # lazygit (shell alias)
```

## Notes for servers

`core.pager = delta` and `core.editor = nvim` are fixed in the config. A machine without delta or nvim (for example `./install.sh --server`, which does not install Homebrew packages) needs overrides in `~/.config/git/local`:

```gitconfig
[core]
	pager = less
	editor = vim
```
