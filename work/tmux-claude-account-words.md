# tmux-claude-account-words

## Goal
Window list shows the full account word (●personal / ●work) when the client is wide, ●p / ●w when narrower than a minimum width (user option, default 120).

## Plan
1. Use #{client_width} in the label formats with a named option @claude_label_min_width.
2. Update the comment and docs/tmux.md.
3. Test on a private tmux server.

## Done
Nothing yet.

## Where we stopped
Note created.

## Next step
Edit tmux.conf.

## How to test
Private server (`env -u TMUX tmux -S <temp socket>`), set @claude_account on panes, render window-status formats.

## Open questions
Whether client_width resolves without an attached client.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
