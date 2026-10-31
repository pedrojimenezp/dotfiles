# Contributing

How to add a key, alias, script or tool so the help list and the docs stay in sync. It applies to your own fork as much as to pull requests here.

## The one rule

Describe a shortcut where you define it. The help list (`prefix ?` or `dotfiles-help`) reads those descriptions from the config files every time it runs. There is no separate list to update, except for keys that no config states.

## Add a tmux key

Give every `bind` in `tmux/.config/tmux/tmux.conf` a note with `-N`:

```tmux
bind -N "project session picker" f display-popup -E "~/.local/bin/tmux-sessionizer"
```

The help list shows it as `prefix f`. It also understands these flags:

| In `tmux.conf` | Shown as |
| --- | --- |
| `bind -N "..." -n M-h` | `Alt+h` (no prefix) |
| `bind -N "..." -T copy-mode-vi v` | `copy mode: v` |
| `bind -N "..." -r H` | `prefix Shift+H` (uppercase letters get `Shift+`) |

A `bind` without `-N` does not appear in the list. Check that every binding has a note (no output means they all do):

```sh
grep -E '^\s*bind' tmux/.config/tmux/tmux.conf | grep -v -- ' -N '
```

Plugins bind their own keys and cannot carry a note, so their keys go in [cheatsheet.tsv](#add-a-plugin-tool-or-terminal-key).

## Add a zsh alias, key or function

In `zsh/.zshrc`:

- **Alias or `bindkey`**: an end-of-line comment, with a space on both sides of the `#`.
  ```zsh
  alias gs='git status -sb'  # short status
  ```
- **Function**: a comment block above it whose first line reads `# name args: what it does`.
  ```zsh
  # tssh <ssh args>: connect and attach to (or create) the remote tmux session "main".
  tssh() { ... }
  ```

Only the first definition of an alias is listed.

## Add a Neovim key

Give every map a `desc`. which-key shows it when you press `Space` and wait.

```lua
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
```

General maps go in `nvim/.config/nvim/lua/config/keymaps.lua`. Plugin maps go next to their plugin in `lua/plugins/`. Neovim keys are not in `dotfiles-help`, apart from a few pointers in the cheat sheet.

## Add a script

Put it in `bin/.local/bin/` and make it executable. The help list reads two things from it:

- **Line 2**: a one-line description, as a comment.
- **Usage lines**: `# Usage:` lines, and the indented comment lines under them. Each needs two or more spaces, then the description in parentheses.

```bash
#!/usr/bin/env bash
# Pick a project folder and open a tmux session for it.
# Usage: tmux-sessionizer [dir]   (without an argument, pick from the roots)
#        tmux-sessionizer --list  (print each candidate and exit)
```

## Add a plugin, tool or terminal key

Keys that come from a plugin, a tool or the terminal have no line in this repo to describe them. Add them to [cheatsheet.tsv](cheatsheet.tsv) instead.

Each line has four fields separated by a tab: area, keys, description, doc page. Lines that start with `#` are skipped.

```text
zsh tool	z name / zi	jump to a frequent folder / pick one with fzf (zoxide)	docs/zsh.md
```

Use an existing area name (`tmux plugin`, `zsh tool`, `terminal`, `nvim`, `command`) so related keys sort together. Keep real tab characters: many editors turn them into spaces.

## Add a new tool

1. Add it to the `[tools]` table of `mise/.config/mise/config.toml` (or to the `Brewfile` if mise has no build for macOS).
2. If it has a config, add a [package](glossary.md#package) (a top-level folder that mirrors your home folder) and add its name to `PACKAGES` in `install.sh`.
3. Describe its keys as above.
4. Document it in the matching page under `docs/`, and in [tools.md](tools.md) if it is a command-line tool.

## Check it worked

```sh
dotfiles-help --list | grep -i "your words"
```

Your new row appears with its area, keys, description and doc page. For tmux keys, reload first with `prefix r` (`prefix` is `Ctrl+Space`, pressed and released before the next key).

## Comments

Every config line here has a short comment, so the repo also works as a reference. When you add one:

- Explain why, or what is not obvious. Don't repeat what the line already says.
- Keep it short. One line is usually enough.
- Describe what the setting does, not who uses it or when you added it. History belongs in the commit message.

## How it works

`dotfiles-help` is a bash script that builds a table with four columns: area, keys, description, doc. It finds the repo by following its own link from `~/.local/bin` back into the clone, then reads:

1. `bind -N` lines from `tmux.conf`. It turns `C-` into `Ctrl+`, `M-` into `Alt+`, and an uppercase letter into `Shift+` plus the letter.
2. `alias` and `bindkey` lines with an end-of-line comment from `.zshrc`, and functions with a comment block above them.
3. Line 2 and the usage lines of every script in `bin/.local/bin/`.
4. Every line of `docs/cheatsheet.tsv` that does not start with `#`.

With fzf installed it shows the table as a searchable list. Without fzf it prints the table in a pager. `dotfiles-help --list` prints the raw table. tmux's own default keys are not in it: `prefix k` lists those.

## Related pages

- [first-day.md](first-day.md): the keys you'll use most.
- [tmux.md](tmux.md), [zsh.md](zsh.md), [nvim.md](nvim.md): every key, by tool.
- [glossary.md](glossary.md): the terms these docs use.
