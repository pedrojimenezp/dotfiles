# img-to-server-skhd

## Goal
Trigger `img-to-server` with skhd.zig (Ctrl+Cmd+V) instead of a Shortcuts Quick Action, and paste without System Events.

## Plan
1. Brewfile: tap and cask for skhd-zig.
2. New stow package `skhd` (macOS only) with the binding.
3. `img-to-server`: paste with Quartz key events, no System Events, run log, iTerm not-authorized fallback.
4. Docs and tests.

## Done
- All four steps, with unit tests (stubbed Quartz, no real keys) and docs/terminals.md rewritten.
- skhd-zig is a Homebrew cask, not a formula: Brewfile uses `cask "jackielii/tap/skhd-zig"`; app at ~/Applications/skhd.app.
- skhd runs commands as `$SHELL -c` (default /bin/bash), so `$HOME` expands in skhdrc without pinning a shell.

## Where we stopped
Implementation and tests done in the worktree; nothing tested on a real Mac yet.

## Next step
User runs the one-time setup in docs/terminals.md and tests Ctrl+Cmd+V in Ghostty and iTerm2.

## How to test
Setup steps in docs/terminals.md ("Paste an image to a server (any terminal)"), then copy an image, focus an ssh tab, press Ctrl+Cmd+V. Check `~/Library/Logs/img-to-server.log` and `~/Library/Logs/skhd.log`.

## Open questions
- Does a posted Cmd+V work while Ctrl is still physically held? (Flags are set to Command only.)
- Does the iTerm2 Automation prompt appear for skhd, and does the fallback work if it is refused?

Updated: 2026-11-07 by niche@Pedros-MacBook-Pro-M4
