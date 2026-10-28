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
