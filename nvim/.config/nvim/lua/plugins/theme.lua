-- Colorscheme: tokyonight. It follows vim.o.background (Neovim 0.12 detects it from the terminal).
return {
  "folke/tokyonight.nvim",
  priority = 1000, -- load before other plugins so highlights apply everywhere
  lazy = false, -- load at startup (the theme is needed immediately)
  opts = {
    style = "night", -- dark variant, same as Ghostty's "TokyoNight Night"
    light_style = "day", -- light variant, same as Ghostty's "TokyoNight Day"
    transparent = false, -- keep the solid background
  },
  config = function(_, opts)
    require("tokyonight").setup(opts) -- apply options
    vim.cmd.colorscheme("tokyonight") -- activate; picks night or day from 'background'
  end,
}
