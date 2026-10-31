# install-find-brew

## Goal
install.sh finds Homebrew in the standard prefixes when `brew` is not on PATH (fresh bash SSH login on Ubuntu).

## Plan
Search the prefixes, eval `shellenv`; headless Linux gets the non-interactive install command; update docs/install.md.

## Done
- Detection loop in install.sh (same prefixes as zsh/.zshrc plus ~/.linuxbrew).
- Headless Linux "not found" message with NONINTERACTIVE=1 and the shellenv line.
- docs/install.md updated.
- bash -n, shellcheck, dry-runs (brew found with a stripped PATH; both not-found branches in a scratch copy).

## Where we stopped
Committed, ready for review.

## Next step
Review, then /merge.

## How to test
`env PATH=/usr/bin:/bin ./install.sh --dry-run` on a machine with brew in a standard prefix.

## Open questions
zsh/.zshrc does not list ~/.linuxbrew; add it there too?

Updated: 2026-10-30 by personal@Pedros-MacBook-Pro-M4.local
