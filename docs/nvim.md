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
| `lua/config/mermaid.lua` | Finds the Mermaid block under the cursor; shows it rendered by `mermaid-ascii` or opens the buffer with `md-open` |
| `lua/plugins/*.lua` | One file per topic |

## Decisions

- **`Ctrl+Space` isn't mapped**: it's the tmux prefix.
- **`Ctrl+h/j/k/l`** cross nvim splits and tmux panes (vim-tmux-navigator).
- **Clipboard**: yanks go to the system clipboard, over SSH through OSC 52. Paste uses nvim's own register, because terminals often block OSC 52 reads.
- **Format on save** (1.5 s timeout) with conform; `<leader>cf` formats the buffer on demand; LSP formatting when no formatter is set. `:ConformInfo` shows what applies.
- **Lint** with nvim-lint: golangci-lint (Go), shellcheck (sh).
- **neo-tree** is the only file explorer: `nvim .` opens it in the current window, `<leader>fe` toggles it as a sidebar on the current file. It shows dotfiles but hides `.git`, `.zig-cache` and `zig-out`.
- **LSP keys** are Neovim's defaults (`grn` rename, `gra` code action, `grr`, `gri`, `grt`, `gO`, `K`); Telescope shows `gd`, `grr`, `gri`, `grt` and `gO`. `<leader>uh` toggles inlay hints; `<C-w>d` shows the diagnostic under the cursor.
- **JSON and YAML** servers get their schemas from SchemaStore.nvim.
- **`timeoutlen` is 0.4 s**: it only affects sequences without a which-key menu.
- **Go** uses real tabs of width 4; everything else 2 spaces.
- **Plugin update checks are off**: update with `:Lazy` then `U`.
- **`zls`, `shfmt`, `shellcheck` and `golangci-lint` come from mise**, not Mason: `zls` must match `zig`. bashls has shellcheck off, since nvim-lint runs it.
- **Resize**: when the terminal or tmux pane is resized, windows in every tab are rebalanced; `winfixwidth` windows (diffview file panel) keep their width.
- **Mermaid**: `<leader>md` in a Markdown file renders the ` ```mermaid ` block under the cursor (fences included) in a float; `q` or `Esc` closes it. Same diagram types as [mermaid-ascii](tools.md).
- **Markdown in the browser**: `<leader>mo` runs `md-open` on the buffer's current text (unsaved edits included, nothing written to disk). With the cursor in a ` ```mermaid ` block it opens only that block as one diagram, titled `<file>:<line>`; anywhere else it opens the whole buffer rendered like GitHub (tables, task lists, highlighted code, Mermaid blocks as diagrams), with relative images and links resolved from the buffer's folder. `md-open [file]` also works in a shell: a `.md` file is the full page, a `.mmd` or `.mermaid` file is one diagram, and stdin (`-`) is Markdown when `--name` ends in `.md` or it has a ` ```mermaid ` fence, else one diagram. `--name <name>` sets the page title and `--dir <dir>` the folder for relative paths; both are meant for stdin. The page is one file in a private temp folder, opened with `open` (macOS) or `xdg-open` (Linux); pages older than a day are deleted on the next run. It is offline: the libraries are vendored in `bin/.local/share/md-open/` (versions and update steps in its `README`), the scripts load by absolute `file://` path, raw HTML goes through DOMPurify and a content-security policy blocks every network request. It follows the system light/dark setting and shows the error text of a diagram that fails.
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

1. Server: its lspconfig name in the one `ensure_installed` list of `mason-tool-installer` in `lua/plugins/lsp.lua`; settings with `vim.lsp.config("name", { ... })`. A server not in Mason: install with mise, then `vim.lsp.enable("name")` behind `vim.fn.executable("name") == 1`.
2. Formatter: `formatters_by_ft` in `lua/plugins/format.lua` and the same `ensure_installed` list. Linter: `linters_by_ft` in the same file.
3. Colors: the parser name in `parsers` in `lua/plugins/treesitter.lua`.

## Plain Vim

`vim/.vimrc` is a small plugin-free config for servers without Neovim, with the same basic keys (`jk`, `<leader>w`, `<leader>q`, `Ctrl+h/j/k/l` into tmux). It loads no local override file. Use `command vim` to reach it where nvim exists.

## Troubleshooting

- **Plugins or parsers fail on first start:** check `git` and `curl`, run `mise install` (ripgrep, fd, tree-sitter), then `:checkhealth`.
- **Telescope fuzzy matching slow or missing:** install a C compiler and `make`, then `:Lazy build telescope-fzf-native.nvim`.
- **`Alt+j` / `Alt+k` do nothing:** the terminal needs Option as Alt ([terminals.md](terminals.md)).
- **No language help:** `:checkhealth vim.lsp` (attached servers and their logs), then `:Mason`.
