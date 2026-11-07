-- Review changes across files: side-by-side diffs against any revision, and file history.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" }, -- load on first use
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view (working tree)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "History of this file" },
      { "<leader>gq", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
    },
  },
}
