# zsh-history-lock

## Goal
Stop multi-second hangs after leaving tmux or running `exec zsh`, and stop leftover cache temp files.

## Plan
1. Add `setopt HIST_FCNTL_LOCK` to the history section of zsh/.zshrc.
2. Make `_cache_init` remove `<cache>.<pid>` leftovers before regenerating.
3. Add tests/zshrc_test.sh and a line in docs/zsh.md.

## Done
- All three steps. Lock wait with a held .LOCK file: 10 s before, about 1 s or less after.

## Where we stopped
Implemented and tested on branch zsh-history-lock. Not pushed or merged.

## Next step
Review, then /merge.

## How to test
`bash tests/zshrc_test.sh`, plus the other scripts in tests/.

## Open questions
None.

Updated: 2026-11-02 by personal@Pedros-MacBook-Pro-M4
