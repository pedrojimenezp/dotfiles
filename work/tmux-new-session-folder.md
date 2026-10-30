# Goal
prefix N creates a session in any folder (name prompt, then folder prompt pre-filled with the pane's path).

# Plan
Two-prompt command-prompt with -I; keep the name sanitizing; update docs/tmux.md and README.

# Done
Binding changed and tested on tmux 3.8 through a pty client; docs updated.

# Where we stopped
Ready to merge.

# Next step
Merge to master.

# How to test
Throwaway `tmux -L outer` running `tmux -L inner attach`; send C-Space N, name, Enter, folder, Enter.

# Open questions
A nonexistent folder is accepted silently (tmux falls back to its own cwd).

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
