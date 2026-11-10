# Git

Config: `git/.config/git/config` and `ignore`, linked to `~/.config/git/`. Aliases: `git config --get-regexp alias`.

## Identity and per-machine settings

`~/.config/git/local` is included last, so it wins. `install.sh` writes the name and email there when git has none; add a work email or signing key the same way. `git config --show-origin user.email` shows which value is active.

Keep no `~/.gitconfig`: git reads it after `~/.config/git/config`, so it overrides this repo. `install.sh` backs it up.

## Non-obvious choices

- **Pushes to GitHub go over SSH; fetch and clone stay on HTTPS** (`pushInsteadOf`), so public repos need no key. The trailing slashes keep hosts like `github.company.com` unchanged. On a server, forward the laptop key ([server.md](server.md#share-the-github-key)).
- **HTTPS auth goes through `gh auth git-credential`**; an empty helper first drops stale ones. Does nothing without `gh`.
- **`pull.rebase`, `rebase.autoStash`, `rebase.autoSquash`**: pulls keep a straight history.
- **`merge.conflictstyle diff3`**, not `zdiff3`, which fails on git older than 2.35 (Ubuntu 22.04).
- **`filter.lfs` is `required`**: git fails if git-lfs is missing (`mise install`).
- **`core.editor` is unset**: git uses `$VISUAL`, which `.zshrc` sets.
- **delta** uses the `ansi` theme so it follows any terminal theme. lazygit gets delta's light/dark flag from `theme effective`, because it can't read the background under tmux; `.zshrc` sets `LG_CONFIG_FILE` so macOS reads `~/.config/lazygit`. `GH_PAGER="delta -s"` makes `gh pr diff` side by side.

## Global ignore

OS and editor files, `.env.local`, `.zshrc.local`, Claude Code's local files (`.claude/worktrees/`, `.claude/settings.local.json`, `CLAUDE.local.md`; the rest of `.claude/` stays trackable), and `/worktrees/` at a repo's top, so feature worktrees need no `info/exclude` entry.

## Reviewing changes

`git wip` and `git pr` show diffs in delta, untracked files included (plain `git diff` leaves them out). They never touch the index. The script is `bin/.local/bin/git-changes`.

```sh
git wip            # everything uncommitted: staged, unstaged and untracked (not ignored) files
git wip -s         # the same, side by side
git pr             # the whole branch since it left the base branch, committed or not, plus untracked files
git pr dev         # against another base: origin/dev when it exists, else a local dev
git pr -s          # side by side; -s and the base can come in either order
```

The default base is `origin/HEAD`, else `origin/main`, `origin/master`, `main`, `master`. A diff with nothing in it prints one line (`No uncommitted changes.`) instead of opening the pager.

In delta, `n` / `N` jump to the next / previous file and `q` quits.

For interactive review, run `lazygit`: arrow keys move between files, `space` stages or unstages one, and `W` diffs against a branch.
