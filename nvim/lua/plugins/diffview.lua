-- Plugin: diffview.nvim
-- Description: Full git diff viewer and file history browser.
-- Keybinds: <leader>gv (diff open), <leader>gh (file history), <leader>gH (repo history)

return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>",          desc = "Git: Diff View" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: File History" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",   desc = "Git: Repo History" },
    { "<leader>gx", "<cmd>DiffviewClose<cr>",         desc = "Git: Close Diffview" },
  },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
        file_history = { layout = "diff2_horizontal" },
      },
    })
  end,
}
