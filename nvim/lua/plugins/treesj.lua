-- Plugin: treesj
-- Description: Split/join function args, arrays, objects with treesitter awareness.
-- Keybinds: <leader>j (toggle split/join)

return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "<leader>j", function() require("treesj").toggle() end, desc = "Split/Join Toggle" },
  },
  config = function()
    require("treesj").setup({
      use_default_keymaps = false,
      check_syntax_error = true,
      max_join_length = 120,
    })
  end,
}
