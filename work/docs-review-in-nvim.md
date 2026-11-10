# docs-review-in-nvim

## Goal
Add a "Reviewing in Neovim" guide to docs/git.md and link it from the cheatsheet and tmux docs.

## Plan
Insert section after "Reviewing changes"; update cheatsheet rows; add a prefix R line to docs/tmux.md; run tests/run.sh.

## Done
Section inserted verbatim; cheatsheet doc column and a diffview gd row; tmux.md line for prefix R.

## Where we stopped
Tests passed.

## Next step
Merge when approved.

## How to test
tests/run.sh; dotfiles-help --list | grep -iE 'review|diffview'.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
