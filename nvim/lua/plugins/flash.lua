-- Plugin: flash.nvim
-- Description: Jump anywhere on screen in 2 keystrokes using labels.
-- Keybinds: s (jump), S (treesitter node select), r (remote op, operator mode)

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  keys = {
    { "s",     function() require("flash").jump() end,              mode = { "n", "x", "o" }, desc = "Flash: Jump" },
    { "S",     function() require("flash").treesitter() end,        mode = { "n", "x", "o" }, desc = "Flash: Treesitter" },
    { "r",     function() require("flash").remote() end,            mode = "o",               desc = "Flash: Remote" },
    { "R",     function() require("flash").treesitter_search() end, mode = { "o", "x" },      desc = "Flash: TS Search" },
    { "<C-s>", function() require("flash").toggle() end,            mode = "c",               desc = "Flash: Toggle" },
  },
  config = function()
    require("flash").setup({
      labels = "asdfghjklqwertyuiopzxcvbnm",
      search = { multi_window = true },
      label = { uppercase = false },
      modes = {
        search = { enabled = false },
      },
    })
  end,
}
