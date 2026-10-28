-- blink.cmp: fast completion menu fed by LSP, paths, snippets and buffer words.
return {
  "saghen/blink.cmp",
  version = "1.*", -- stable releases ship prebuilt binaries
  event = "InsertEnter", -- load when you start typing
  opts = {
    keymap = { preset = "enter" }, -- Enter accepts, Ctrl-n/p select (Ctrl-Space is the tmux prefix)
    appearance = { nerd_font_variant = "mono" }, -- align icons with a Nerd Font
    completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } }, -- doc popup next to the menu
    sources = { default = { "lsp", "path", "snippets", "buffer" } }, -- where candidates come from
    signature = { enabled = true }, -- function signature help while typing arguments
  },
}
