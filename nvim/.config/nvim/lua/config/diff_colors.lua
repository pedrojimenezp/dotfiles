-- GitHub-style diff colors for any colorscheme: Diff* groups get a background and never a
-- foreground, so syntax highlighting shows through. The tints are the Normal background blended
-- with the scheme's red and green. A scheme colour that is too dull (HSL saturation below
-- min_saturation) is replaced by the mode's GitHub colour from `fallback`, so tints always read
-- as red or green. Each colour is judged on its own.
--   DiffAdd         added line (green); DiffAddOld is the same line as seen on the old side (red)
--   DiffChange*     changed line, DiffText* the changed words inside it; Old = red, New = green
--   DiffDelete      filler where the other side has lines: a faint gap, drawn with blank fillchars
--   GitSigns*       gitsigns' unified view: AddPreview added line, DeleteVirtLn deleted line,
--                   AddInline/ChangeInline/DeleteVirtLnInLine the changed words (green or red)
local M = {}

local fallback = {
  light = { bg = "#ffffff", red = "#cf222e", green = "#1a7f37", fg = "#1f2328" },
  dark = { bg = "#0d1117", red = "#f85149", green = "#3fb950", fg = "#e6edf3" },
}
local strength = { -- blend amount: whole line, changed words, filler gap
  light = { line = 0.14, text = 0.32, gap = 0.05 },
  dark = { line = 0.20, text = 0.40, gap = 0.07 },
}

local min_saturation = 0.32 -- HSL; Dayfox green is 0.29, base16 greens 0.34 and up

local function to_hex(n) return n and string.format("#%06x", n) or nil end

-- First fg or bg found among the groups, as "#rrggbb".
local function color(attr, ...)
  for _, name in ipairs({ ... }) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl[attr] then return to_hex(hl[attr]) end
  end
end

local function blend(a, b, t)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x + (y - x) * t + 0.5))
  end
  return out
end

-- HSL saturation of "#rrggbb", 0 (grey) to 1.
local function saturation(hex)
  local r, g, b = tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255
  local hi, lo = math.max(r, g, b), math.min(r, g, b)
  if hi == lo then return 0 end
  return (hi - lo) / (1 - math.abs(hi + lo - 1))
end

-- The scheme colour, or the fallback when it is missing or too dull.
local function vivid(scheme, fallback_color)
  if scheme and saturation(scheme) >= min_saturation then return scheme end
  return fallback_color
end

function M.apply()
  local mode = vim.o.background == "light" and "light" or "dark"
  local fb, k = fallback[mode], strength[mode]
  local bg = color("bg", "Normal") or fb.bg
  local fg = color("fg", "Normal") or fb.fg
  local red = vivid(color("fg", "DiagnosticError", "Removed"), fb.red)
  local green = vivid(color("fg", "DiagnosticOk", "Added"), fb.green)
  local function hl(name, tint, t) vim.api.nvim_set_hl(0, name, { bg = blend(bg, tint, t) }) end
  hl("DiffAdd", green, k.line)
  hl("DiffAddOld", red, k.line)
  hl("DiffChangeNew", green, k.line)
  hl("DiffTextNew", green, k.text)
  hl("DiffChangeOld", red, k.line)
  hl("DiffTextOld", red, k.text)
  hl("DiffDelete", fg, k.gap)
  hl("GitSignsAddPreview", green, k.line)
  hl("GitSignsDeleteVirtLn", red, k.line)
  hl("GitSignsAddInline", green, k.text)
  hl("GitSignsChangeInline", green, k.text)
  hl("GitSignsDeleteInline", red, k.text)
  hl("GitSignsDeleteVirtLnInLine", red, k.text)
  -- Plain :diffthis windows get the new-side look
  vim.api.nvim_set_hl(0, "DiffChange", { link = "DiffChangeNew" })
  vim.api.nvim_set_hl(0, "DiffText", { link = "DiffTextNew" })
end

-- Window-local highlight for a diffview side: "a" is the old file, "b" the new one.
function M.winhighlight(symbol)
  if symbol == "a" then return "DiffAdd:DiffAddOld,DiffChange:DiffChangeOld,DiffText:DiffTextOld" end
  if symbol == "b" then return "DiffChange:DiffChangeNew,DiffText:DiffTextNew" end
end

function M.setup()
  vim.opt.fillchars:append({ diff = " " }) -- the default "-" fills the gap with dashes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("dotfiles_diff_colors", { clear = true }),
    desc = "Redefine the diff groups after a colorscheme",
    callback = M.apply,
  })
  M.apply()
end

return M
