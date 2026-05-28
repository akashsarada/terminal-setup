-- Plugin: persistence.nvim
-- Description: Saves and restores buffer/layout sessions per working directory.
-- Keybinds: <leader>qs (restore), <leader>ql (last session), <leader>qd (don't save)

return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  keys = {
    { "<leader>qs", function() require("persistence").load() end,              desc = "Session: Restore" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Session: Restore Last" },
    { "<leader>qd", function() require("persistence").stop() end,              desc = "Session: Don't Save" },
  },
  config = function()
    require("persistence").setup({
      dir = vim.fn.stdpath("state") .. "/sessions/",
    })
  end,
}
