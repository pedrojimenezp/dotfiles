-- Plugin maps live in their specs.
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Leave insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Cmd+K sends NUL, which in insert mode would insert the last text.
map("i", "<C-@>", "<Nop>", { desc = "Ignore NUL" })
map("i", "<C-Space>", "<Nop>", { desc = "Ignore NUL" })

-- Splits: built-in Ctrl-w v / Ctrl-w s, since <leader>s is Search.
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })

map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })

-- `theme` recolors the terminal; the 'background' change then loads the other slot.
map("n", "<leader>ut", function()
  if vim.fn.executable("theme") == 1 then
    local res = vim.system({ "theme", "toggle", "--print" }, { text = true }):wait() -- returns escape codes
    if res.code == 0 and res.stdout then vim.api.nvim_ui_send(res.stdout) end
    local state = vim.trim(vim.system({ "theme", "mode" }, { text = true }):wait().stdout or "") -- toggle always saves dark or light
    if state == "dark" or state == "light" then
      vim.o.background = state
      return
    end
  end
  vim.o.background = vim.o.background == "dark" and "light" or "dark" -- fallback: flip only nvim
end, { desc = "Toggle light/dark theme" })

map("n", "<leader>uw", "<cmd>set wrap!<CR>", { desc = "Toggle line wrap" })

-- With a count (5j), move by real line.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down (screen line)" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up (screen line)" })
