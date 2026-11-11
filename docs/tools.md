# Tools

The tool list is `mise/.config/mise/config.toml` (per user, no sudo, macOS and Linux) plus the `Brewfile` (macOS: mise, stow, btop, pngpaste, chafa, skhd, apps, font). zsh plugins are git clones in `~/.local/share/zsh-plugins`. A missing tool never breaks the shell.

## Add or upgrade a tool

- Add `name = "latest"` under `[tools]` (find the name with `mise registry | grep <tool>`), then `mise install`. No mise build for one OS: `{ version = "latest", os = ["linux"] }` plus a `Brewfile` line for the other.
- `install.sh` never upgrades: `mise upgrade` (see [Update](install.md#update)).
- `mise use -g ...` edits the repo file through the link: commit it.
- `zig` and `zls` are pinned to one version: change them together.

## mise per project

- `mise use node@22 go@1.25` writes a `mise.toml` to commit; versions switch on `cd`. `.nvmrc` and `.node-version` work too (run `mise install`).
- Secrets go in an untracked `mise.local.toml`.
- `.zshrc` activates mise early, so its tools beat Homebrew copies.
- mise tools bring no zsh completions: load them from `~/.zshrc.local` ([zsh.md](zsh.md#completions-for-mise-tools)).

## Not from mise

- **chafa** on Linux: mise has no build; `sudo apt-get install -y chafa`. In tmux it relies on `allow-passthrough on`; images can vanish on redraw.
- **Ghostty** on Linux: your distro's package.

## Prompt (starship)

`starship/.config/starship.toml`. Over SSH the user shows as `user@host`, from `PROMPT_HOST` that `.zshrc` exports (`HOST_LABEL` or the short hostname); root is red. Icons are `\uXXXX` escapes so editors can't strip them. Modules time out at 500 ms. `starship explain` shows what each part is.

## mermaid-ascii

Only flowcharts (`graph`/`flowchart`) and `sequenceDiagram`; other types fail with "unsupported graph type". Copy a `mermaid` block into a `.mmd` file first.

## dotfiles-usage

`dotfiles-usage [week|2weeks|month]` counts how often each tool ran, unused ones last (`← unused`) as removal candidates. Tools come from the `Brewfile`, mise config, `bin/` and `tssh`; aliases count for their tool. Tools that other programs run (`shellcheck`, `shfmt`, `golangci-lint`, `tree-sitter`, `git-lfs`, `zls`, `pngpaste`) are not listed. Counts come from `~/.zsh_history` (undercounts repeats because of `HIST_IGNORE_ALL_DUPS`; first word of each pipe or chain part only) plus `dotfiles-log`, which key-launched scripts call to append to `~/.local/state/dotfiles/usage.log`. `img-to-server` and the other key-launched scripts log each run; `theme` logs only runs you start, not `apply` or `sync`. Delete the log to reset.
