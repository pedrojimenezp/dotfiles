-- Colorscheme: tokyonight (the Ghostty theme and tmux colors match it).
return {
  "folke/tokyonight.nvim",
  priority = 1000, -- load before other plugins so highlights apply everywhere
  lazy = false, -- load at startup (the theme is needed immediately)
  opts = {
    style = "night", -- darkest variant, same as Ghostty's "TokyoNight Night"
    transparent = false, -- keep the solid background
  },
  config = function(_, opts)
    require("tokyonight").setup(opts) -- apply options
    vim.cmd.colorscheme("tokyonight-night") -- activate the theme
  end,
}
