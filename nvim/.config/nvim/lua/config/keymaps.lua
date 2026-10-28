-- General keymaps. Plugin-specific maps live next to each plugin.
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Leave insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Windows: Ctrl-h/j/k/l are handled by vim-tmux-navigator (works across tmux panes too).
-- Splits use the built-in Ctrl-w v / Ctrl-w s (<leader>s is the Search group).

-- Move lines (Alt-j / Alt-k), as in the old vimrc.
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep the selection when indenting in visual mode.
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Center the screen after half-page jumps and search.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })

-- Diagnostics.
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })

-- Toggle light/dark: the `theme` script recolors the terminal, then nvim follows.
map("n", "<leader>ut", function()
  if vim.fn.executable("theme") == 1 then -- the script lives in ~/.local/bin
    local res = vim.system({ "theme", "toggle", "--print" }, { text = true }):wait() -- sync, returns escape codes
    if res.code == 0 and res.stdout then vim.api.nvim_ui_send(res.stdout) end -- send them to the terminal
    local state = vim.trim(vim.system({ "theme", "status" }, { text = true }):wait().stdout or "") -- new saved state
    if state == "dark" or state == "light" then
      vim.o.background = state -- match the terminal
      return
    end
  end
  vim.o.background = vim.o.background == "dark" and "light" or "dark" -- fallback: flip only nvim
end, { desc = "Toggle light/dark theme" })
