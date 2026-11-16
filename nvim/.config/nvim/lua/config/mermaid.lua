local M = {}

local OPEN = "^%s*```+%s*mermaid%s*$"
local CLOSE = "^%s*```+%s*$"

-- Returns the body lines of the ```mermaid block containing `row` (1-based; a fence line counts) and the
-- line of its opening fence, or nil.
function M.find_block(lines, row)
  local start
  for i, line in ipairs(lines) do
    if not start then
      if line:match(OPEN) then start = i end
    elseif line:match(CLOSE) then
      if row >= start and row <= i then return vim.list_slice(lines, start + 1, i - 1), start end
      start = nil
    end
  end
  return nil
end

-- Shows `text` in a centred, read-only float sized to it; `q` or `<Esc>` closes it.
function M.float(text)
  local lines = vim.split(text:gsub("\n+$", ""), "\n", { plain = true })
  local width = 1
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Mermaid ",
  })
  vim.wo[win].wrap = false
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true, desc = "Close preview" })
  end
  return buf, win
end

-- Renders the mermaid block under the cursor with mermaid-ascii; the buffer is not touched.
function M.preview()
  if vim.fn.executable("mermaid-ascii") ~= 1 then
    vim.notify("mermaid-ascii is not installed (mise install)", vim.log.levels.ERROR)
    return
  end
  local body = M.find_block(vim.api.nvim_buf_get_lines(0, 0, -1, false), vim.api.nvim_win_get_cursor(0)[1])
  if not body then
    vim.notify("no mermaid block under the cursor", vim.log.levels.WARN)
    return
  end
  local res = vim.system({ "mermaid-ascii", "-f", "/dev/stdin" }, { stdin = table.concat(body, "\n") .. "\n", text = true }):wait()
  if res.code ~= 0 then
    vim.notify(vim.trim(res.stderr ~= "" and res.stderr or res.stdout or "mermaid-ascii failed"), vim.log.levels.ERROR)
    return
  end
  M.float(res.stdout)
end

-- Opens the buffer in the browser with md-open, from the buffer text as it is (unsaved edits included).
-- With the cursor in a mermaid block, sends only that block as one diagram named <file>:<fence line>;
-- otherwise sends the whole buffer as rendered Markdown, relative paths resolved from the buffer's folder.
function M.open()
  if vim.fn.executable("md-open") ~= 1 then
    vim.notify("md-open is not installed (stow bin)", vim.log.levels.ERROR)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local file = vim.fn.expand("%:t")
  if file == "" then file = "untitled.md" end
  local cmd = { "md-open", "--name", file, "--dir", vim.fn.expand("%:p:h"), "-" }
  local body, start = M.find_block(lines, vim.api.nvim_win_get_cursor(0)[1])
  if body then
    lines = body
    cmd = { "md-open", "--name", file .. ":" .. start, "-" }
  end
  local res = vim.system(cmd, { stdin = table.concat(lines, "\n") .. "\n", text = true }):wait()
  if res.code ~= 0 then
    vim.notify(vim.trim(res.stderr ~= "" and res.stderr or "md-open failed"), vim.log.levels.ERROR)
  end
end

return M
