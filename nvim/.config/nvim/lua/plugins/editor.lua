-- Editing helpers: git signs, key hints, file explorer, mini.nvim, tmux navigation.
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- load when opening files
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc }) -- buffer-local map
        end
        map("n", "]c", function() -- in diff mode keep the built-in jump
          if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
        end, "Next hunk")
        map("n", "[c", function()
          if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
        end, "Previous hunk")
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", gs.blame_line, "Blame line")
      end,
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy", -- load after startup
    opts = {
      spec = {
        { "<leader>s", group = "Search" }, -- label for the telescope group
        { "<leader>g", group = "Git" }, -- label for the git group
        { "<leader>h", group = "Hunks" }, -- label for the gitsigns group
        { "<leader>d", group = "Diagnostics/symbols" }, -- label for the d group
        { "<leader>u", group = "UI" }, -- label for the ui group (theme toggle)
      },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false, -- load at startup so `nvim <dir>` opens oil
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- file icons
    opts = { view_options = { show_hidden = true } }, -- show dotfiles
    keys = { { "-", "<cmd>Oil<CR>", desc = "Open parent directory (oil)" } },
  },
  {
    "nvim-mini/mini.nvim",
    event = "VeryLazy", -- load after startup
    config = function()
      require("mini.surround").setup() -- sa/sd/sr: add, delete, replace surroundings
      require("mini.ai").setup({ n_lines = 500 }) -- better a/i text objects (function, argument, quote)
      local statusline = require("mini.statusline")
      statusline.setup({ use_icons = vim.g.have_nerd_font }) -- compact statusline
      statusline.section_location = function() return "%2l:%-2v" end -- show only line:column
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" }, -- load on first use
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Move to left split/pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Move to lower split/pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Move to upper split/pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Move to right split/pane" },
    },
  },
}
