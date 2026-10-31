# tpm-isolated-server

## Goal
Make the installer's tmux plugin install independent of any running tmux server, and warn when a login shell would start an old system tmux.

## Plan
1. Run TPM install on a private throwaway server (env -u TMUX, own TMUX_TMPDIR, kill by socket path).
2. Extend the "Your login shell is ..." message with a system tmux < 3.5 warning.

## Done
- Both fixes in install.sh; docs/install.md step 8 updated.
- Tested: bash -n, shellcheck, --dry-run; temp-HOME repro inside a simulated "user" server: plugins installed, user server survived.

## Where we stopped
Ready to merge.

## Next step
Review and /merge.

## How to test
`bash -n install.sh && shellcheck install.sh && ./install.sh --dry-run`. Real check: run the installer inside tmux on a fresh machine; on Ubuntu with bash login shell and tmux < 3.5, the final message shows the warning.

## Open questions
Add `brew shellenv` to ~/.profile for bash users? Not done (touches user shell config).

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4
