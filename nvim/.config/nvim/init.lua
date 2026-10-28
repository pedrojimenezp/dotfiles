-- init.lua: entry point. Each require loads lua/<name>.lua.
vim.g.mapleader = " " -- Space is the leader key (must be set before plugins load)
vim.g.maplocalleader = " " -- same key for filetype-local maps
vim.g.have_nerd_font = true -- the terminal uses a Nerd Font (see Brewfile)

require("config.options") -- editor options
require("config.keymaps") -- general keymaps
require("config.autocmds") -- autocommands
require("config.lazy") -- bootstrap lazy.nvim and load lua/plugins/*
