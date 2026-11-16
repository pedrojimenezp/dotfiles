-- Colorschemes, loaded on demand by :colorscheme or require().
return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { transparent = false },
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = true,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = true,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    -- The default styles.italic also italicizes variables, parameters and properties.
    -- Keep italics for comments and emphasis.
    opts = {
      styles = { italic = false },
      highlight_groups = {
        Comment = { italic = true },
        ["@markup.italic"] = { italic = true },
        ["@text.emphasis"] = { italic = true },
        htmlItalic = { italic = true },
      },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
  },
  {
    "lunacookies/vim-colors-xcode",
    lazy = true,
  },
  {
    "navarasu/onedark.nvim",
    lazy = true,
  },
  {
    "zanglg/nova.nvim",
    lazy = true,
  },
  {
    "Paulo-Camacho/734",
    lazy = true,
  },
}
