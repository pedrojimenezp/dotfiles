# tmux-audit-cleanup

## Goal
Drop tmux.conf settings that equal tmux 3.7 defaults; min tmux is now 3.7.

## Plan
1. Header, remove default-equal lines, move bell comment, add why-comments.
2. Update docs/tmux.md requirements.

## Done
- tmux.conf and docs/tmux.md edited and verified on a private server (defaults unchanged); tests pass.

## Where we stopped
Batch 1 done; install.sh and mise comment moved to 3.7. Item 2: prefix N and tmux-new-session removed; tmux-sessionizer gained zoxide entries, typed paths and preview; tests extended. Item 3: @pane_program defined once in tmux.conf. More items may be added.

## Next step
Wait for more items.

## How to test
Load the config on a private tmux server (-S temp socket); check escape-time 10, monitor-bell on, bell-action any, visual-bell off, automatic-rename on, C-v rectangle-toggle in copy-mode-vi; run `bash tests/run.sh`.

## Open questions
None.

Updated: 2026-11-13 by personal@Pedros-MacBook-Pro-M4
