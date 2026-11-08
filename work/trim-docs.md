# trim-docs

## Goal
Cut docs from ~139 KB to ~55 KB and config comments to the why only. The repo is for its owner.

## Plan
1. Docs: README, contributing, delete glossary/first-day/vim, merge tmux-sessionizer into tmux, trim each doc to target.
2. Config comments per package: zsh, tmux, nvim, git, ghostty, mise, Brewfile, install/uninstall, bin.
3. Tests, syntax checks, link check.

## Done
- Docs rewritten for the owner: 139 KB -> 37 KB; glossary, first-day, vim, tmux-sessionizer removed (sessionizer merged into tmux.md). Link check clean.

## Where we stopped
Docs committed.

## Next step
Config comments, one commit per package.

## How to test
`bash tests/run.sh`; `zsh -n zsh/.zshrc`; tmux on a private socket with `-f tmux/.config/tmux/tmux.conf`; nvim headless with temp XDG dirs; relative link check over README and docs/.

## Open questions
None.

Updated: 2026-11-07 by personal@Pedros-MacBook-Pro-M4
