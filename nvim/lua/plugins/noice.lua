-- Plugin: noice.nvim
-- Description: Replaces cmdline, messages, and LSP progress with floating UI.
-- Note: Delete this file + :Lazy clean to fully revert to default behavior.

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("noice").setup({
      messages = { enabled = true },
      popupmenu = { enabled = true },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        progress = { enabled = false },
        hover = { enabled = true },
        signature = { enabled = false },
      },
      presets = {
        long_message_to_split = true,
        inc_rename = true,
      },
      routes = {
        -- Hide "written" messages
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
        -- Hide search count noise
        { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
        -- Hide auto-save notifications
        { filter = { event = "notify", find = "[Aa]uto.?[Ss]ave" }, opts = { skip = true } },
        { filter = { event = "msg_show", find = "[Aa]uto.?[Ss]ave" }, opts = { skip = true } },
        -- Hide Neovim 0.11 plugin compatibility warnings
        { filter = { event = "notify", find = "supports_method" },         opts = { skip = true } },
        { filter = { event = "notify", find = "position_encoding" },       opts = { skip = true } },
        { filter = { event = "msg_show", find = "supports_method" },       opts = { skip = true } },
        { filter = { event = "msg_show", find = "position_encoding" },     opts = { skip = true } },
      },
    })

    -- Dismiss notification with <leader>nd
    vim.keymap.set("n", "<leader>nd", "<cmd>NoiceDismiss<cr>", { desc = "Dismiss Notifications" })
  end,
}
