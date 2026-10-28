-- Bootstrap lazy.nvim (plugin manager) and load every file in lua/plugins/.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim" -- where lazy.nvim is stored
if not (vim.uv or vim.loop).fs_stat(lazypath) then -- clone it on first run
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then error("Failed to clone lazy.nvim:\n" .. out) end
end
vim.opt.rtp:prepend(lazypath) -- make lazy.nvim loadable

require("lazy").setup({
  spec = { { import = "plugins" } }, -- each lua/plugins/*.lua returns plugin specs
  install = { colorscheme = { "tokyonight" } }, -- theme used while installing
  checker = { enabled = false }, -- no background update checks
  change_detection = { notify = false }, -- no popup when config files change
})
