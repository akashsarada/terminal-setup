-- Plugin: nvim-surround
-- Description: Add/change/delete surrounding brackets, quotes, tags.
-- Usage: ys{motion}{char} (add), cs{old}{new} (change), ds{char} (delete)
-- Example: ysiw" wraps word in quotes, cs"' changes " to ', ds( removes parens

return {
  "kylechui/nvim-surround",
  version = "*",
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup()
  end,
}
