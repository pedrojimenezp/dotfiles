# picker-speed

## Goal
Make the tmux-new-session folder popup show fast on macOS (was ~1.6s).

## Plan
1. Skip the linuxbrew PATH entry on macOS (autofs on /home) and add only existing dirs.
2. Replace basename/dirname forks in tmux-sessionizer with parameter expansion.

## Done
Nothing yet.

## Where we stopped
Starting.

## Next step
Edit both scripts.

## How to test
Compare tmux-sessionizer --list before/after with diff; time tmux-new-session --list "$HOME".

## Open questions
None.

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
