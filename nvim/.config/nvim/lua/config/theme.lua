-- Colors that follow the dotfiles theme pair (~/.config/theme/config, edited by `theme pick`/`theme set`).
-- vim.o.background picks the slot (light or dark); the slot's name picks the colorscheme:
--   TokyoNight ... -> tokyonight.nvim, GitHub ... -> github-nvim-theme, anything else -> mini.base16
--   built from the theme file that `theme file <name>` prints. A 'background' change reloads it.
-- g:colors_name is cleared after loading: otherwise Neovim reloads that scheme itself when 'background'
-- changes, and a scheme for one slot would fight the other slot. g:dotfiles_theme holds the name instead.
local M = {}

local defaults = { light = "GitHub Light Default", dark = "TokyoNight Night" } -- same fallbacks as the script
local loading = false -- guard: a scheme that sets 'background' would reload us while we load
M.applied = nil -- theme name shown now, to notice changes made in the shell

-- Read the light/dark names from ~/.config/theme/config.
function M.read_config()
  local dir = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config") -- same path as the script
  local names = vim.deepcopy(defaults) -- start from the defaults
  local ok, lines = pcall(vim.fn.readfile, dir .. "/theme/config") -- missing file: keep defaults
  if not ok then return names end
  for _, line in ipairs(lines) do
    local slot, name = line:match("^%s*(%a+)%s*=%s*(.-)%s*$") -- "slot = name"
    if (slot == "light" or slot == "dark") and name ~= "" then names[slot] = name end
  end
  return names
end

-- The saved mode as a background value; nil in auto mode off macOS (keep nvim's own detection).
function M.mode()
  local dir = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state") -- same path as the script
  local ok, lines = pcall(vim.fn.readfile, dir .. "/theme", "", 1) -- first line of the state file
  local state = ok and lines[1] or "auto" -- missing file means auto
  if state == "dark" or state == "light" then return state end -- explicit choice
  if vim.fn.has("mac") == 1 then
    local res = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait() -- fails in light mode
    return vim.trim(res.stdout or "") == "Dark" and "dark" or "light" -- follow macOS
  end
  return nil -- auto elsewhere: the terminal background decides
end

-- Path of a theme file, via the `theme` script (cache, Ghostty bundle or download).
local function theme_file(name)
  if vim.fn.executable("theme") ~= 1 then return nil end -- script not installed
  local res = vim.system({ "theme", "file", name }, { text = true }):wait() -- may download once
  if res.code ~= 0 then return nil end -- unknown theme or offline
  return vim.trim(res.stdout or "") -- the path
end

-- Parse a Ghostty theme file into { palette = { [0..15] = "#rrggbb" }, bg = ..., fg = ... }.
local function parse(path)
  local t = { palette = {} } -- result
  for _, line in ipairs(vim.fn.readfile(path)) do
    local idx, color = line:match("^%s*palette%s*=%s*(%d+)%s*=%s*#?(%x%x%x%x%x%x)") -- palette = N=#hex
    if idx then
      t.palette[tonumber(idx)] = "#" .. color:lower() -- palette entry
    else
      local key, value = line:match("^%s*([%a-]+)%s*=%s*#?(%x%x%x%x%x%x)") -- key = #hex
      if key == "background" then t.bg = "#" .. value:lower() end -- window background
      if key == "foreground" then t.fg = "#" .. value:lower() end -- default text
    end
  end
  return t
end

-- Mix two "#rrggbb" colors: t = 0 gives a, t = 1 gives b.
local function blend(a, b, t)
  local out = "#" -- result
  for i = 2, 6, 2 do -- the r, g and b pairs
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16) -- channel values
    out = out .. string.format("%02x", math.floor(x + (y - x) * t + 0.5)) -- rounded mix
  end
  return out
end

-- Apply mini.base16 with a palette derived from a Ghostty theme file.
local function base16(path)
  local t = parse(path) -- colors from the file
  if not (t.bg and t.fg) then return false end -- not a usable theme
  local p = t.palette -- shortcut
  local function c(i) return p[i] or t.fg end -- palette entry or fg
  require("mini.base16").setup({
    palette = {
      base00 = t.bg, -- default background
      base01 = blend(t.bg, t.fg, 0.08), -- lighter background (status bars, cursor line)
      base02 = blend(t.bg, t.fg, 0.18), -- selection background
      base03 = c(8), -- comments, invisibles
      base04 = blend(t.bg, t.fg, 0.55), -- dark foreground (status bars)
      base05 = t.fg, -- default foreground
      base06 = blend(t.bg, t.fg, 0.9), -- light foreground
      base07 = p[15] or t.fg, -- lightest foreground
      base08 = c(1), -- variables, tags, errors (red)
      base09 = p[9] or blend(c(3), t.fg, 0.25), -- numbers, constants (bright red or a brighter yellow)
      base0A = c(3), -- types, search (yellow)
      base0B = c(2), -- strings (green)
      base0C = c(6), -- regex, escapes (cyan)
      base0D = c(4), -- functions (blue)
      base0E = c(5), -- keywords (magenta)
      base0F = p[9] or c(1), -- deprecated, embedded tags
    },
  })
  return true
end

-- Colorscheme for a "TokyoNight ..." or "GitHub ..." name, or nil.
local function plugin_scheme(name)
  local tokyo = name:match("^TokyoNight%s*(%a*)$") -- "" for plain TokyoNight, else the variant
  if tokyo then
    local style = ({ Night = "night", Storm = "storm", Moon = "moon", Day = "day" })[tokyo] or "night" -- variant
    require("tokyonight").setup({ style = style, light_style = style, transparent = false }) -- both slots
    return "tokyonight-" .. style -- e.g. tokyonight-night
  end
  if name == "GitHub" then return "github_light" end -- the plain Ghostty "GitHub" theme is light
  if name:match("^GitHub ") then return (name:lower():gsub("%s+", "_")) end -- GitHub Light Default -> github_light_default
  return nil -- no plugin for this theme
end

-- Load the theme for the current background.
function M.load()
  if loading then return end -- re-entered through a 'background' change: ignore
  loading = true -- start the guard
  local bg = vim.o.background -- "light" or "dark"
  local name = M.read_config()[bg] -- the slot's theme
  local ok = false -- true once something applied
  vim.cmd("highlight clear") -- start clean (schemes skip this when g:colors_name is unset)
  local found, scheme = pcall(plugin_scheme, name) -- dedicated plugin, if any (may be missing)
  if found and scheme then ok = pcall(vim.cmd.colorscheme, scheme) end -- plugin may fail to load
  if not ok then
    local path = theme_file(name) -- Ghostty theme file
    if path then
      local called, applied = pcall(base16, path) -- generic palette
      ok = called and applied -- both must succeed
    end
  end
  if not ok then pcall(vim.cmd.colorscheme, bg == "light" and "tokyonight-day" or "tokyonight-night") end -- last resort
  M.applied = name -- remember what is shown
  vim.g.dotfiles_theme = name -- for statuslines or :echo
  vim.g.colors_name = nil -- no native reload on 'background' changes (the autocmd below does it)
  loading = false -- end the guard
end

-- Startup: take the background from the saved mode, load the colors, and reload them on changes.
function M.setup()
  local want = M.mode() -- nil = keep nvim's detected background
  if want then vim.o.background = want end -- match the terminal
  M.load() -- colors for that background
  vim.api.nvim_create_autocmd("OptionSet", {
    group = vim.api.nvim_create_augroup("dotfiles_theme", { clear = true }), -- no duplicates on re-source
    pattern = "background", -- <leader>ut, FocusGained or the terminal's own detection
    desc = "Load the dotfiles theme for the new background",
    callback = function() M.load() end, -- the other slot's theme
  })
end

-- Focus regained: follow a mode or theme change made in the shell (`theme pick`, `tt`, macOS).
function M.sync()
  local want = M.mode() or vim.o.background -- desired background
  if vim.o.background ~= want then
    vim.o.background = want -- the OptionSet autocmd loads the other slot
  elseif M.read_config()[want] ~= M.applied then
    M.load() -- same slot, new theme name
  end
end

return M
