# repo-structure-cleanup

## Goal
Four structural cleanups: shared test helpers, stow packages derived from folders, apt-style install output, one source for indirect tools.

## Plan
1. tests/lib.sh. 2. Package list in one sourced file. 3. install.sh prints like apt. 4. dotfiles-usage reads `# indirect` tags.

## Done
- 1: tests/lib.sh (ok, bad, check, check_eq, contains, summary).

## Where we stopped
Item 1 committed.

## Next step
Item 2.

## How to test
`bash tests/run.sh`

## Open questions
None.

Updated: 2026-11-14 by personal@Pedros-MacBook-Pro-M4
