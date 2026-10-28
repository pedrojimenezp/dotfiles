-- Colorscheme plugins used by lua/config/theme.lua (it picks one by theme name).
-- Both load on demand: lazy.nvim loads them when their colorscheme or module is first used.
return {
  {
    "folke/tokyonight.nvim", -- for "TokyoNight Night/Storm/Moon/Day"
    lazy = true, -- loaded by :colorscheme tokyonight-* or require("tokyonight")
    opts = { transparent = false }, -- keep the solid background (style is set per theme)
  },
  {
    "projekt0n/github-nvim-theme", -- for "GitHub Light Default", "GitHub Dark Dimmed", ...
    lazy = true, -- loaded by :colorscheme github_*
  },
}
