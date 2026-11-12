-- Winbar with the file path relative to the cwd: dimmed directory, bold name, "[+]" when modified.
-- Windows showing a buffer with a 'buftype' (help, terminal, quickfix, prompts) or a floating
-- window get no winbar.
local M = {}

local function hl(name, src, extra)
  local base = vim.api.nvim_get_hl(0, { name = src, link = false })
  vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", base, extra or {}))
end

-- Derived from the scheme's groups; schemes clear custom groups, so this reruns on ColorScheme.
function M.set_highlights()
  hl("WinbarDir", "Comment", { italic = false })
  hl("WinbarDirNC", "Comment", { italic = false })
  hl("WinbarFile", "WinBar", { bold = true })
  hl("WinbarFileNC", "WinBarNC", { bold = true })
end

-- Winbar contents of the window being drawn ('statusline' expression context).
function M.render()
  local win = vim.g.statusline_winid
  if not win or win == 0 then win = vim.api.nvim_get_current_win() end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or vim.api.nvim_win_get_config(win).relative ~= "" then return "" end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then name = "[No Name]" end
  local path = vim.fn.fnamemodify(name, ":~:.")
  local nc = win == vim.api.nvim_get_current_win() and "" or "NC"
  local dir, file = path:match("^(.*/)([^/]*)$")
  if not dir then dir, file = "", path end
  local function esc(str) return (str:gsub("%%", "%%%%")) end
  local modified = vim.bo[buf].modified and " [+]" or ""
  return ("%%#WinbarDir%s#%s%%#WinbarFile%s#%s%s%%*"):format(nc, esc(dir), nc, esc(file), modified)
end

function M.setup()
  M.set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("user_winbar", { clear = true }),
    desc = "Rebuild winbar highlights",
    callback = M.set_highlights,
  })
  vim.o.winbar = "%{%v:lua.require'config.winbar'.render()%}"
end

return M
