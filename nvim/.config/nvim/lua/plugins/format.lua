-- conform.nvim (formatters, format on save) and nvim-lint (linters).
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" }, -- load right before the first save
    cmd = { "ConformInfo" }, -- or when inspecting formatters
    keys = {
      { "<leader>f", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" }, -- fix imports, then strict gofmt
        typescript = { "prettierd", "prettier", stop_after_first = true }, -- prettierd if present, else prettier
        typescriptreact = { "prettierd", "prettier", stop_after_first = true }, -- same for TSX
        javascript = { "prettierd", "prettier", stop_after_first = true }, -- same for JS
        json = { "prettierd", "prettier", stop_after_first = true }, -- same for JSON
        yaml = { "prettierd", "prettier", stop_after_first = true }, -- same for YAML
        markdown = { "prettierd", "prettier", stop_after_first = true }, -- same for Markdown
        sh = { "shfmt" }, -- shell scripts
        bash = { "shfmt" }, -- bash scripts
        zig = { "zigfmt" }, -- `zig fmt`
        lua = { "stylua" }, -- Lua
      },
      format_on_save = { timeout_ms = 1500, lsp_format = "fallback" }, -- format on every save; use LSP if no formatter
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" }, -- lint after open and save
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        go = { "golangcilint" }, -- Go linters aggregator
        sh = { "shellcheck" }, -- shell script linter
        bash = { "shellcheck" }, -- same for bash
      }
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
        callback = function() lint.try_lint() end, -- run the linters configured for this filetype
      })
    end,
  },
}
