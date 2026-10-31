# tmux-claude-account

## Goal
Show which Claude Code account (personal or work) runs in a tmux pane, in the window list and the pane border. Contract: pane option `@claude_account` = `personal` or `work`, set while Claude runs and unset on exit (set by the user's `claude` shell function).

## Plan
1. Window list: a colored `●p` / `●w` per pane that has the option.
2. Pane border: colored `●personal` / `●work` after the command name.
3. Document in docs/tmux.md; test on a private tmux server.

## Done
tmux.conf: window-list marks (@claude_window_label[_current]) and pane-border account text; docs/tmux.md; tested on a private server.

## Where we stopped
Code and docs done, link check run.

## Next step
Merge when the user agrees (needs the claude-account-label branch of the shared config for the option to be set).

## How to test
Private server (`env -u TMUX tmux -S <temp socket> -f tmux.conf`), `set -p @claude_account personal`, check `list-windows -F` and `display -p`.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
