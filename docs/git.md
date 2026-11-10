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

## Reviewing in Neovim

diffview.nvim lists the changed files on the left and shows each one side by side. The right side is your real file, so the language server works there: `gd` goes to the definition. The left side is the old version from git and has no language server.

These keys work inside any diffview (leader is `Space`):

| Key | Does |
| --- | --- |
| `j` / `k`, then `Enter` | pick a file in the list |
| `Tab` / `Shift-Tab` | next / previous changed file |
| `Ctrl-w l` / `Ctrl-w h` | move between the panes |
| `gd` (right side) | go to definition; `Ctrl-o` comes back |
| `Space e` | back to the file list |
| `-` (file list) | stage or unstage a file |
| `g?` | every diffview key |
| `Space g q` | close the diffview |

### Uncommitted changes

1. `cd` into the repo or worktree and run `nvim`.
2. Press `Space g d`. Diffview opens with every staged, unstaged and untracked change.
3. Review with the keys above, then `Space g q`.

### A branch you have locally (your own PR)

1. `cd` into the feature's worktree and run `git fetch`.
2. Run `review`, or press `prefix R` in a tmux pane in that folder. A tmux window `review:<repo>` opens with everything since the default branch (`origin/main`), committed and uncommitted.
3. If the PR targets another branch, open Neovim there instead and run `:DiffviewOpen origin/dev...HEAD --imply-local`. The three dots start from the merge-base, as GitHub does; `--imply-local` keeps your real files on the right, so `gd` works.

### Someone else's PR

1. Get the PR's code into a worktree (replace 123 with the PR number):

   ```sh
   cd <repo>
   git fetch origin pull/123/head:pr-123
   git worktree add worktrees/pr-123 pr-123
   cd worktrees/pr-123
   ```

2. Install the project's dependencies if `gd` should reach into libraries (for example `npm install`). Definitions inside the repo work without them.
3. Review it as above: `review`, or the `:DiffviewOpen origin/<base>...HEAD --imply-local` command. `gh pr view 123 --json baseRefName -q .baseRefName` prints the PR's base.
4. Clean up when you're done:

   ```sh
   cd <repo>
   git worktree remove worktrees/pr-123
   git branch -D pr-123
   ```
