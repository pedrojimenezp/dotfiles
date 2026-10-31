# tmux-claude-account-words

## Goal
Window list shows the full account word (●personal / ●work) when the client is wide, ●p / ●w when narrower than a minimum width (user option, default 120).

## Plan
1. Use #{client_width} in the label formats with a named option @claude_label_min_width.
2. Update the comment and docs/tmux.md.
3. Test on a private tmux server.

## Done
tmux.conf: labels use #{client_width} against @claude_label_min_width (default 120). docs/tmux.md updated. Tested with a control-mode client at 200/100/119/120 columns: full words at 120+, p/w below. Link check: 0 broken.

## Where we stopped
Change done and committed.

## Next step
Review, then merge.

## How to test
Private server (`env -u TMUX tmux -S <temp socket>`), set @claude_account on panes, render window-status formats.

## Open questions
None. client_width is empty without a client (reads as 0, so short form).

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
