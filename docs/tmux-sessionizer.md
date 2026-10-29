# tmux-sessionizer

`tmux-sessionizer` is a project picker for tmux. In tmux, press `prefix f`
(the prefix is `Ctrl+Space`). An fzf list opens. Pick a line and you jump to a
tmux session for that folder. The session is created if it does not exist yet.

The script is `bin/.local/bin/tmux-sessionizer`. Stow installs it as
`~/.local/bin/tmux-sessionizer`. It makes no git calls: it only looks at folder
names.

## Folder convention

Feature work lives in a `worktrees/` folder. Any `<x>/worktrees/<feature>`
folder is a feature session.

| Layout | Worktree path |
| --- | --- |
| Single repo | `<repo>/worktrees/<branch>` |
| Monorepo or parent of several repos | `<parent>/worktrees/<feature>/<project>` |

In the second layout the feature folder holds one worktree per project you
touch, and the session opens in the feature folder.

## What it lists

1. Features: every `<x>/worktrees/<feature>` folder, up to 4 levels below a
   root. The label is `feature  [x]`, for example `fix-login  [api]`.
2. Repos: every folder that contains `.git` (a directory or a file), up to 3
   levels below a root. The label is the full path.

Not listed: the roots themselves, hidden folders, `node_modules`, anything
inside a `worktrees/` folder (features cover it), and plain folders without
`.git`.

## Search roots

- `SESSIONIZER_DIRS` (space separated), if set and not empty.
- Else `~/projects`, if it exists.
- Else `$HOME`, skipping `~/go`, `~/snap` and `~/bin`.

Roots that do not exist are skipped silently. The old config file
(`~/.config/sessionizer/config`) and `SESSIONIZER_EXCLUDE` / `SESSIONIZER_DEPTH`
are gone; delete the file, it is ignored.

## Session names

- The name is the folder name. `.`, `:` and spaces become `-`, and repeated `-`
  collapse. So a feature session is named after its feature or branch.
- `tmux-sessionizer <dir>` resolves the folder (ignoring `CDPATH`) to its real
  path first, so `tmux-sessionizer .` is named after the folder, not `-`.
- A folder that already has a session (matched by its start path) reuses it.
  Popup sessions (`_popup_*`) are ignored.
- If the name belongs to another folder, `-<owner>` is appended, where owner is
  the folder that holds `worktrees/` for a feature, else the parent folder
  (`app-two`). If that name is taken too, tmux reports an error.

## Environment variables

| Variable | Meaning |
| --- | --- |
| `SESSIONIZER_DIRS` | Search roots, space separated. |
| `SESSIONIZER_TMUX_ARGS` | Extra tmux options, for example `-L sock` for a separate server. |

## Why don't I see my project?

Run `tmux-sessionizer --list`. It prints `label<TAB>path` for every candidate.
Check that the folder is below a root, within the depth limits, has a `.git` or
sits at `<x>/worktrees/<feature>`, and is not under a hidden folder or
`node_modules`. Paths only: `tmux-sessionizer --list | cut -f2`.

## macOS and Linux

Works with bash 3.2 (macOS) and newer. You need `fzf`, `tmux` and `find`.
Install with `brew install fzf tmux` on macOS or `sudo apt install fzf tmux` on
Ubuntu.
