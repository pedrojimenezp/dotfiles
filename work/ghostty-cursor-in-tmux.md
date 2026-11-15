# ghostty-cursor-in-tmux

## Goal
Ghostty cursor is a bar and theme-independent in colour, so it looks the same inside and outside tmux.

## Plan
Set cursor-style = bar and cursor-color = cell-foreground in ghostty/.config/ghostty/config.

## Done
- Added both settings near the shell-integration lines, with a short why-comment.
- Validated the config with ghostty +validate-config.

## Where we stopped
Committed on branch ghostty-cursor-in-tmux; not pushed or merged.

## Next step
Manual check (below), then /merge.

## How to test
Reload Ghostty (cmd+shift+r), then check the cursor is a bar and visible at the zsh prompt inside and outside tmux, and in Claude Code.

## Open questions
None.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
