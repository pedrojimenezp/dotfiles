# tmux-sessionizer

`tmux-sessionizer` is a project picker for tmux. In tmux, press `prefix f`
(the prefix is `Ctrl+Space`). An fzf list opens.
Pick a line and you jump to a tmux session for that directory. The session is
created if it does not exist yet.

The script is `bin/.local/bin/tmux-sessionizer`. Stow installs it as
`~/.local/bin/tmux-sessionizer`.

## What it lists

- Git worktrees first. They are what you usually work on.
- Then plain directories (your projects).

Each line has a label:

- A worktree shows `branch  [repo]`, for example `fix-login  [api]`.
- A plain directory shows its full path.

Hidden folders, bare repos (`*.git`), `node_modules` and `worktrees/` folders are
not listed as projects. Worktrees come from `git worktree list`, so they are found for every
repo under your search roots, wherever the worktree folder lives.
A worktree folder inside a search root is listed once, by its branch, and gets
the branch name however you open it (picker or argument).
A worktree whose main checkout is not under the roots (or is a bare repo, as in
`app.git` or `app/.bare` plus worktrees) is still listed, by its own branch,
with the repo name `app`.
A search root may be a symlink; symlinks below a root are not followed.

## Session names

- A worktree session is named after its branch. Without a branch (detached
  HEAD) it uses the folder name. A plain directory uses its folder name.
- A directory given as an argument is resolved (ignoring `CDPATH`) to its real absolute path
  first, so `tmux-sessionizer .` is named after the folder, not `-`.
  A linked worktree given as an argument is named after its branch, like in
  the picker, so both ways reuse one session.
- The characters `/`, `.`, `:` and spaces become `-`. Repeated `-` collapse
  into one. (tmux does not allow `.` and `:` in names.)
- A directory that already has a session (found by its start path) always
  reuses it, even when the name came from a suffix (`api-b`).
- If a session with that name already exists for another directory, a suffix
  is added (cleaned the same way): the repo name for a worktree
  (`fix-login-api`), the parent folder name for a plain directory (`api-b`).
  If that name is taken by yet another directory, a counter follows (`api-b-2`, `api-b-3`).

## Default search roots

| Situation | Roots | Depth |
| --- | --- | --- |
| `~/projects` exists | `~/projects` | 3 |
| `~/projects` is missing | `$HOME` | 2 |

In the `$HOME` fallback the script skips `~/go`, `~/snap` and `~/bin`
(and every `worktrees/` folder, at any depth).

## Config file

Optional. One file per machine. It is not in this repo and Stow does not
touch it.

```
${XDG_CONFIG_HOME:-$HOME/.config}/sessionizer/config
```

Usually that is `~/.config/sessionizer/config`. Create it:

```
mkdir -p ~/.config/sessionizer
$EDITOR ~/.config/sessionizer/config
```

Example:

```
# Roots to search. This replaces the default roots.
# Only folders below a root are listed, never the root itself.
include = ~/projects ~/work

# Trees to skip. find never goes inside them.
exclude = ~/go ~/projects/old

# Maximum depth under each root.
depth = 2
```

Rules:

- One `key = value` per line.
- Text after `#` is a comment. Blank lines are ignored.
- Values are paths separated by spaces. Paths with spaces do not work.
- `~`, `$HOME` and `${HOME}` at the start of a path are expanded. Other
  variables are not.
- `include` paths that do not exist are skipped, with no message.
- An unknown key prints a one-line warning on stderr and is ignored.
- A `depth` that is not a number of 1 or more prints a warning and the
  default depth is used.
- `exclude` is added to the built-in skips. With the `$HOME` fallback, `go`,
  `snap`, `bin` and `worktrees/` folders stay skipped too.
- If `include` is set, the depth default is 3 (not 2).

## Environment variables

| Variable | Meaning |
| --- | --- |
| `SESSIONIZER_DIRS` | Search roots, space separated. Same as `include`. |
| `SESSIONIZER_EXCLUDE` | Trees to skip. Same as `exclude`. |
| `SESSIONIZER_DEPTH` | Maximum depth. Same as `depth`. |
| `SESSIONIZER_TMUX_ARGS` | Extra tmux options, for example `-L sock` for a separate server. |

Order of priority: environment variable, then config file, then built-in
default. Example:

```
SESSIONIZER_DIRS="$HOME/work" tmux-sessionizer
```

An empty variable counts as not set.

## Why don't I see my project?

Run:

```
tmux-sessionizer --list
```

It prints every candidate as `label<TAB>path<TAB>repo` and exits. Check:

1. Is the path below a search root? Look at your `include` line. The roots
   themselves are never listed, only the folders inside them.
2. Is it deeper than `depth`? Raise `depth`.
3. Is it inside an `exclude` path, a hidden folder or `node_modules`?
4. Did a warning appear on stderr? Fix the config line.

To see only the paths: `tmux-sessionizer --list | cut -f2`.

## When changes apply

The script reads the config on every run. A change is used the next time you
press `prefix f`. You do not reload tmux or the shell.

## macOS and Linux

The script works with bash 3.2 (macOS) and newer. You need `fzf`, `tmux` and
`git`. Install with `brew install fzf tmux git` on macOS or
`sudo apt install fzf tmux git` on Ubuntu.
