-- GitHub-style diff colors for any colorscheme: Diff* groups get a background and never a
-- foreground, so syntax highlighting shows through. The tints are the Normal background blended
-- with the scheme's red and green.
--   DiffAdd         added line (green); DiffAddOld is the same line as seen on the old side (red)
--   DiffChange*     changed line, DiffText* the changed words inside it; Old = red, New = green
--   DiffDelete      filler where the other side has lines: a faint gap, drawn with blank fillchars
local M = {}

local fallback = {
  light = { bg = "#ffffff", red = "#cf222e", green = "#1a7f37", fg = "#1f2328" },
  dark = { bg = "#0d1117", red = "#f85149", green = "#3fb950", fg = "#e6edf3" },
}
local strength = { -- blend amount: whole line, changed words, filler gap
  light = { line = 0.14, text = 0.32, gap = 0.05 },
  dark = { line = 0.20, text = 0.40, gap = 0.07 },
}

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

function M.apply()
  local mode = vim.o.background == "light" and "light" or "dark"
  local fb, k = fallback[mode], strength[mode]
  local bg = color("bg", "Normal") or fb.bg
  local fg = color("fg", "Normal") or fb.fg
  local red = color("fg", "DiagnosticError", "Removed") or fb.red
  local green = color("fg", "DiagnosticOk", "Added") or fb.green
  local function hl(name, tint, t) vim.api.nvim_set_hl(0, name, { bg = blend(bg, tint, t) }) end
  hl("DiffAdd", green, k.line)
  hl("DiffAddOld", red, k.line)
  hl("DiffChangeNew", green, k.line)
  hl("DiffTextNew", green, k.text)
  hl("DiffChangeOld", red, k.line)
  hl("DiffTextOld", red, k.text)
  hl("DiffDelete", fg, k.gap)
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
