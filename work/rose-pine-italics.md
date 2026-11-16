# rose-pine-italics

## Goal
Rose Pine themes italicize only comments and real emphasis (Markdown/HTML), not variables, parameters or properties.

## Plan
Set `styles.italic = false` in the rose-pine opts and re-enable italic on Comment, @markup.italic, @text.emphasis, htmlItalic.

## Done
- opts added in nvim/.config/nvim/lua/plugins/theme.lua.
- Headless check and tests/run.sh pass.

## Where we stopped
Done; ready for review.

## Next step
Review and merge.

## How to test
`bash tests/nvim_themes_test.sh`, `bash tests/run.sh`; headless: setup() with the opts, load rose-pine-main, check @variable italic is nil and Comment italic is true.

## Open questions
None. tests/nvim_themes_test.sh sets the rtp directly and bypasses lazy opts, so it cannot see this setting.

Updated: 2026-11-16 by personal@Pedros-MacBook-Pro-M4
