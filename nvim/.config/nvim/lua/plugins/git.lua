return {
  {
    "sindrets/diffview.nvim",
    opts = {
      hooks = {
        diff_buf_win_enter = function(_, winid, ctx)
          local winhl = require("config.diff_colors").winhighlight(ctx.symbol)
          if winhl then vim.wo[winid].winhighlight = winhl end
        end,
      },
    },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view (working tree)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "History of this file" },
      { "<leader>gq", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
    },
  },
}
