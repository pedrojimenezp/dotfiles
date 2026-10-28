-- Telescope: fuzzy finder for files, text, buffers, help and more.
return {
  "nvim-telescope/telescope.nvim",
  branch = "master", -- tracks the current development branch
  dependencies = {
    "nvim-lua/plenary.nvim", -- Lua helper library required by telescope
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- native fzf sorter (faster, better ranking)
  },
  cmd = "Telescope", -- load on :Telescope
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
    { "<leader>gc", function() require("telescope.builtin").git_commits() end, desc = "Git commits" },
    { "<leader>gb", function() require("telescope.builtin").git_branches() end, desc = "Git branches" },
  },
  config = function()
    require("telescope").setup({
      defaults = { file_ignore_patterns = { "^.git/", "node_modules/" } }, -- hide noise from results
    })
    pcall(require("telescope").load_extension, "fzf") -- enable the native sorter if it built
  end,
}
