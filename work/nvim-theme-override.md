# nvim-theme-override

## Goal
Optional `nvim_light` / `nvim_dark` keys in the theme config so Neovim can use its own pair while the terminal keeps its own.

## Plan
1. Script: `set nvim-light|nvim-dark <name>`, `--clear`, `pick nvim-*`, status.
2. Lua: `read_config` resolves the override (so `M.applied` and focus sync notice changes).
3. Docs, tests.

## Done
- Script: set/--clear/pick/status for nvim-light and nvim-dark; Lua read_config resolves the override.
- docs/theme.md, docs/cheatsheet.tsv, tests/theme_test.sh (29 checks pass).

## Where we stopped
Finished; ready for review.

## Next step
Review, then /merge.

## How to test
`bash tests/theme_test.sh` or `tests/run.sh`.

## Open questions
None.

Updated: 2026-11-10 by personal@Pedros-MacBook-Pro-M4
