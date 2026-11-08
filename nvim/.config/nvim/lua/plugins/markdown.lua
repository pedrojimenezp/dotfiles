return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- needs the markdown and markdown_inline parsers
    "nvim-tree/nvim-web-devicons",
  },
  opts = {},
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>", ft = "markdown", desc = "Toggle Markdown rendering" },
  },
}
