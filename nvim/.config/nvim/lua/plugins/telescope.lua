return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<leader><leader>", function() require("telescope.builtin").buffers() end, desc = "Find open buffers" },
    { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Search files" },
    { "<leader>sg", function() require("telescope.builtin").live_grep() end, desc = "Search by grep" },
    { "<leader>sw", function() require("telescope.builtin").grep_string() end, desc = "Search word under cursor" },
    { "<leader>sh", function() require("telescope.builtin").help_tags() end, desc = "Search help" },
    { "<leader>sk", function() require("telescope.builtin").keymaps() end, desc = "Search keymaps" },
    { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" },
    { "<leader>sr", function() require("telescope.builtin").resume() end, desc = "Resume last search" },
    { "<leader>s.", function() require("telescope.builtin").oldfiles() end, desc = "Search recent files" },
    { "<leader>/", function() require("telescope.builtin").current_buffer_fuzzy_find() end, desc = "Fuzzy search in buffer" },
  },
  config = function()
    -- Picker width in columns: 95% of the window under 180 columns, 80% above.
    local function picker_width(_, max_columns)
      return math.floor(max_columns * (max_columns < 180 and 0.95 or 0.8))
    end

    require("telescope").setup({
      defaults = {
        file_ignore_patterns = { "^.git/", "node_modules/" },
        layout_strategy = "flex",
        layout_config = {
          flip_columns = 120, -- side by side from 120 columns, stacked below
          width = picker_width,
          height = 0.95,
          horizontal = { preview_width = 0.5 },
        },
        path_display = { "filename_first" },
      },
      pickers = { find_files = { hidden = true } },
    })
    pcall(require("telescope").load_extension, "fzf") -- only if fzf-native built
  end,
}
