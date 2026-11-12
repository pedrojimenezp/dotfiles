vim.g.mapleader = " " -- before plugins load
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.winbar").setup()
require("config.lazy")
require("config.theme").setup() -- needs the plugins above
