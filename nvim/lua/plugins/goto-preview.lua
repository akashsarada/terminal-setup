-- Plugin: goto-preview.nvim
-- Description: Peek definition/impl/refs in floating window without navigating away.
-- Keybinds: gpd (def), gpi (impl), gpr (refs), gpc (close all)

return {
  "rmagatti/goto-preview",
  event = "LspAttach",
  config = function()
    require("goto-preview").setup({
      width = 120,
      height = 25,
      border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
      default_mappings = false,
      opacity = nil,
      post_open_hook = nil,
    })

    vim.keymap.set("n", "gpd", require("goto-preview").goto_preview_definition,      { desc = "Preview: Definition" })
    vim.keymap.set("n", "gpi", require("goto-preview").goto_preview_implementation,  { desc = "Preview: Implementation" })
    vim.keymap.set("n", "gpr", require("goto-preview").goto_preview_references,      { desc = "Preview: References" })
    vim.keymap.set("n", "gpc", require("goto-preview").close_all_win,                { desc = "Preview: Close All" })
  end,
}
