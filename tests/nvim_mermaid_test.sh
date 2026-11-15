#!/usr/bin/env bash
# Tests nvim's config/mermaid.lua: block lookup (cursor inside, on either fence, outside, two blocks)
# and the float with the mermaid-ascii output. Offline, no plugins.
# Run: bash tests/nvim_mermaid_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v nvim >/dev/null; then
  echo "nvim not installed: skipped"
  exit 0
fi

LUA='
local m = require("config.mermaid")
local lines = {
  "# t",          -- 1
  "```mermaid",   -- 2
  "graph LR",     -- 3
  "A --> B",      -- 4
  "```",          -- 5
  "text",         -- 6
  "```lua",       -- 7
  "x = 1",        -- 8
  "```",          -- 9
  "```mermaid",   -- 10
  "graph TD",     -- 11
  "C --> D",      -- 12
  "```",          -- 13
}
local problems = {}
local function check(name, ok) if not ok then problems[#problems + 1] = name end end
local function body(row) local b = m.find_block(lines, row); return b and table.concat(b, "|") end
check("on opening fence", body(2) == "graph LR|A --> B")
check("inside", body(4) == "graph LR|A --> B")
check("on closing fence", body(5) == "graph LR|A --> B")
check("outside", body(6) == nil and body(1) == nil)
check("other fenced block", body(8) == nil)
check("second block", body(12) == "graph TD|C --> D")

if vim.fn.executable("mermaid-ascii") == 1 then
  vim.cmd("enew")
  vim.bo.filetype = "markdown"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  m.preview()
  local buf = vim.api.nvim_get_current_buf()
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  check("float shows output", text:find("A", 1, true) and text:find("B", 1, true) and text:find("►", 1, true))
  check("float read-only", vim.bo[buf].modifiable == false)
  vim.api.nvim_feedkeys("q", "x", false)
  check("q closes", vim.api.nvim_get_current_buf() ~= buf)
  check("file untouched", vim.deep_equal(before, vim.api.nvim_buf_get_lines(0, 0, -1, false)))
end
io.stdout:write(#problems == 0 and "ok" or table.concat(problems, "; "))
'

out="$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$SRC/nvim/.config/nvim" \
  -c "lua $LUA" -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
if [[ "$out" == ok ]]; then
  echo "  ok   mermaid block lookup and float"
else
  echo "  FAIL $out"
  exit 1
fi
