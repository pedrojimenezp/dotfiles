return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
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
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>s", group = "Search" },
        { "<leader>f", group = "Files" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Hunks" },
        { "<leader>d", group = "Diagnostics/symbols" },
        { "<leader>u", group = "UI" },
      },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false, -- so `nvim <dir>` opens oil
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { view_options = { show_hidden = true } },
    keys = { { "-", "<cmd>Oil<CR>", desc = "Open parent directory (oil)" } },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = { { "<leader>fe", "<cmd>Neotree toggle reveal left<CR>", desc = "File explorer (neo-tree)" } },
    opts = {
      window = { mappings = { ["<space>"] = "none" } }, -- keep Space as the leader in the tree
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "disabled", -- directories open in oil
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          never_show = { ".git", ".zig-cache", "zig-out" },
        },
      },
    },
  },
  {
    "nvim-mini/mini.nvim",
    event = "VeryLazy",
    config = function()
      require("mini.surround").setup()
      require("mini.ai").setup({ n_lines = 500 })
      local statusline = require("mini.statusline")
      statusline.setup({ use_icons = vim.g.have_nerd_font })
      statusline.section_location = function() return "%2l:%-2v" end
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Move to left split/pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Move to lower split/pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Move to upper split/pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Move to right split/pane" },
    },
  },
}
