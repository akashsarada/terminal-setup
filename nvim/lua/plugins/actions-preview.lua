-- Plugin: actions-preview.nvim
-- Description: Code action picker with diff preview before applying.
-- Keybinds: <leader>la (code action with preview)

return {
  "aznhe21/actions-preview.nvim",
  event = "LspAttach",
  config = function()
    require("actions-preview").setup({
      telescope = {
        sorting_strategy = "ascending",
        layout_strategy = "vertical",
        layout_config = {
          width = 0.8,
          height = 0.9,
          prompt_position = "top",
          preview_cutoff = 20,
          preview_height = function(_, _, max_lines)
            return max_lines - 20
          end,
        },
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>la",
      require("actions-preview").code_actions,
      { desc = "Code Action (preview)" })
  end,
}
