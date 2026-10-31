# remove-atuin

## Goal
Drop atuin; go back to zsh history (Up/Down prefix search, Ctrl+R fzf). Plus fix the `ssh -O exit` wording.

## Plan
1. Remove the package, config, init, import, usage branch and docs; add legacy cleanup to install.sh.
2. Wording fix in a separate commit.

## Done
Atuin removed everywhere except legacy cleanup; ssh wording fixed (see commits).

## Where we stopped
Tests running / ready for review.

## Next step
Review, then /merge.

## How to test
`for t in tests/*.sh; do bash "$t"; done`, `python3 tests/iterm_image_paste_test.py`, `shellcheck install.sh uninstall.sh bin/.local/bin/dotfiles-usage`, `zsh -n zsh/.zshrc`.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
