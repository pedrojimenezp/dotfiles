# lazygit-repo-picker

## Goal
`prefix G` in a folder that only holds repos (a feature folder of worktrees) must not open a parent repo.

## Plan
Script `tmux-lazygit <dir>`: one repo below opens it, several ask with fzf, otherwise lazygit as before. Bind it in tmux.conf, document, test.

## Done
- bin/.local/bin/tmux-lazygit, tests/tmux_lazygit_test.sh, tmux.conf binding, docs/tmux.md, docs/install.md.

## Where we stopped
Implemented and tested; not merged.

## Next step
Review, then /merge.

## How to test
`bash tests/tmux_lazygit_test.sh`, then `prefix G` in a feature folder.

## Open questions
None.

Updated: 2026-11-04 by personal@Pedros-MacBook-Pro-M4
