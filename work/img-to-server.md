# img-to-server

## Goal
Copy any image on the Mac, switch to any terminal tab with an ssh session, press Ctrl-Cmd-V: the image is scp'd to that server and the remote path is pasted. Ask which server when it cannot be detected.

## Plan
1. `bin/.local/bin/img-to-server` (python3, stdlib, no iTerm API).
2. Move the iTerm binding to Ctrl-Opt-Cmd-V (`0x76-0x1c0000`).
3. Docs in `docs/terminals.md`.
4. Tests in `tests/img_to_server_test.py`.

## Done
- Clipboard rule: copied image file (one, image extension) uploads as is; image data uploads even with text types; else Cmd-V. A copied file wins over image data (Finder adds an icon image).
- Script, iTerm plist key move, docs, cheatsheet, tests (44 pass); iTerm tests and tests/*_test.sh pass.

## Where we stopped
Implementation finished, waiting for the user's real-machine test.

## Next step
User creates the macOS Shortcut (docs/terminals.md) and tests with a real ssh session.

## How to test
`img-to-server --dry-run` with an image on the clipboard and an ssh tab open; `python3 -I tests/img_to_server_test.py`.

## Open questions
- A copied non-image file that also carries image data pastes normally.
- The clipboard keeps the remote path after an upload.

Updated: 2026-11-07 by niche@Pedros-MacBook-Pro-M4
