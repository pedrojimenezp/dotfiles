# iterm-paste-safe-key

## Goal
Cmd+V must always be iTerm's normal Paste. The image upload script moves to a separate key, so paste never depends on the script running.

## Plan
1. Remove the Cmd+V mapping from the iTerm profile template.
2. Map the script to Cmd+Ctrl+V (Cmd+Shift+V is iTerm's Advanced Paste).
3. Update docs and cheatsheet; add a `theme sync` troubleshooting line.
4. Run tests, plutil lint, temp profile generation and the link check.

## Done
Nothing yet.

## Where we stopped
Work note created.

## Next step
Edit the template and docs.

## How to test
`python3 -I tests/iterm_image_paste_test.py`, `plutil -lint` on the template, generate the profile into a temp file and check the keys.

## Open questions
None.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
