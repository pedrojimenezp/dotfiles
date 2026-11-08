return {
  "saghen/blink.cmp",
  version = "1.*", -- stable releases ship prebuilt binaries
  event = "InsertEnter",
  opts = {
    keymap = { preset = "enter" }, -- Ctrl-Space is the tmux prefix
    appearance = { nerd_font_variant = "mono" },
    completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    signature = { enabled = true },
  },
}
