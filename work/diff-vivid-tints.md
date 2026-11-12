# diff-vivid-tints

## Goal
Diff tints read as green/red even when a colorscheme's green or red is dull (Dayfox green looked grey).

## Plan
In diff_colors.lua, replace a scheme red/green whose HSL saturation is below 0.32 with the mode's GitHub fallback colour. Each colour decided alone.

## Done
- vivid() + saturation() + min_saturation in diff_colors.lua, header updated.
- Tests: dull green, dull red and vivid fake themes in tests/nvim_diff_colors_test.sh.

## Where we stopped
Implemented and tested; not merged.

## Next step
Review, then /merge.

## How to test
bash tests/nvim_diff_colors_test.sh; tests/run.sh

## Open questions
Threshold 0.32 is tight against Dayfox (0.29) and base16 light green (0.34).

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
