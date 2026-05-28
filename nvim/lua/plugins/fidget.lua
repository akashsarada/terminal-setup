-- Plugin: fidget.nvim
-- Description: LSP progress spinner and notification history in the corner.

return {
  "j-hui/fidget.nvim",
  event = "LspAttach",
  config = function()
    require("fidget").setup({
      progress = {
        poll_rate = 0,                -- update as fast as possible
        suppress_on_insert = false,
        ignore_done_already = false,
        display = {
          render_limit = 10,
          done_ttl = 5,              -- keep "done" visible for 5s
          done_icon = "✓",
          progress_icon = { pattern = "dots", period = 1 },
        },
      },
      notification = {
        poll_rate = 10,
        filter = vim.log.levels.DEBUG, -- show everything including debug
        window = {
          winblend = 0,
          border = "rounded",
          zindex = 45,
          max_width = 60,
        },
      },
    })
  end,
}
