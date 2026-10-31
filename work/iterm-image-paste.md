# iTerm image paste over SSH

## Goal

In iTerm2 on macOS, `Cmd+V` in a tab whose foreground job is `ssh` (also `tssh`) with an image on the clipboard asks "Upload image to <host>?". Upload saves the image with `pngpaste`, copies it to `/tmp/claude-img/<timestamp>.png` on that host only (old files cleaned), and types the remote path. Every other case is iTerm's normal Paste. iTerm2 only; not Ghostty.

## Plan

1. iTerm2 Python API AutoLaunch script in the `iterm` stow package, with pure helpers (ssh argv parsing, upload command) and unit tests in `tests/`.
2. `Cmd+V` in the Dynamic Profile template: Invoke Script Function.
3. `pngpaste` in the Brewfile.
4. Docs: terminals.md section, server.md link, cheatsheet.tsv, README if relevant.

## Done

- Work note.
- Script `iterm/Library/Application Support/iTerm2/Scripts/AutoLaunch/dotfiles_image_paste.py` (stowed into AutoLaunch) and `tests/iterm_image_paste_test.py` (21 tests pass). `.gitignore` now ignores only the old DynamicProfiles path.

## Where we stopped

Script and tests done.

## Next step

Cmd+V mapping in the profile template, Brewfile, docs.

## How to test

`python3 -I tests/iterm_image_paste_test.py`. In iTerm: see docs/terminals.md.

## Open questions

- Live iTerm behavior (jobName for the `tssh` function, symlinked AutoLaunch script) is not verified by the agent.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
