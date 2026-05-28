-- Plugin: trouble.nvim
-- Description: Structured diagnostics, references, and quickfix panel.
-- Keybinds: <leader>xx (workspace diag), <leader>xd (doc diag), <leader>xq (quickfix)

return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Trouble: Workspace Diagnostics" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Trouble: Document Diagnostics" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                             desc = "Trouble: Quickfix List" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>",                            desc = "Trouble: Location List" },
    { "<leader>xr", "<cmd>Trouble lsp_references toggle focus=true<cr>",          desc = "Trouble: LSP References" },
  },
  config = function()
    require("trouble").setup({
      modes = {
        diagnostics = {
          auto_close = true,
        },
      },
    })
  end,
}
