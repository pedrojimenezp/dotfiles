# tmux-sessionizer

`tmux-sessionizer` is a project picker for tmux: it lists your projects and jumps to a [session](glossary.md#session) for the one you pick.

You'll use it to move between projects and feature branches in two key presses.

## Requirements

`fzf`, `tmux` and `find`. It works with bash 3.2 (macOS) and newer.

Install them the way [install.md](install.md) describes: Homebrew on macOS and Linux (`brew install fzf tmux`). `install.sh` does this for you. See [tmux.md](tmux.md#requirements) for why the apt version of tmux is not enough.

## Quick start

1. In tmux, press `prefix f`. Here `prefix` means `Ctrl+Space`, pressed and released first.
2. An [fzf](glossary.md#fzf) list opens in a popup. Type to filter.
3. Press `Enter` on a line. You jump to the tmux session for that folder, created if it does not exist yet.
4. Press `Esc` to close the list without choosing.

Outside tmux, run `tmux-sessionizer` in a shell. It starts or attaches to the session. You can also pass a folder: `tmux-sessionizer ~/projects/app`.

## What you see

Two kinds of lines, features first:

1. **Features**: labeled `feature  [x]`, for example `fix-login  [api]`.
2. **Repos**: labeled with the full path.

A feature is a [worktree](glossary.md#worktree) folder (a second checkout of a repo for one branch). Any `<x>/worktrees/<feature>` folder is a feature session. A repo is any folder that contains `.git`.

## Folder convention

Keep feature work in a `worktrees/` folder:

| Layout | Worktree path |
| --- | --- |
| Single repo | `<repo>/worktrees/<branch>` |
| Parent folder with several repos | `<parent>/worktrees/<feature>/<project>` |

In the second layout the feature folder holds one worktree per project you touch, and the session opens in the feature folder.

## Search roots

The same rule on every machine:

- If `SESSIONIZER_DIRS` (space separated) is set and not empty, only those folders are searched.
- Otherwise it searches `~/projects` (deeply, if it exists) plus the repos directly in `~`: each `~/<name>` with a `.git`, and its `~/<name>/worktrees/*` features.

Roots that do not exist are skipped silently. Repos deeper in `~`, such as `~/development/app`, are not found by default. Add their parent folder:

```sh
export SESSIONIZER_DIRS="$HOME/projects $HOME/development"   # in ~/.zshrc.local
```

| Variable | Meaning |
| --- | --- |
| `SESSIONIZER_DIRS` | Search roots, space separated |
| `SESSIONIZER_TMUX_ARGS` | Extra tmux options, for example `-L sock` for a separate server |

## Limits

- Features are found up to 4 levels below a root. Repos, up to 3 levels.
- Not listed: the roots themselves, hidden folders, `node_modules`, anything inside a `worktrees/` folder (features cover it), and plain folders without `.git`.
- The script makes no git calls. It only looks at folder names.

## Troubleshooting

**You don't see your project.** Run:

```sh
tmux-sessionizer --list
```

It prints `label<TAB>path` for every candidate. For paths only, add `| cut -f2`. Check that the folder:

- is below a root and within the depth limits;
- has a `.git`, or sits at `<x>/worktrees/<feature>`;
- is not under a hidden folder or `node_modules`.

**Old settings.** The config file `~/.config/sessionizer/config` and the variables `SESSIONIZER_EXCLUDE` and `SESSIONIZER_DEPTH` are gone. Delete the file: it is ignored.

## How it works

**Session names.** The name is the folder name. `.`, `:`, `/` and spaces become `-`, and repeated `-` collapse. So a feature session is named after its feature or branch.

- `tmux-sessionizer <dir>` resolves the folder (ignoring `CDPATH`) to its real path first, so `tmux-sessionizer .` is named after the folder, not `-`.
- A folder that already has a session (matched by its start path) reuses it. Popup sessions (`_popup_*`) are ignored.
- If the name belongs to another folder, `-<owner>` is appended. The owner is the folder that holds `worktrees/` for a feature, else the parent folder (`app-two`). If that name is taken too, tmux reports an error.

**Switching.** Inside tmux, a missing session is created detached, then the client switches to it. Outside tmux, `new-session -A` attaches or creates.

The script is `bin/.local/bin/tmux-sessionizer`, linked to `~/.local/bin/tmux-sessionizer`. The key is bound in `tmux.conf`.

## Related pages

- [tmux.md](tmux.md)
- [glossary.md](glossary.md#worktree)
- [git.md](git.md)
