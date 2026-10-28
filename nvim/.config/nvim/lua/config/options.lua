-- Editor options. `opt` is shorthand for vim.opt.
local opt = vim.opt

opt.number = true -- show line numbers
opt.relativenumber = true -- relative numbers for easy `5j` jumps
opt.signcolumn = "yes" -- always show the sign column (no text shifting)
opt.cursorline = true -- highlight the current line
opt.scrolloff = 8 -- keep 8 lines visible above/below the cursor
opt.sidescrolloff = 8 -- same for columns
opt.termguicolors = true -- true color
opt.showmode = false -- mode is shown in the statusline
opt.wrap = false -- no soft wrapping
opt.splitbelow = true -- :split opens below
opt.splitright = true -- :vsplit opens right
opt.ignorecase = true -- case-insensitive search...
opt.smartcase = true -- ...unless the pattern has capitals
opt.inccommand = "split" -- live preview of :substitute
opt.undofile = true -- persistent undo
opt.swapfile = false -- no swap files
opt.updatetime = 250 -- faster CursorHold and swap writes
opt.timeoutlen = 400 -- which-key's menu waits after Space, so this only limits sequences without a menu
opt.expandtab = true -- Tab inserts spaces
opt.tabstop = 2 -- a tab displays as 2 columns
opt.shiftwidth = 2 -- indent by 2 columns
opt.smartindent = true -- auto-indent new lines
opt.mouse = "a" -- mouse support
opt.list = true -- show whitespace characters
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- how whitespace is drawn
opt.completeopt = { "menu", "menuone", "noselect" } -- completion menu behavior
opt.confirm = true -- ask instead of failing on unsaved changes

-- Clipboard: system clipboard normally; OSC 52 over SSH so yanks reach the local machine.
-- Scheduled so startup is not slowed by clipboard provider detection.
vim.schedule(function()
  opt.clipboard = "unnamedplus" -- yank/paste use the system clipboard
  if vim.env.SSH_TTY then
    local osc52 = require("vim.ui.clipboard.osc52") -- built-in OSC 52 provider
    vim.g.clipboard = {
      name = "OSC 52",
      copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") }, -- copy via escape sequence
      -- Terminals often block OSC 52 reads, so paste from nvim's own register instead.
      paste = {
        ["+"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
        ["*"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
      },
    }
  end
end)
