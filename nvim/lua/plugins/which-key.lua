-- Plugin: which-key.nvim
-- Description: Displays pending keybindings in a popup on leader press.

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({
      preset = "modern",
      delay = 400,
    })

    wk.add({
      { "<leader>a",  group = "aerial/outline" },
      { "<leader>h",  group = "harpoon" },
      { "<leader>l",  group = "language" },
      { "<leader>c",  group = "cmake" },
      { "<leader>d",  group = "debug" },
      { "<leader>f",  group = "find" },
      { "<leader>g",  group = "git/goto" },
      { "<leader>j",  desc  = "Split/Join toggle" },
      { "<leader>n",  group = "diagnostics/annotate" },
      { "<leader>q",  group = "session" },
      { "<leader>r",  group = "rename" },
      { "<leader>s",  group = "search/swap" },
      { "<leader>t",  group = "test/terminal" },
      { "<leader>m",  group = "markdown" },

      { "<leader>x",  group = "trouble" },
      { "<leader>D",  desc  = "Type definition" },

      { "<leader>ih", desc  = "Toggle inlay hints" },
      { "]",          group = "next" },
      { "[",          group = "prev" },
      { "g",          group = "goto/preview" },
      { "z",          group = "fold" },
    })
  end,
}
