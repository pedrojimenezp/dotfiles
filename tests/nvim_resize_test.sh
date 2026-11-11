#!/usr/bin/env bash
# Tests the VimResized autocmd in nvim's config/autocmds.lua: the non-fixed windows of every tab
# are rebalanced and a 'winfixwidth' window keeps its width. Offline, no plugins.
# Run: bash tests/nvim_resize_test.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v nvim >/dev/null; then
  echo "nvim not installed: skipped"
  exit 0
fi

LUA='
local function widths(tab)
  local r = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do r[#r + 1] = { w = w, width = vim.api.nvim_win_get_width(w), fixed = vim.wo[w].winfixwidth } end
  return r
end
local function setup()
  vim.cmd("silent only | vsplit | vsplit")
  local wins = vim.api.nvim_tabpage_list_wins(0)
  vim.wo[wins[3]].winfixwidth = true
  vim.api.nvim_win_set_width(wins[3], 10)
  vim.api.nvim_win_set_width(wins[1], 50)
end
setup()
vim.cmd("tabnew")
setup()
local first = vim.api.nvim_list_tabpages()[1]
local second = vim.api.nvim_get_current_tabpage()
vim.api.nvim_set_current_tabpage(first)
vim.cmd("doautocmd VimResized")
local problems = {}
for i, tab in ipairs({ first, second }) do
  local free = {}
  for _, w in ipairs(widths(tab)) do
    if w.fixed then
      if w.width ~= 10 then table.insert(problems, "tab " .. i .. " fixed width " .. w.width) end
    else free[#free + 1] = w.width end
  end
  if math.abs(free[1] - free[2]) > 1 then table.insert(problems, "tab " .. i .. " unbalanced " .. free[1] .. "/" .. free[2]) end
end
if vim.api.nvim_get_current_tabpage() ~= first then table.insert(problems, "current tab not restored") end
io.stdout:write(#problems == 0 and "ok" or table.concat(problems, "; "))
'

out="$(nvim --headless -u NONE -i NONE --cmd "set rtp^=$SRC/nvim/.config/nvim" \
  -c "lua require('config.autocmds')" -c "lua $LUA" -c "qa!" 2>&1 | tr -d '\r' | tail -n 1)"
if [[ "$out" == ok ]]; then
  echo "  ok   VimResized rebalances every tab and keeps winfixwidth"
else
  echo "  FAIL $out"
  exit 1
fi
