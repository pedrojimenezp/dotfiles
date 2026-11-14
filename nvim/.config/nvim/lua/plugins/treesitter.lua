-- The main branch (Neovim 0.12+) compiles parsers with the tree-sitter CLI.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- the plugin doesn't support lazy loading
  build = ":TSUpdate",
  config = function()
    local parsers = {
      "go", "gomod", "typescript", "tsx", "javascript", "json", "yaml", "bash", "zig",
      "lua", "markdown", "markdown_inline", "dockerfile", "vim", "vimdoc", "query",
      "toml", "gitcommit", "git_config", "git_rebase", "diff",
    } -- vim, vimdoc, query: needed for Lua and help files
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      desc = "Start treesitter highlighting and indent",
      callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
