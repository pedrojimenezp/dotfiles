-- Treesitter: fast, accurate syntax highlighting and indentation.
-- Uses the `main` branch (Neovim 0.11+); it compiles parsers with the tree-sitter CLI.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main", -- the maintained rewrite
  lazy = false, -- the plugin does not support lazy loading
  build = ":TSUpdate", -- update parsers when the plugin updates
  config = function()
    local parsers = {
      "go", "gomod", "typescript", "tsx", "javascript", "json", "yaml", "bash", "zig",
      "lua", "markdown", "markdown_inline", "dockerfile", "vim", "vimdoc", "query",
    } -- languages to install (vim/vimdoc/query are needed for Lua and help files)
    require("nvim-treesitter").install(parsers) -- install missing parsers (async, no-op if present)

    vim.api.nvim_create_autocmd("FileType", {
      desc = "Start treesitter highlighting and indent",
      callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then -- only when a parser exists for this filetype
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- treesitter indent
        end
      end,
    })
  end,
}
