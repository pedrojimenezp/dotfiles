# Neovim

Config: `nvim/.config/nvim`. Keys: press `Space` and wait (which-key), or `<leader>sk`. `vim` and `vi` open `nvim` when it exists.

Needs Neovim 0.12+, `git` and network on the first start, the `tree-sitter` CLI (mise), and a C compiler for telescope-fzf-native. The first start installs plugins (lazy.nvim), parsers (treesitter) and Mason tools: wait until the messages stop.

## Layout

| File | Holds |
| --- | --- |
| `init.lua` | Sets the leader, loads the rest |
| `lua/config/options.lua`, `keymaps.lua`, `autocmds.lua` | Options, general keymaps, autocommands |
| `lua/config/lazy.lua` | Bootstraps lazy.nvim, loads `lua/plugins/*.lua` |
| `lua/config/theme.lua` | Colors that follow the dotfiles theme |
| `lua/plugins/*.lua` | One file per topic |

## Decisions

- **`Ctrl+Space` isn't mapped**: it's the tmux prefix.
- **`Ctrl+h/j/k/l`** cross nvim splits and tmux panes (vim-tmux-navigator).
- **Clipboard**: yanks go to the system clipboard, over SSH through OSC 52. Paste uses nvim's own register, because terminals often block OSC 52 reads.
- **Format on save** (1.5 s timeout) with conform; LSP formatting when no formatter is set. `:ConformInfo` shows what applies.
- **Lint** with nvim-lint: golangci-lint (Go), shellcheck (sh).
- **oil** handles `nvim .` and `-`; neo-tree is only a sidebar (`<leader>fe`). It shows dotfiles but hides `.git`, `.zig-cache` and `zig-out`.
- **`timeoutlen` is 0.4 s**: it only affects sequences without a which-key menu.
- **Go** uses real tabs of width 4; everything else 2 spaces.
- **Plugin update checks are off**: update with `:Lazy` then `U`.
- **`zls`, `shfmt`, `shellcheck` and `golangci-lint` come from mise**, not Mason: `zls` must match `zig`. bashls has shellcheck off, since nvim-lint runs it.
- **Theme**: `<leader>ut` runs the `theme` script, then nvim reads the pair from `~/.config/theme/config` ([theme.md](theme.md)).

## Add a plugin

1. Create `lua/plugins/<name>.lua` returning a spec:
   ```lua
   return {
     "author/plugin.nvim",
     event = "VeryLazy",
     opts = {},
   }
   ```
2. Put its keys in `keys = { ... }` with a `desc`, so which-key lists them. A new `<leader>x` group goes in the which-key `spec` in `lua/plugins/editor.lua`.
3. Restart nvim; `:Lazy` shows it without errors.

## Add a language

1. Server: its Mason name in `ensure_installed` of `mason-lspconfig` in `lua/plugins/lsp.lua`; settings with `vim.lsp.config("name", { ... })`. A server not in Mason: install with mise, then `vim.lsp.enable("name")` behind `vim.fn.executable("name") == 1`.
2. Formatter: `formatters_by_ft` in `lua/plugins/format.lua` and `mason-tool-installer`'s `ensure_installed`. Linter: `linters_by_ft` in the same file.
3. Colors: the parser name in `parsers` in `lua/plugins/treesitter.lua`.

## Plain Vim

`vim/.vimrc` is a small plugin-free config for servers without Neovim, with the same basic keys (`jk`, `<leader>w`, `<leader>q`, `Ctrl+h/j/k/l` into tmux). It loads no local override file. Use `command vim` to reach it where nvim exists.

## Troubleshooting

- **Plugins or parsers fail on first start:** check `git` and `curl`, run `mise install` (ripgrep, fd, tree-sitter), then `:checkhealth`.
- **Telescope fuzzy matching slow or missing:** install a C compiler and `make`, then `:Lazy build telescope-fzf-native.nvim`.
- **`Alt+j` / `Alt+k` do nothing:** the terminal needs Option as Alt ([terminals.md](terminals.md)).
- **No language help:** `:checkhealth vim.lsp`, then `:Mason`.
