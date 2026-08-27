-- Plugin: live-server.nvim
-- Description: Pure-Lua local web server with live-reload for HTML, CSS, and JS.
-- Keybinds: <leader>lp (Start live server), <leader>ls (Stop live server), <leader>lo (Open in browser)

return {
  "selimacerbas/live-server.nvim",
  cmd = { "LiveServerStart", "LiveServerStop", "LiveServerOpen", "LiveServerStatus" },
  ft = { "html", "htmldjango", "css", "javascript", "typescript" },
  keys = {
    {
      "<leader>lp",
      "<cmd>LiveServerStart<cr>",
      desc = "LiveServer: Start Preview",
      ft = { "html", "htmldjango" },
    },
    {
      "<leader>ls",
      "<cmd>LiveServerStop<cr>",
      desc = "LiveServer: Stop Preview",
      ft = { "html", "htmldjango" },
    },
    {
      "<leader>lo",
      "<cmd>LiveServerOpen<cr>",
      desc = "LiveServer: Open in Browser",
    },
  },
  opts = {
    default_port = 8000,
    open_on_start = true,
  },
  config = function(_, opts)
    require("live_server").setup(opts)
  end,
}
