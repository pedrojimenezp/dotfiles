-- Colors that follow the dotfiles theme pair (~/.config/theme/config).
-- 'background' picks the slot; the slot's name picks the scheme (nvim_light/nvim_dark, when set,
-- replace the terminal's name for that slot): TokyoNight -> tokyonight.nvim,
-- GitHub -> github-nvim-theme, anything else -> mini.base16 from the theme file.
-- g:colors_name is cleared after loading, or Neovim would reload that scheme itself on a
-- 'background' change and fight the other slot. g:dotfiles_theme holds the name instead.
local M = {}

local defaults = { light = "GitHub Light Default", dark = "TokyoNight Night" } -- same fallbacks as the script
local loading = false -- a scheme that sets 'background' would reload us mid-load
M.applied = nil -- to notice changes made in the shell
M.applied_bg = nil
local appearance = { at = nil, value = nil } -- cache: each `defaults` read is a process
local appearance_ttl = 5000 -- ms

-- Returns { light = name, dark = name }: the nvim_<slot> name when set, else the terminal's.
function M.read_config()
  local dir = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config") -- same path as the script
  local names = vim.deepcopy(defaults)
  local ok, lines = pcall(vim.fn.readfile, dir .. "/theme/config")
  if not ok then return names end
  local keys = { light = "light", dark = "dark", nvim_light = "light", nvim_dark = "dark" } -- key -> slot
  local terminal, nvim = {}, {}
  local seen = {} -- first line of each key wins, like the script
  for _, line in ipairs(lines) do
    local key, name = line:match("^%s*([%a_]+)%s*=%s*(.-)%s*$")
    if keys[key] and name ~= "" and not seen[key] then
      seen[key] = true
      if key:find("^nvim_") then nvim[keys[key]] = name else terminal[keys[key]] = name end
    end
  end
  for slot in pairs(names) do names[slot] = nvim[slot] or terminal[slot] or names[slot] end
  return names
end

-- The saved mode as a background value; nil in auto mode off macOS (nvim detects it).
function M.mode()
  local dir = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
  local ok, lines = pcall(vim.fn.readfile, dir .. "/theme", "", 1)
  local state = ok and lines[1] or "auto" -- missing file means auto
  if state == "dark" or state == "light" then return state end
  if vim.fn.has("mac") == 1 then
    local now = vim.uv.now()
    if appearance.at and now - appearance.at < appearance_ttl then return appearance.value end
    local res = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait() -- fails in light mode
    appearance.at = now
    appearance.value = vim.trim(res.stdout or "") == "Dark" and "dark" or "light"
    return appearance.value
  end
  return nil
end

-- Path of a theme file. Mirrors theme_file() in bin/.local/bin/theme (same folders and order)
-- without spawning it, and never downloads, so startup can't wait on curl.
local function theme_file(name)
  if name == "" or name:find("/", 1, true) or name:sub(1, 1) == "." then return nil end -- the script refuses paths
  local home = vim.env.HOME or ""
  local dirs = vim.uv.os_getenv("THEME_GHOSTTY_DIRS") -- set, even empty, replaces the list
  if dirs == nil then
    dirs = table.concat({
      home .. "/Applications/Ghostty.app/Contents/Resources/ghostty/themes",
      "/Applications/Ghostty.app/Contents/Resources/ghostty/themes",
      "/usr/share/ghostty/themes",
      home .. "/.local/share/ghostty/themes",
    }, ":")
  end
  local data = vim.env.XDG_DATA_HOME
  if data == nil or data == "" then data = home .. "/.local/share" end -- like bash ${VAR:-default}
  local candidates = vim.split(dirs, ":", { plain = true })
  candidates[#candidates + 1] = data .. "/theme/themes"
  for _, dir in ipairs(candidates) do
    if dir ~= "" then
      local stat = vim.uv.fs_stat(dir .. "/" .. name)
      if stat and stat.type == "file" then return dir .. "/" .. name end
    end
  end
  return nil
end

-- Parse a Ghostty theme file into { palette = { [0..15] = "#rrggbb" }, bg = ..., fg = ... }.
local function parse(path)
  local t = { palette = {} }
  for _, line in ipairs(vim.fn.readfile(path)) do
    local idx, color = line:match("^%s*palette%s*=%s*(%d+)%s*=%s*#?(%x%x%x%x%x%x)")
    if idx then
      t.palette[tonumber(idx)] = "#" .. color:lower()
    else
      local key, value = line:match("^%s*([%a-]+)%s*=%s*#?(%x%x%x%x%x%x)")
      if key == "background" then t.bg = "#" .. value:lower() end
      if key == "foreground" then t.fg = "#" .. value:lower() end
    end
  end
  return t
end

-- Mix two "#rrggbb" colors: t = 0 gives a, t = 1 gives b.
local function blend(a, b, t)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x + (y - x) * t + 0.5))
  end
  return out
end

-- Apply mini.base16 with a palette derived from a Ghostty theme file.
local function base16(path)
  local t = parse(path)
  if not (t.bg and t.fg) then return false end
  local p = t.palette
  local function c(i) return p[i] or t.fg end
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
  local tokyo = name:match("^TokyoNight%s*(%a*)$")
  if tokyo then
    local style = ({ Night = "night", Storm = "storm", Moon = "moon", Day = "day" })[tokyo] or "night"
    require("tokyonight").setup({ style = style, light_style = style, transparent = false }) -- both slots
    return "tokyonight-" .. style
  end
  if name == "GitHub" then return "github_light" end -- Ghostty's plain "GitHub" theme is light
  if name:match("^GitHub ") then return (name:lower():gsub("%s+", "_")) end -- GitHub Light Default -> github_light_default
  return nil
end

function M.load()
  if loading then return end -- re-entered through a 'background' change
  loading = true
  local bg = vim.o.background
  local name = M.read_config()[bg]
  local ok = false
  vim.cmd("highlight clear") -- schemes skip this when g:colors_name is unset
  local found, scheme = pcall(plugin_scheme, name) -- the plugin may be missing
  if found and scheme then ok = pcall(vim.cmd.colorscheme, scheme) end
  if not ok then
    local path = theme_file(name)
    if path then
      local called, applied = pcall(base16, path)
      ok = called and applied
    end
  end
  if not ok then pcall(vim.cmd.colorscheme, bg == "light" and "tokyonight-day" or "tokyonight-night") end -- last resort
  M.applied = name
  M.applied_bg = bg -- a plugin scheme may force 'background' to the other value
  vim.g.dotfiles_theme = name
  vim.g.colors_name = nil -- see the header
  loading = false
end

function M.setup()
  local want = M.mode() -- nil = keep nvim's detected background
  if want then vim.o.background = want end
  M.load()
  vim.api.nvim_create_autocmd("OptionSet", {
    group = vim.api.nvim_create_augroup("dotfiles_theme", { clear = true }),
    pattern = "background", -- <leader>ut, FocusGained or the terminal's own detection
    desc = "Load the dotfiles theme for the new background",
    callback = function() M.load() end,
  })
end

-- Follow a mode or theme change made outside nvim.
function M.sync()
  -- Compare with the mode we last loaded, not vim.o.background: a plugin colorscheme can force
  -- 'background' to its own brightness, which would otherwise look like a change on every focus.
  local want = M.mode() or M.applied_bg or vim.o.background
  if M.applied_bg ~= want then
    vim.o.background = want -- OptionSet loads the other slot
    if M.applied_bg ~= want then M.load() end -- no event fired: 'background' already had that value
  elseif M.read_config()[want] ~= M.applied then
    M.load()
  end
end

return M
