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
- Template maps `Cmd+V` (`0x76-0x100000`) to action 60 `dotfiles_image_paste()`; `pngpaste` in the Brewfile.
- Docs: terminals.md section (setup, use, files, limits, troubleshooting), server.md Daily use line, cheatsheet.tsv, README index. Link check clean.

## Where we stopped

Feature and docs done; not tried in a live iTerm yet.

## Next step

User tests in iTerm (one-time setup in docs/terminals.md), then /merge.

## How to test

`python3 -I tests/iterm_image_paste_test.py`. In iTerm: see docs/terminals.md.

## Open questions

- The local iTerm Python runtime (`iterm2env/versions/manual`) links to a missing Homebrew Python 3.14: reinstall it from Scripts > Manage.
- Live iTerm behavior (jobName for the `tssh` function, symlinked AutoLaunch script) is not verified by the agent.

Updated: 2026-10-31 by personal@Pedros-MacBook-Pro-M4
