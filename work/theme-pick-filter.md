# theme-pick-filter

## Goal
`theme pick <slot>` lists only themes of the slot's brightness; fzf ctrl-a toggles the full list. Add `theme list [light|dark]`.

## Plan
Classify by Rec. 601 luma of `background` (cutoff 0.5) in one grep + awk; unclassifiable names show in both lists; fzf reload via hidden `_list`, `_toggle`, `_pos`.

## Done
Script, tests, usage(), docs/theme.md.

## Where we stopped
Finished; fzf behaviour not exercised interactively.

## Next step
Try `theme pick dark` and ctrl-a in a real terminal.

## How to test
`tests/run.sh`; `theme list dark | wc -l`.

## Open questions
None.

Updated: 2026-11-11 by personal@Pedros-MacBook-Pro-M4
