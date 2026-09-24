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
      { "<leader>l",  group = "language/live" },
      { "<leader>c",  group = "cmake" },
      { "<leader>d",  group = "debug" },
      { "<leader>f",  group = "find" },
      { "<leader>g",  group = "git/goto" },
      { "<leader>j",  desc  = "Split/Join toggle" },
      { "<leader>n",  group = "notebook/annotate" },
      { "<leader>na", desc = "Notebook: Add cell above / Annotate" },
      { "<leader>nA", desc = "Notebook: Run all cells above" },
      { "<leader>nb", desc = "Notebook: Add cell below" },
      { "<leader>nB", desc = "Notebook: Run all cells below" },
      { "<leader>nc", desc = "Notebook: Clear cell output" },
      { "<leader>nC", desc = "Notebook: Clear all outputs" },
      { "<leader>nd", desc = "Notebook: Delete cell / Dismiss" },
      { "<leader>nD", desc = "Notebook: Delete cell image" },
      { "<leader>ni", desc = "Notebook: Interrupt kernel" },
      { "<leader>nI", desc = "Notebook: Save cell image" },
      { "<leader>nj", desc = "Notebook: Move cell down" },
      { "<leader>nk", desc = "Notebook: Move cell up" },
      { "<leader>nK", desc = "Notebook: Select kernel" },
      { "<leader>nL", desc = "Notebook: Refresh display" },
      { "<leader>nm", desc = "Notebook: Convert to markdown" },
      { "<leader>no", desc = "Notebook: Toggle output expand" },
      { "<leader>nr", desc = "Notebook: Run cell + advance" },
      { "<leader>nR", desc = "Notebook: Run all cells" },
      { "<leader>ns", desc = "Notebook: Start kernel" },
      { "<leader>nS", desc = "Notebook: Stop kernel" },
      { "<leader>nx", desc = "Notebook: Restart kernel" },
      { "<leader>ny", desc = "Notebook: Convert to code" },
      { "<leader>q",  group = "session" },
      { "<leader>r",  group = "rename" },
      { "<leader>R",  group = "remote-sshfs" },
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
