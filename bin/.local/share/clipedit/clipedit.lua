-- Adds <leader>m to the current buffer: replace secrets with *** using mask.pl, and report how many lines changed.
local dir = debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]*$")

Clipedit = Clipedit or {}

local diff = (vim.text and vim.text.diff) or vim.diff -- vim.diff is deprecated in newer nvim

-- Masks the whole buffer in one undo step. Returns the number of lines changed.
function Clipedit.mask()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local eol = vim.bo[buf].endofline
  local text = table.concat(lines, "\n") .. (eol and "\n" or "")
  local res = vim.system({ "perl", dir .. "/mask.pl" }, { stdin = text }):wait()
  if res.code ~= 0 then
    vim.notify("mask failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
    return 0
  end
  local out = res.stdout
  if out == text then
    vim.notify("nothing to mask")
    return 0
  end
  local new = vim.split(out, "\n", { plain = true })
  if eol then table.remove(new) end
  local changed = 0
  for _, h in ipairs(diff(table.concat(lines, "\n") .. "\n", table.concat(new, "\n") .. "\n", { result_type = "indices" })) do
    changed = changed + h[2]
  end
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new)
  vim.fn.winrestview(view)
  vim.notify(("masked %d line%s"):format(changed, changed == 1 and "" or "s"))
  return changed
end

vim.keymap.set("n", "<leader>m", Clipedit.mask, { buffer = true, desc = "Mask secrets with ***" })
