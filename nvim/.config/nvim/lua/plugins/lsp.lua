-- LSP: language servers installed by Mason, configured with the Neovim 0.11 API.
-- zls is the exception: it comes from Homebrew so it always matches the installed zig.
return {
  {
    "neovim/nvim-lspconfig", -- ships default configs in its lsp/ folder (cmd, filetypes, root markers)
    event = { "BufReadPre", "BufNewFile" }, -- load when opening files, not at startup
    cmd = { "Mason", "LspInfo", "LspLog" }, -- commands usable before the first file
    dependencies = {
      { "mason-org/mason.nvim", opts = {} }, -- installer for servers, formatters, linters
      "mason-org/mason-lspconfig.nvim", -- bridges Mason and vim.lsp
      "WhoIsSethDaniel/mason-tool-installer.nvim", -- installs formatters/linters through Mason
      "saghen/blink.cmp", -- provides completion capabilities for the servers
    },
    config = function()
      -- Keymaps and options when a server attaches to a buffer.
      -- Neovim 0.11 already defines: grn rename, gra code action, grr references,
      -- gri implementation, gO document symbols, K hover. grr/gri are overridden below
      -- with Telescope pickers (avoid a bare gr map: it delays the gr* defaults).
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(event)
          local function map(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc }) -- buffer-local map
          end
          local tb = function(name) return function() require("telescope.builtin")[name]() end end -- lazy telescope picker
          map("gd", tb("lsp_definitions"), "Go to definition")
          map("grr", tb("lsp_references"), "Go to references") -- overrides default grr with Telescope
          map("gri", tb("lsp_implementations"), "Go to implementation") -- overrides default gri with Telescope
          map("<leader>D", tb("lsp_type_definitions"), "Type definition")
          map("<leader>ds", tb("lsp_document_symbols"), "Document symbols")
          map("<leader>sS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols") -- under Search: <leader>w must stay a plain save
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
          end, "Toggle inlay hints")
        end,
      })

      vim.diagnostic.config({
        severity_sort = true, -- errors before warnings
        virtual_text = { spacing = 2 }, -- inline messages at line end
        float = { border = "rounded" }, -- rounded popups
      })

      -- Give every server blink.cmp's completion capabilities.
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      -- Per-server settings (merged on top of nvim-lspconfig's defaults).
      vim.lsp.config("gopls", {
        settings = { gopls = { gofumpt = true, staticcheck = true, usePlaceholders = true } }, -- stricter formatting, extra checks
      })
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } }, -- know `vim`, no prompts
      })
      vim.lsp.config("bashls", {
        settings = { bashIde = { shellcheckPath = "" } }, -- shellcheck runs via nvim-lint instead (avoids duplicates)
      })

      -- Servers installed from Mason, and the tools conform/nvim-lint call.
      require("mason-lspconfig").setup({
        ensure_installed = { "gopls", "ts_ls", "bashls", "lua_ls" }, -- ts_ls: typescript-language-server (also JS/TSX)
        automatic_enable = { exclude = { "zls" } }, -- enable installed servers, except zls
      })
      require("mason-tool-installer").setup({
        ensure_installed = { "gofumpt", "goimports", "prettierd", "stylua" }, -- shfmt/shellcheck/golangci-lint come from brew
      })

      -- zls from PATH (Homebrew), enabled only when the binary exists.
      if vim.fn.executable("zls") == 1 then vim.lsp.enable("zls") end
    end,
  },
}
