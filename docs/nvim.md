# Neovim

Folder: `nvim/.config/nvim`, linked to `~/.config/nvim`. It needs Neovim 0.12 or newer. `vim` and `vi` open `nvim` when it is installed (see [zsh.md](zsh.md)). On servers without Neovim, see [vim.md](vim.md).

## How the config is organized

| File | What is in it |
| --- | --- |
| `init.lua` | Entry point: sets the leader key, then loads the files below |
| `lua/config/options.lua` | Editor options (numbers, indent, search, clipboard) |
| `lua/config/keymaps.lua` | General keymaps |
| `lua/config/autocmds.lua` | Automatic actions (highlight on yank, restore cursor, Go tabs, theme sync) |
| `lua/config/lazy.lua` | Installs lazy.nvim (plugin manager) and loads `lua/plugins/*.lua` |
| `lua/config/theme.lua` | Colors that follow the dotfiles theme, see [theme.md](theme.md) |
| `lua/plugins/*.lua` | One file per topic: completion, editor, format, lsp, telescope, theme, treesitter |

First start: open `nvim` once and wait. lazy.nvim, Mason and treesitter install everything (needs internet and `git`; treesitter needs `tree-sitter-cli`, which is in the Brewfile).

## Leader key and which-key

The leader key is **Space**. `<leader>ut` means: press `Space`, then `u`, then `t`, one after another.

Press `Space` and wait: the **which-key** menu shows the next keys. Groups:

| After Space | Group |
| --- | --- |
| `s` | Search (telescope) |
| `g` | Git (telescope) |
| `h` | Hunks (gitsigns) |
| `d` | Diagnostics and symbols |
| `u` | UI (theme toggle) |

The menu waits for you. `timeoutlen` (0.4 s) only limits key sequences that have no menu. Search all keymaps with `Space s k`.

## Keymaps

### General

| Keys | Mode | What it does |
| --- | --- | --- |
| `jk` | insert | Leave insert mode |
| `Esc` | normal | Clear search highlight |
| `<leader>w` | normal | Save |
| `<leader>q` | normal | Quit the window |
| `Alt+j` / `Alt+k` | normal, visual | Move line or selection down / up |
| `<` / `>` | visual | Indent and keep the selection |
| `Ctrl+d` / `Ctrl+u` | normal | Half page down / up, cursor centered |
| `n` / `N` | normal | Next / previous search result, centered |
| `Ctrl+h/j/k/l` | normal | Move between splits and tmux panes (vim-tmux-navigator) |
| `Ctrl+w v` / `Ctrl+w s` | normal | Split vertical / horizontal (default) |
| `-` | normal | Open the parent folder in oil |
| `<leader>ut` | normal | Toggle light/dark theme |
| `<leader>e` | normal | Show the diagnostic under the cursor |
| `<leader>dq` | normal | Send diagnostics to the location list |

`Alt` needs "Option as Alt" in the terminal, see [terminals.md](terminals.md).

### Search (telescope)

| Keys | What it does |
| --- | --- |
| `<leader>sf` | Search files |
| `<leader>sg` | Search text with grep (needs `rg`) |
| `<leader>sw` | Search the word under the cursor |
| `<leader><leader>` | Open buffers |
| `<leader>s.` | Recent files |
| `<leader>/` | Fuzzy search in the current buffer |
| `<leader>sh` | Search help |
| `<leader>sk` | Search keymaps |
| `<leader>sd` | Search diagnostics |
| `<leader>sr` | Resume the last search |
| `<leader>gc` | Git commits |
| `<leader>gb` | Git branches |

In the telescope window (defaults): `Ctrl+n` / `Ctrl+p` move, `Enter` opens, `Esc` closes.

### Git hunks (gitsigns)

Only in files inside a git repo.

| Keys | What it does |
| --- | --- |
| `]c` / `[c` | Next / previous hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |

### LSP (when a language server is attached)

| Keys | What it does |
| --- | --- |
| `gd` | Go to definition (telescope) |
| `grr` | References (telescope) |
| `gri` | Implementations (telescope) |
| `<leader>D` | Type definition |
| `<leader>ds` | Document symbols |
| `<leader>ws` | Workspace symbols |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>th` | Toggle inlay hints |
| `K` | Hover documentation (Neovim default) |
| `grn` / `gra` | Rename / code action (Neovim defaults) |
| `gO` | Document symbols outline (Neovim default) |
| `]d` / `[d` | Next / previous diagnostic (Neovim default) |

### Completion (blink.cmp)

Completion opens while you type in insert mode. `Enter` accepts the selected item. `Ctrl+n` / `Ctrl+p` select the next / previous item. Other keys are the plugin's `enter` preset (for example `Ctrl+e` hides the menu). `Ctrl+Space` is not used here because it is the tmux prefix.

### Format

`<leader>f` formats the buffer. Files are also formatted on every save (timeout 1.5 s), using the LSP when no formatter is set.

| Language | Formatter |
| --- | --- |
| Go | goimports, then gofumpt |
| TS, TSX, JS, JSON, YAML, Markdown | prettierd, else prettier |
| sh, bash | shfmt |
| Zig | zig fmt |
| Lua | stylua |

Check what is active with `:ConformInfo`.

### Other

- **mini.surround**: `sa` add, `sd` delete, `sr` replace a surrounding. Example: `saiw"` surrounds the word with quotes.
- **mini.ai**: better text objects, for example `vaf` / `vif` (around / inside function), `via` (argument).
- **Comments** (Neovim default): `gcc` toggles a line comment, `gc` plus a motion for more.

## Options worth knowing

Relative line numbers, no line wrap, 2-space indent (Go uses real tabs of width 4), whitespace characters shown, persistent undo, no swap files, mouse on. The system clipboard is used for yank and paste. Over SSH, yanks go to your local clipboard with OSC 52 (paste uses nvim's own register). Files changed outside nvim reload when the window gets focus, and a file reopens at the last cursor position.

## Plugins

| Plugin | What it does |
| --- | --- |
| lazy.nvim | Plugin manager |
| nvim-lspconfig, mason.nvim, mason-lspconfig, mason-tool-installer | Language servers and tools |
| blink.cmp | Completion menu |
| nvim-treesitter (main branch) | Syntax highlighting and indent |
| telescope.nvim (+ fzf-native, plenary) | Fuzzy finder |
| conform.nvim | Formatters and format on save |
| nvim-lint | Linters: golangci-lint (Go), shellcheck (sh, bash) |
| gitsigns.nvim | Git signs in the gutter, hunk actions |
| which-key.nvim | Key hints menu |
| oil.nvim | Edit the file system like a buffer (press `-`) |
| mini.nvim | surround, ai (text objects), statusline |
| vim-tmux-navigator | `Ctrl+h/j/k/l` across tmux and nvim |
| tokyonight.nvim, github-nvim-theme | Colorschemes picked by theme name |

Manage plugins with `:Lazy` (`U` updates, `S` syncs, `q` closes). Auto update checks are off.

## LSP servers, formatters, linters

Installed by Mason on first start: servers `gopls`, `ts_ls` (TypeScript and JavaScript), `bashls`, `lua_ls`; tools `gofumpt`, `goimports`, `prettierd`, `stylua`. `zls` (Zig) comes from Homebrew so it always matches the installed `zig`. `shfmt`, `shellcheck` and `golangci-lint` also come from Homebrew.

Open `:Mason` to see, install (`i`) or remove (`X`) tools by hand. `:checkhealth vim.lsp` shows the servers attached to the current buffer.

## Add a plugin

1. Create `nvim/.config/nvim/lua/plugins/<name>.lua` that returns a plugin spec:

   ```lua
   -- Short comment: what it does.
   return {
     "author/plugin.nvim",
     event = "VeryLazy",   -- when to load it
     opts = {},            -- passed to plugin.setup()
   }
   ```

2. Restart nvim. lazy.nvim installs it. Check with `:Lazy`.
3. Put its keymaps in the spec (`keys = { ... }`) with a `desc`, so which-key shows them. If you add a new `<leader>x` group, add its name in the which-key `spec` in `lua/plugins/editor.lua`.

## Add a language server

1. Add its Mason name to `ensure_installed` in `lua/plugins/lsp.lua` (the `mason-lspconfig` list). Names are in `:Mason`. Example: `"pyright"`.
2. Settings are optional: `vim.lsp.config("pyright", { settings = { ... } })`, next to the existing ones.
3. A server that is not in Mason (like `zls`): install it with Homebrew and enable it with `vim.lsp.enable("name")` when `vim.fn.executable("name") == 1`.
4. For a formatter, add it to `formatters_by_ft` in `lua/plugins/format.lua` (and to `mason-tool-installer`'s `ensure_installed`). For a linter, add it to `linters_by_ft` in the same file.
5. For a new language's colors, add the parser name to the `parsers` list in `lua/plugins/treesitter.lua`.

## Check that everything works

Run `:checkhealth` (or `:checkhealth vim.lsp`, `:checkhealth mason`, `:checkhealth nvim-treesitter`). Look for lines marked ERROR or WARNING. Common fixes: install `git`, `curl`, `ripgrep`, `fd`, `tree-sitter-cli`, a C compiler for `make` (telescope-fzf-native).

## Theme

`<leader>ut` toggles light/dark. The colors come from `~/.config/theme/config`, see [theme.md](theme.md).
