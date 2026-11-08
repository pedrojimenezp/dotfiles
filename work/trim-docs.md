# trim-docs

## Goal
Cut docs from ~139 KB to ~55 KB and config comments to the why only. The repo is for its owner.

## Plan
1. Docs: README, contributing, delete glossary/first-day/vim, merge tmux-sessionizer into tmux, trim each doc to target.
2. Config comments per package: zsh, tmux, nvim, git, ghostty, mise, Brewfile, install/uninstall, bin.
3. Tests, syntax checks, link check.

## Done
- Docs rewritten for the owner: 139 KB -> 37 KB; glossary, first-day, vim, tmux-sessionizer removed (sessionizer merged into tmux.md). Link check clean.
- Comments trimmed: zsh, tmux, git, ghostty, mise, Brewfile, nvim (code unchanged, checked by stripping comments and diffing).
- install.sh, uninstall.sh, bin scripts, starship, skhd, theme, vimrc, iTerm template trimmed. Comment lines 1335 -> 582.
- tests/run.sh, zsh -n, tmux load on a private socket, nvim headless with temp XDG, vim, starship print-config, link check: all pass.

## Where we stopped
All planned work done; not pushed or merged.

## Next step
Owner review of the docs (37 KB, below the ~55 KB target), then /merge.

## How to test
`bash tests/run.sh`; `zsh -n zsh/.zshrc`; tmux on a private socket with `-f tmux/.config/tmux/tmux.conf`; nvim headless with temp XDG dirs; relative link check over README and docs/.

## Open questions
None.

Updated: 2026-11-07 by personal@Pedros-MacBook-Pro-M4
