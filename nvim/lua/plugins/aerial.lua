-- Plugin: aerial.nvim
-- Description: Code outline/structure panel showing symbols, functions, classes.
-- Keybinds: <leader>ao (toggle), { / } (jump prev/next symbol in source buffer)

return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>ao", "<cmd>AerialToggle!<cr>", desc = "Aerial: Toggle Outline" },
    { "<leader>an", "<cmd>AerialNavToggle<cr>", desc = "Aerial: Nav Toggle" },
  },
  config = function()
    require("aerial").setup({
      backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
      layout = {
        max_width = { 40, 0.2 },
        width = nil,
        min_width = 20,
        default_direction = "right",
        placement = "edge",
      },
      show_guides = true,
      on_attach = function(bufnr)
        vim.keymap.set("n", "{", "<cmd>AerialPrev<cr>", { buffer = bufnr, desc = "Aerial: Prev Symbol" })
        vim.keymap.set("n", "}", "<cmd>AerialNext<cr>", { buffer = bufnr, desc = "Aerial: Next Symbol" })
      end,
    })
    require("telescope").load_extension("aerial")
  end,
}
