# nvim-winbar-path

## Goal
Show the file path (relative to the cwd) in the winbar and drop the filename from the mini.statusline.

## Plan
- `lua/config/winbar.lua`: global winbar via a Lua render function, empty for special buffers and floats.
- `lua/plugins/editor.lua`: custom `content.active` without the filename section.

## Done
- Winbar module (dim dir, bold name, `[+]` modified, NC variants), wired in init.lua.
- Statusline active content without filename.
- Headless checks: file, modified, help winbar and statusline.

## Where we stopped
Implemented and tested headless; not tried in a real UI.

## Next step
Eyeball it in a real session with a few schemes and splits.

## How to test
`XDG_CONFIG_HOME=<worktree>/nvim/.config nvim` and open a nested file, a split and `:help`.

## Open questions
None.

Updated: 2026-11-12 by personal@Pedros-MacBook-Pro-M4
