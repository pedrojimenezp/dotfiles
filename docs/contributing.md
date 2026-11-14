# Contributing

`dotfiles-help` reads descriptions from the config every time it runs, so describe a key where you define it:

- **tmux:** `bind -N "note" ...`. A `bind` without `-N` is missing from the list; `grep -E '^\s*bind' tmux/.config/tmux/tmux.conf | grep -v -- ' -N '` finds them.
- **zsh:** an end-of-line ` # comment` on an `alias` or `bindkey`; for a function, a block above it starting `# name args: what it does`.
- **Neovim:** a `desc` on every map (which-key shows it). Plugin maps live in their spec in `lua/plugins/`.
- **Script** in `bin/.local/bin/`: a description on line 2, then `# Usage:` lines with the note after two or more spaces, in parentheses.
- **Plugin, tool or terminal keys** (no config line to describe them): a row in [cheatsheet.tsv](cheatsheet.tsv): `area<TAB>keys<TAB>description<TAB>doc`. Keep real tabs.

A new tool goes in the mise config (or the `Brewfile`); add `# indirect` to its line if other tools run it ([tools.md](tools.md#dotfiles-usage)). With a config, add a top-level folder for it: every folder except `docs`, `tests`, `work` and `worktrees` is a stow package, picked up by `install.sh`, `uninstall.sh` and the tests.

Check with `dotfiles-help --list | grep -i <words>` (reload tmux first), then run `tests/run.sh`: it runs every `tests/*_test.*` against temp folders and fails if one does. Tests never run brew, mise or clones from the network, never reload Ghostty and use a private tmux socket (`-S`) with `TMUX` unset: keep new ones that way.
