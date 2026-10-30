# zsh-compinit-insecure
## Goal
Stop the daily compinit insecure-directories prompt.
## Plan
chmod go-w Homebrew dirs in install.sh; skip the prompt in .zshrc when owners are safe.
## Done
Both changes, docs, tests.
## Where we stopped
Ready to merge.
## Next step
Merge.
## How to test
zsh -n zsh/.zshrc; shellcheck install.sh; ./install.sh --dry-run
## Open questions
None.
Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
