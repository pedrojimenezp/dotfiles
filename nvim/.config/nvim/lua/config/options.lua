local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true
opt.showmode = false
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
opt.timeoutlen = 400 -- which-key's menu waits after Space; this limits only sequences without a menu
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.mouse = "a"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.completeopt = { "menu", "menuone", "noselect" }
opt.confirm = true

-- OSC 52 over SSH so yanks reach the local machine.
-- Scheduled: clipboard provider detection slows startup.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
  if vim.env.SSH_TTY then
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
      name = "OSC 52",
      copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
      -- Terminals often block OSC 52 reads, so paste from nvim's own register instead.
      paste = {
        ["+"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
        ["*"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
      },
    }
  end
end)
