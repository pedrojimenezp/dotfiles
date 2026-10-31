# Neovim

The editor config: `nvim/.config/nvim`, linked to `~/.config/nvim`. `vim` and `vi` open `nvim` when it is installed (see [zsh.md](zsh.md)).

You'll use it for: editing code with search, git signs, completion, formatting and language-server help.

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Leader key and which-key](#leader-key-and-which-key)
- [Keymaps](#keymaps)
- [Options worth knowing](#options-worth-knowing)
- [Plugins](#plugins)
- [Add a plugin](#add-a-plugin)
- [Add a language server](#add-a-language-server)
- [Check that everything works](#check-that-everything-works)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)

## Requirements

- Neovim 0.12 or newer.
- `git` and internet access on the first start.
- The `tree-sitter` CLI (in the mise config) for syntax parsers. Also useful: `curl`, `ripgrep`, `fd`, and a C compiler for the telescope fuzzy matcher.

On servers without Neovim, see [vim.md](vim.md).

## Quick start

1. Open `nvim` once and wait. [lazy.nvim](https://github.com/folke/lazy.nvim) (the plugin manager), [Mason](glossary.md#mason) and [treesitter](glossary.md#treesitter) install everything.
2. Press `Space` and wait: a menu lists the next keys.
3. Press `<leader>sf` (`Space` then `s f`) to search files.
4. Press `-` to browse the current folder as a buffer.
5. Press `<leader>w` to save, `<leader>q` to quit the window.

## Leader key and which-key

The [leader](glossary.md#leader) key is **Space**. `<leader>ut` means: press `Space`, then `u`, then `t`, one after another.

The **which-key** menu appears when you press `Space` and wait. Its groups:

| After Space | Group |
| --- | --- |
| `s` | Search (telescope) |
| `g` | Git (telescope) |
| `h` | Hunks (gitsigns) |
| `d` | Diagnostics and symbols |
| `u` | UI (theme toggle) |

Search all keymaps with `<leader>sk`.

## Keymaps

Neovim has modes. In **normal** mode, keys are commands. In **insert** mode, keys type text. In **visual** mode, keys act on a selection. `Esc` (or `jk` in insert mode) returns to normal mode.

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

In the telescope window: `Ctrl+n` / `Ctrl+p` move, `Enter` opens, `Esc` closes.

### Git hunks (gitsigns)

A [hunk](glossary.md#hunk) is one block of changed lines in a file. These keys work only in files inside a git repo.

| Keys | What it does |
| --- | --- |
| `]c` / `[c` | Next / previous hunk (in a diff, the next / previous change) |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |

### Language server ([LSP](glossary.md#lsp))

A language server gives the editor code help: definitions, rename, errors. These keys work when a server is attached to the file.

| Keys | What it does |
| --- | --- |
| `gd` | Go to definition (telescope) |
| `grr` | References (telescope) |
| `gri` | Implementations (telescope) |
| `<leader>D` | Type definition |
| `<leader>ds` | Document symbols |
| `<leader>sS` | Workspace symbols |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>th` | Toggle inlay hints |
| `K` | Hover documentation (Neovim default) |
| `grn` / `gra` | Rename / code action (Neovim defaults) |
| `gO` | Document symbols outline (Neovim default) |
| `]d` / `[d` | Next / previous diagnostic (Neovim default) |

### Completion (blink.cmp)

Completion opens while you type in insert mode.

- `Enter` accepts the selected item.
- `Ctrl+n` / `Ctrl+p` select the next / previous item.
- Other keys follow the plugin's `enter` preset. For example, `Ctrl+e` hides the menu.

`Ctrl+Space` is not used here because it is the tmux [prefix](glossary.md#prefix).

### Format

`<leader>f` formats the buffer. Files are also formatted on every save (timeout 1.5 s), using the language server when no formatter is set.

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

- Relative line numbers, no line wrap, whitespace characters shown, mouse on.
- 2-space indent. Go uses real tabs of width 4.
- Persistent undo, no swap files.
- The system clipboard is used for yank and paste. Over SSH, yanks go to your local clipboard with [OSC 52](glossary.md#osc-52). Paste uses nvim's own register.
- Files changed outside nvim reload when the window gets focus.
- A file reopens at the last cursor position.

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

Manage plugins with `:Lazy`: `U` updates, `S` syncs, `q` closes. Automatic update checks are off.

### Language servers, formatters, linters

Mason installs these on first start:

- Servers: `gopls`, `ts_ls` (TypeScript and JavaScript), `bashls`, `lua_ls`.
- Tools: `gofumpt`, `goimports`, `prettierd`, `stylua`.

mise provides `zls` (pinned to the same version as `zig`), `shfmt`, `shellcheck` and `golangci-lint`.

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

2. Restart nvim. lazy.nvim installs it.
3. Put its keymaps in the spec (`keys = { ... }`) with a `desc`, so which-key shows them. For a new `<leader>x` group, add its name to the which-key `spec` in `lua/plugins/editor.lua`.

Check it worked: `:Lazy` lists the plugin without errors.

## Add a language server

1. Add its Mason name to `ensure_installed` in `lua/plugins/lsp.lua` (the `mason-lspconfig` list). Names are in `:Mason`. Example: `"pyright"`.
2. Settings are optional: `vim.lsp.config("pyright", { settings = { ... } })`, next to the existing ones.
3. For a server that is not in Mason (like `zls`), install it with mise (add it to `mise/.config/mise/config.toml`). Enable it with `vim.lsp.enable("name")` when `vim.fn.executable("name") == 1`.
4. For a formatter, add it to `formatters_by_ft` in `lua/plugins/format.lua` and to `mason-tool-installer`'s `ensure_installed`. For a linter, add it to `linters_by_ft` in the same file.
5. For a new language's colors, add the parser name to the `parsers` list in `lua/plugins/treesitter.lua`.

## Check that everything works

Run `:checkhealth`, or a narrower check: `:checkhealth vim.lsp`, `:checkhealth mason`, `:checkhealth nvim-treesitter`. Look for lines marked ERROR or WARNING.

## Troubleshooting

- **Plugins or parsers fail on the first start**: check that `git` and `curl` exist, run `mise install` (it provides `ripgrep`, `fd` and `tree-sitter`), then run `:checkhealth`.
- **Telescope fuzzy matching is slow or missing**: install a C compiler and `make`, then run `:Lazy build telescope-fzf-native.nvim`.
- **`Alt+j` / `Alt+k` do nothing**: set "Option as Alt" in the terminal, see [terminals.md](terminals.md).
- **No language help in a file**: run `:checkhealth vim.lsp` and check `:Mason` for the server.

## How it works

| File | What is in it |
| --- | --- |
| `init.lua` | Entry point: sets the leader key, then loads the files below |
| `lua/config/options.lua` | Editor options (numbers, indent, search, clipboard) |
| `lua/config/keymaps.lua` | General keymaps |
| `lua/config/autocmds.lua` | Automatic actions (highlight on yank, restore cursor, Go tabs, theme sync) |
| `lua/config/lazy.lua` | Installs lazy.nvim and loads `lua/plugins/*.lua` |
| `lua/config/theme.lua` | Colors that follow the dotfiles theme, see [theme.md](theme.md) |
| `lua/plugins/*.lua` | One file per topic: completion, editor, format, lsp, telescope, theme, treesitter |

**Key timeout.** `timeoutlen` is 0.4 s. It only limits key sequences that have no which-key menu, because the menu itself waits for you.

**Theme.** `<leader>ut` runs the `theme` script, which recolors the terminal. Then nvim follows by reading the colors from `~/.config/theme/config`. See [theme.md](theme.md).

## Related

- [vim.md](vim.md): the small config for servers.
- [theme.md](theme.md): light and dark colors.
- [tmux.md](tmux.md): panes and the shared `Ctrl+h/j/k/l` keys.
- [terminals.md](terminals.md): `Alt` and fonts.
