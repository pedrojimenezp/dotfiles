-- Servers from Mason via vim.lsp.config. zls comes from mise, to match zig.
return {
  {
    "neovim/nvim-lspconfig", -- its lsp/ folder ships the default server configs
    event = { "BufReadPre", "BufNewFile" },
    cmd = "Mason",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
      { "b0o/SchemaStore.nvim", lazy = true }, -- JSON/YAML schema catalog
    },
    config = function()
      -- Neovim maps grn, gra, grr, gri, grt, gO and K. Telescope pickers replace grr, gri, grt and gO, and take gd.
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
          map("grt", tb("lsp_type_definitions"), "Go to type definition")
          map("gO", tb("lsp_document_symbols"), "Document symbols")
          map("<leader>sS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols") -- not under <leader>w: that must stay a plain save
          map("<leader>uh", function()
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
        settings = { gopls = { staticcheck = false, usePlaceholders = true } }, -- golangci-lint (nvim-lint) owns linting
      })
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } },
      })
      vim.lsp.config("bashls", {
        settings = { bashIde = { shellcheckPath = "" } }, -- nvim-lint runs shellcheck; avoids duplicates
      })

      vim.lsp.config("jsonls", {
        settings = { json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } } },
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = { schemaStore = { enable = false, url = "" }, schemas = require("schemastore").yaml.schemas() }, -- SchemaStore.nvim replaces the built-in fetch
        },
      })

      require("mason-lspconfig").setup({ automatic_enable = { exclude = { "zls" } } })
      require("mason-tool-installer").setup({
        -- Servers (lspconfig names, ts_ls also covers JS and TSX) and formatters. shfmt, shellcheck and golangci-lint come from mise.
        ensure_installed = {
          "gopls", "ts_ls", "bashls", "lua_ls", "jsonls", "yamlls",
          "gofumpt", "goimports", "prettierd", "stylua",
        },
      })
      -- The plugin installs on VimEnter, which has already passed when this loads on the first buffer.
      if vim.v.vim_did_enter == 1 then require("mason-tool-installer").run_on_start() end

      if vim.fn.executable("zls") == 1 then vim.lsp.enable("zls") end
    end,
  },
}
