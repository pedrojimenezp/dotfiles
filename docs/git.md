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

## Reviewing in Neovim

In delta (the pager for plain `git diff` and `git log`), `n` / `N` jump to the next / previous file and `q` quits. To stage and commit interactively, run `lazygit`: `space` stages or unstages a file.

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

### Unified view: `review -u`

`review -u [<base>] [<dir>]` opens the same changes in gitsigns' diff panel instead of diffview: one pane with your real file, deleted lines shown inline in red and added lines in green, so `gd` and the rest of the language server work on the whole file. The panel lists committed and uncommitted changes since the merge-base, like diffview. Everything else (base, folder, tmux window `review:<repo>`, `--print`) works as without `-u`.

| Key | Does |
| --- | --- |
| `gu` (file panel) | toggle between the unified and the side-by-side view |
| `]f` / `[f` | open the next / previous changed file, keeping focus |
| `]c` / `[c` | next / previous hunk in the file |
| `Enter` (file panel) | open a file or fold a folder |
| `g?` (file panel) | every panel key, including staging with `s` / `u` |
| `q` (file panel) | close the panel |

Inside nvim, `:lua require('gitsigns').diff('<base>', nil, { diff = 'unified' })` does the same for any revision.

### Diff colors

Diffs look like GitHub's split view with every colorscheme: the old side tints changed lines light red and the new side light green, with the changed words darker. Only backgrounds change, so syntax colors stay. The tints are the `Normal` background blended with the scheme's red and green (`DiagnosticError` / `DiagnosticOk`), with GitHub-like fallbacks. Filler lines are blank with a faint gap background. The groups are in `lua/config/diff_colors.lua`, redefined after every colorscheme load; the unified view uses `GitSignsAddPreview` / `GitSignsDeleteVirtLn` for whole lines and `GitSignsAddInline` / `GitSignsChangeInline` / `GitSignsDeleteVirtLnInLine` for the changed words, also background-only; diffview picks the per-side groups through `hooks.diff_buf_win_enter` in `lua/plugins/git.lua`.

### Uncommitted changes

1. `cd` into the repo or worktree and run `nvim`.
2. Press `Space g d`. Diffview opens with every staged, unstaged and untracked change.
3. Review with the keys above, then `Space g q`.

### A branch you have locally (your own PR)

1. `cd` into the feature's worktree and run `git fetch`.
2. Run `review`, or press `prefix R` in a tmux pane in that folder. A tmux window `review:<repo>` opens with everything since the default branch (`origin/main`), committed and uncommitted.
3. If the PR targets another branch, pass it: `review dev`. A short name means `origin/dev` when that exists; the base can come before or after a folder.

### Someone else's PR

1. Run `review-pr 123` (replace 123 with the PR number) from the repo or any of its worktrees, or paste the PR's URL: `review-pr https://github.com/owner/repo/pull/123` (a trailing `/files`, `/commits` or `#...` is fine). A number means the repo you are in. A URL is matched against the `origin` of the current repo, then its superproject, then the submodules of that superproject (or of the current repo); it stops with a message when none matches, so in a folder of submodules you can run it from the top.
2. It fetches the PR from that repo's `origin` and finds the PR's base with `gh`. The worktree lands in one of two places. A single repo: `<repo>/worktrees/pr-123`, branch `pr-123`. A submodule of a superproject (for example `development/Website`): `<superproject>/worktrees/pr-website-123/Website`, still a worktree of the submodule's repo with branch `pr-123`. It always uses the superproject's main checkout, never one of its worktrees. Then it runs `review` against the base.
3. Install the project's dependencies in that worktree if `gd` should reach into libraries (for example `npm install`). Definitions inside the repo work without them.
4. Review as above. When the author pushes more commits, run the same `review-pr` command again: it fast-forwards the worktree. It stops, changing nothing, when the worktree has edits or the PR was force-pushed; then do step 5 and rerun. If you deleted the worktree folder by hand, rerunning recreates it; a leftover `pr-123` branch is moved to the PR head only when it has no commits of its own, otherwise it stops and tells you to delete or rename the branch.
5. Clean up when you're done: `review-pr --done 123` (or with the URL). It removes the worktree and the `pr-123` branch, plus the empty `pr-website-123` folder in the submodule layout, and refuses while the worktree has unsaved edits. The tmux window (`review:pr-123`, or `review:pr-website-123` in the submodule layout, so two PRs of one repo never share a window) stays open; close it yourself.

Without the script: `git fetch origin pull/123/head:pr-123`, `git worktree add worktrees/pr-123 pr-123`, then `review <base>` there (`gh pr view 123 --json baseRefName -q .baseRefName` prints the base).
