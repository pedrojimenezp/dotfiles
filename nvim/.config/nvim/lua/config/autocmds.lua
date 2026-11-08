-- One group, so re-sourcing doesn't duplicate autocmds.
local group = vim.api.nvim_create_augroup("user_config", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore last cursor position",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lines = vim.api.nvim_buf_line_count(args.buf) -- guard against stale marks
    if mark[1] > 0 and mark[1] <= lines then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = group,
  desc = "Check for external file changes",
  command = "checktime",
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "go", "gomod" },
  desc = "Tabs for Go",
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

-- Follow mode or theme changes made outside nvim (`theme pick`, `tt`, macOS).
vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  desc = "Sync colors with the dotfiles theme",
  nested = true, -- so the 'background' change fires OptionSet
  callback = function() require("config.theme").sync() end,
})
