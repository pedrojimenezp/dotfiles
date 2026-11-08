-- Servers from Mason via vim.lsp.config. zls comes from mise, to match zig.
return {
  {
    "neovim/nvim-lspconfig", -- its lsp/ folder ships the default server configs
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "Mason", "LspInfo", "LspLog" },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Neovim already maps grn, gra, grr, gri, gO and K; grr and gri get Telescope pickers.
      -- No bare gr map: it would delay the gr* defaults.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(event)
          local function map(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          local tb = function(name) return function() require("telescope.builtin")[name]() end end
          map("gd", tb("lsp_definitions"), "Go to definition")
          map("grr", tb("lsp_references"), "Go to references")
          map("gri", tb("lsp_implementations"), "Go to implementation")
          map("<leader>D", tb("lsp_type_definitions"), "Type definition")
          map("<leader>ds", tb("lsp_document_symbols"), "Document symbols")
          map("<leader>sS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols") -- not under <leader>w: that must stay a plain save
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
          end, "Toggle inlay hints")
        end,
      })

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = { spacing = 2 },
        float = { border = "rounded" },
      })

      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      vim.lsp.config("gopls", {
        settings = { gopls = { gofumpt = true, staticcheck = true, usePlaceholders = true } },
      })
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } },
      })
      vim.lsp.config("bashls", {
        settings = { bashIde = { shellcheckPath = "" } }, -- nvim-lint runs shellcheck; avoids duplicates
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "gopls", "ts_ls", "bashls", "lua_ls" }, -- ts_ls also covers JS and TSX
        automatic_enable = { exclude = { "zls" } },
      })
      require("mason-tool-installer").setup({
        ensure_installed = { "gofumpt", "goimports", "prettierd", "stylua" }, -- shfmt, shellcheck and golangci-lint come from mise
      })

      if vim.fn.executable("zls") == 1 then vim.lsp.enable("zls") end
    end,
  },
}
