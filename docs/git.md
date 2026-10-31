# Git

The global git config: `git/.config/git/config` (settings) and `git/.config/git/ignore` (global ignore list). They are linked to `~/.config/git/`.

You'll use it for: readable diffs, pulls that keep history clean, short aliases, and a per-machine identity.

- [Quick start](#quick-start)
- [Aliases](#aliases)
- [Per-machine settings](#per-machine-settings-configgitlocal)
- [Useful commands](#useful-commands-with-this-config)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)

## Quick start

1. Run `install.sh`. It asks for your name and email if git has none, and saves them in `~/.config/git/local`.
2. Check the result:

   ```sh
   git config --show-origin user.email
   ```

3. Use `git st`, `git lg` and `git pull` as usual. Diffs open in `delta`, a colored pager.

Do not keep a `~/.gitconfig`: it wins over `~/.config/git/config`. `install.sh` moves an existing one to a backup.

## What the config sets and why

| Setting | Value | Why |
| --- | --- | --- |
| `init.defaultBranch` | `main` | New repos start on `main`. |
| `core.pager` | `delta` | Colored, readable diffs and logs. Needs `git-delta`. |
| `core.excludesFile` | `~/.config/git/ignore` | Global ignore list. |
| `interactive.diffFilter` | `delta --color-only` | `git add -p` is colored too. |
| `delta.*` | navigate, line numbers, unified view, `ansi` syntax theme, auto light/dark | In a diff, `n` / `N` jump between files. `ansi` follows the terminal's colors, so any theme works. |
| `credential.https://github.com.helper` | `gh auth git-credential` | HTTPS GitHub remotes use the `gh auth login` token. Does nothing without `gh`. SSH is unaffected. |
| `pull.rebase` | `true` | `git pull` rebases instead of merging. See below. |
| `rebase.autoStash` | `true` | Uncommitted changes are set aside and restored around a rebase. |
| `rebase.autoSquash` | `true` | `fixup!` / `squash!` commits are placed automatically in `git rebase -i`. |
| `push.autoSetupRemote` | `true` | The first `git push` creates the upstream branch. No `-u` needed. |
| `fetch.prune` | `true` | Remote branches deleted upstream disappear locally. |
| `diff.algorithm` | `histogram` | Better diffs than the default. |
| `diff.colorMoved` | `default` | Moved lines have their own color. |
| `merge.conflictstyle` | `diff3` | Conflict markers also show the base text. |
| `rerere.enabled` | `true` | Git remembers how you solved a conflict and reuses it. |
| `url."ssh://git@github.com/".pushInsteadOf` | `https://github.com/` | **Pushes** to GitHub go over SSH. Fetch, clone and pull stay on https, so public repos need no key. |
| `filter.lfs.*` | git-lfs commands | Git LFS for big files. It is `required`, so git fails if git-lfs is missing. |
| `include.path` | `~/.config/git/local` | Machine-specific overrides, not tracked. |

For pushes over SSH you need a GitHub key. On a server, forward your laptop key, see [server.md](server.md).

### What "pull rebases" means

When you pull and the remote has new commits, git has two ways to combine them with yours.

- **Merge** (the git default) adds an extra "merge commit" that joins the two lines of work.
- **Rebase** (this config) takes your local commits, puts them on top of the new remote commits, and replays them. History stays a straight line.

Your commits get new IDs after a rebase. That is fine for commits you have not pushed. If a rebase stops on a conflict, fix the files, run `git add` on them and then `git rebase --continue`. To cancel, run `git rebase --abort`.

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

lazygit and `gh` use delta too. `lazygit/.config/lazygit/config.yml` sets `git.diffRenderers` (press `|` in lazygit to switch between side by side and inline; delta's light/dark flag comes from `theme effective`, because lazygit can't read the terminal background under tmux), and `.zshrc` sets `LG_CONFIG_FILE` so macOS reads that file. `.zshrc` also sets `GH_PAGER="delta -s"`, so `gh pr diff` is side by side.

## Per-machine settings: `~/.config/git/local`

This file is included at the end of the config, so it wins over everything above. It is not in the repo.

Your name and email live here. `install.sh` asks for them when git has none and writes them with `git config --file ~/.config/git/local`. Use the file also for a work email on a work machine, signing keys, or other local rules:

```gitconfig
# ~/.config/git/local
[user]
    email = me@work.example
```

Check which value is active and where it comes from:

```sh
git config --show-origin user.email
```

For one project only, run `git config user.email me@work.example` inside that repo. It is stored in the repo's `.git/config`.

## Global ignore list

`~/.config/git/ignore` applies to every repo on this machine. It ignores:

- OS and editor files: `.DS_Store`, `Thumbs.db`, Vim swap files (`*.swp`, `*.swo`, `*~`), `.idea/`, `.vscode/`.
- Local files: `.env.local`, `.zshrc.local`.
- Claude Code files: `.claude/worktrees/`, `.claude/settings.local.json` and `CLAUDE.local.md`. The rest of `.claude/`, such as `settings.json`, stays trackable.
- `/worktrees/`: feature [worktrees](glossary.md#worktree) at the top of a repo, so no `info/exclude` entry is needed.

For a rule that is only yours in one repo, add it to that repo's `.git/info/exclude`. It is not committed.

## Useful commands with this config

```sh
git add -p                 # choose changes one by one (colored by delta)
git commit --fixup <sha>   # later: git rebase -i --autosquash <sha>~
git pull                   # fetch and rebase
git push                   # the first push sets the upstream by itself
git rerere diff            # show what rerere remembers
lg                         # lazygit (shell alias)
```

## Troubleshooting

- **Commits show the wrong name or email**: run `git config --show-origin user.email`. Edit `~/.config/git/local`, or check for a stray `~/.gitconfig`.
- **`git push` asks for a password or fails**: pushes use SSH, so add a GitHub key, see [server.md](server.md) for servers.
- **Git fails on `git-lfs`**: run `mise install` (the mise config has it), or remove the `filter.lfs` section if you do not need it.

## How it works

- **Config order.** git reads `~/.config/git/config` before `~/.gitconfig`, so a leftover `~/.gitconfig` overrides this repo. The `include.path` line is last, so `~/.config/git/local` wins over everything.
- **Editor.** `core.editor` is not set, so git uses `$VISUAL`, then `$EDITOR`. `.zshrc` sets both to `nvim`, or `vim` when nvim is missing. Override with `core.editor` in `~/.config/git/local`.
- **Conflict style.** `diff3` is used instead of `zdiff3`, because `zdiff3` fails on git older than 2.35, for example Ubuntu 22.04.
- **SSH push rule.** The trailing slashes in the `pushInsteadOf` rule keep hosts like `github.company.com` unchanged.

## Related

- [zsh.md](zsh.md): the git shell aliases.
- [server.md](server.md): SSH keys on a server.
- [tools.md](tools.md): delta, lazygit, gh and git-lfs.
