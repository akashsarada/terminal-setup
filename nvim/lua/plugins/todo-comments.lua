-- Plugin: todo-comments.nvim
-- Description: Highlights TODO/FIXME/HACK/NOTE with telescope integration.
-- Keybinds: <leader>ft (list all), ]t / [t (jump next/prev)

return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "BufReadPost",
  keys = {
    { "<leader>ft", "<cmd>TodoTelescope<cr>",                                    desc = "Find: TODOs" },
    { "<leader>fT", "<cmd>TodoTrouble<cr>",                                      desc = "Trouble: TODOs" },
    { "]t",         function() require("todo-comments").jump_next() end,         desc = "Next TODO" },
    { "[t",         function() require("todo-comments").jump_prev() end,         desc = "Prev TODO" },
  },
  config = function()
    require("todo-comments").setup()
  end,
}
