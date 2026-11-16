#!/usr/bin/env bash
# Tests nvim's config/mermaid.lua: block lookup (cursor inside, on either fence, outside, two blocks)
# the float with the mermaid-ascii output, and open() (block under the cursor vs the whole buffer, with a
# stub md-open on PATH that records its arguments and stdin). Offline, no plugins.
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

local rec = vim.env.MO_STUB_OUT
vim.cmd("enew")
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
local function opened(row)
  vim.fn.delete(rec)
  vim.fn.delete(rec .. ".args")
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  m.open()
  return vim.fn.filereadable(rec) == 1 and table.concat(vim.fn.readfile(rec), "|") or nil
end
local function args() return table.concat(vim.fn.readfile(rec .. ".args"), " ") end
vim.api.nvim_buf_set_name(0, vim.fn.getcwd() .. "/sub/notes.md")
local dir = vim.fn.expand("%:p:h")
check("open: cursor in block sends only it", opened(4) == "graph LR|A --> B")
check("open: block args", args() == "--name notes.md:2 -")
check("open: second block", opened(12) == "graph TD|C --> D")
check("open: outside sends the buffer", opened(6) == table.concat(lines, "|"))
check("open: whole-buffer args", args() == "--name notes.md --dir " .. dir .. " -")
check("open: other fence sends the buffer", opened(8) == table.concat(lines, "|"))
vim.api.nvim_buf_set_lines(0, 3, 4, false, { "A --> Z" })
check("open: unsaved edit is sent", opened(3) == "graph LR|A --> Z")
local seen
vim.notify = function(msg, level) seen = level end
vim.env.MO_STUB_FAIL = "1"
opened(4)
check("open: failure is reported", seen == vim.log.levels.ERROR)
io.stdout:write(#problems == 0 and "ok" or table.concat(problems, "; "))
'

STUB="$(mktemp -d)"
trap 'rm -rf "$STUB"' EXIT
cat >"$STUB/md-open" <<'EOS'
#!/bin/sh
[ -n "${MO_STUB_FAIL:-}" ] && { echo "boom" >&2; exit 1; }
printf '%s\n' "$*" >"$MO_STUB_OUT.args"
cat >"$MO_STUB_OUT"
EOS
chmod +x "$STUB/md-open"
export MO_STUB_OUT="$STUB/stdin"
PATH="$STUB:$PATH"

out="$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$SRC/nvim/.config/nvim" \
  -c "lua $LUA" -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
if [[ "$out" == ok ]]; then
  echo "  ok   mermaid block lookup, float and open"
else
  echo "  FAIL $out"
  exit 1
fi
