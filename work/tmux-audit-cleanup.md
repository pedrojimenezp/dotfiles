# tmux-audit-cleanup

## Goal
Drop tmux.conf settings that equal tmux 3.7 defaults; min tmux is now 3.7.

## Plan
1. Header, remove default-equal lines, move bell comment, add why-comments.
2. Update docs/tmux.md requirements.

## Done
- tmux.conf and docs/tmux.md edited and verified on a private server (defaults unchanged); tests pass.

## Where we stopped
Batch 1 done. More items may be added.

## Next step
Wait for more items. Not done: install.sh (line ~360) and mise config comment still say 3.5+.

## How to test
Load the config on a private tmux server (-S temp socket); check escape-time 10, monitor-bell on, bell-action any, visual-bell off, automatic-rename on, C-v rectangle-toggle in copy-mode-vi; run `bash tests/run.sh`.

## Open questions
Bump the 3.5 check in install.sh and the mise comment to 3.7?

Updated: 2026-11-13 by personal@Pedros-MacBook-Pro-M4
