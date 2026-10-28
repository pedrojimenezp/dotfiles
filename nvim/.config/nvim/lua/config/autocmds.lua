-- Autocommands, grouped so reloading the config does not duplicate them.
local group = vim.api.nvim_create_augroup("user_config", { clear = true })

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function() vim.hl.on_yank() end,
})

-- Reopen a file at the last cursor position.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore last cursor position",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"') -- the '"' mark stores the last position
    local lines = vim.api.nvim_buf_line_count(args.buf) -- guard against stale marks
    if mark[1] > 0 and mark[1] <= lines then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-- Reload files changed outside nvim when focus returns.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = group,
  desc = "Check for external file changes",
  command = "checktime",
})

-- Go uses real tabs (gofmt style).
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "go", "gomod" },
  desc = "Tabs for Go",
  callback = function()
    vim.bo.expandtab = false -- use tab characters
    vim.bo.tabstop = 4 -- display width of a tab
    vim.bo.shiftwidth = 4 -- indent width
  end,
})

-- Follow the saved theme (or macOS in auto mode) when focus returns, e.g. after toggling elsewhere.
vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  desc = "Sync background with the saved theme",
  callback = function()
    local dir = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state") -- same path as the theme script
    local ok, lines = pcall(vim.fn.readfile, dir .. "/theme", "", 1) -- first line of the state file
    local state = ok and lines[1] or "auto" -- missing file means auto
    local want ---@type string?
    if state == "dark" or state == "light" then
      want = state -- explicit choice
    elseif vim.fn.has("mac") == 1 then
      local res = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait() -- fails in light mode
      want = vim.trim(res.stdout or "") == "Dark" and "dark" or "light" -- follow macOS
    end
    if want and vim.o.background ~= want then vim.o.background = want end -- only change when different
  end,
})
