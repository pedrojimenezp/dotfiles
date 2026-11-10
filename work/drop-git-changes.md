# drop-git-changes

## Goal
Remove `git wip` / `git pr`; reviewing happens only in Neovim.

## Plan
Remove aliases, `git-changes`, its test; fold delta/lazygit lines into docs/git.md "Reviewing in Neovim"; clean cheatsheet; run tests.

## Done
All removals and doc edits; tests/run.sh run.

## Where we stopped
Committed on the branch, not merged.

## Next step
Main chat: remove the installed `git-changes` symlink, then merge.

## How to test
`tests/run.sh`; `dotfiles-help --list | grep -i git`.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
