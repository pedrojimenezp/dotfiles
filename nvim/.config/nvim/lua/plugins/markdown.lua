-- Markdown: renders headings, code blocks, tables and lists inside the buffer (concealed, in normal mode).
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown", -- loaded when a Markdown file opens
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- needs the markdown and markdown_inline parsers (listed in treesitter.lua)
    "nvim-tree/nvim-web-devicons", -- icons for headings and code block languages
  },
  opts = {}, -- defaults; colors come from the active colorscheme's highlight groups
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>", ft = "markdown", desc = "Toggle Markdown rendering" },
  },
}
