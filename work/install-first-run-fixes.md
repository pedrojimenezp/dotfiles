# install-first-run-fixes

## Goal
Fix two first-run failures of install.sh on a fresh server: atuin import with no zsh history, and TPM plugin install with no tmux server.

## Plan
1. Skip the atuin import when there is no history file.
2. Install plugins inside a throwaway detached tmux session; make the Next steps line truthful.

## Done
- Both fixes in install.sh; docs/install.md updated.
- bash -n, shellcheck, --dry-run pass; TPM step tested in an isolated TMUX_TMPDIR.

## Where we stopped
Ready for review. Not pushed, not merged.

## Next step
Review, then /merge.

## How to test
bash -n install.sh; shellcheck install.sh; ./install.sh --dry-run

## Open questions
Local tmux 3.8 passes even without the fix; Ubuntu 24.04 (tmux 3.4) failure not reproduced here.

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
