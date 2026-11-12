-- Colors that follow the dotfiles theme pair (~/.config/theme/config).
-- 'background' picks the slot; the slot's name picks the scheme (nvim_light/nvim_dark, when set,
-- replace the terminal's name for that slot). Names map to colorschemes through themes.tsv, the
-- list `theme list nvim` prints; a name not in it gets Dayfox (light) or Nightfox (dark).
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

-- Original themes from themes.tsv: { [name] = { scheme = colorscheme, background = "light"|"dark" } }.
local themes
local function original_themes()
  if themes then return themes end
  themes = {}
  local path = vim.api.nvim_get_runtime_file("themes.tsv", false)[1]
  for _, line in ipairs(path and vim.fn.readfile(path) or {}) do
    local name, scheme, background = line:match("^([^#\t][^\t]*)\t([^\t]+)\t(%a+)")
    if name then themes[name] = { scheme = scheme, background = background } end
  end
  return themes
end

-- Colorscheme for a name in the list, or nil.
local function plugin_scheme(name)
  local theme = original_themes()[name]
  if not theme then return nil end
  local style = theme.scheme:match("^tokyonight%-(%a+)$")
  if style then
    require("tokyonight").setup({ style = style, light_style = style, transparent = false }) -- both slots
  end
  -- Catppuccin picks the flavour from 'background' when it differs from the one loaded last.
  local flavour = theme.scheme:match("^catppuccin%-(%a+)$")
  if flavour then require("catppuccin").setup({ background = { light = flavour, dark = flavour } }) end
  return theme.scheme
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
  if not ok then pcall(vim.cmd.colorscheme, bg == "light" and "dayfox" or "nightfox") end -- unlisted name or failed load
  M.applied = name
  M.applied_bg = bg -- a plugin scheme may force 'background' to the other value
  vim.g.dotfiles_theme = name
  vim.g.colors_name = nil -- see the header
  require("config.diff_colors").apply() -- covers a scheme that fires no ColorScheme
  loading = false
end

function M.setup()
  require("config.diff_colors").setup()
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
