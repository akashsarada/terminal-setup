-- Plugin: clangd_extensions.nvim
-- Description: Inlay hints (param names, auto types), enhanced clangd features.
-- Note: clangd server config stays in lsp-config.lua; this adds UI/hint layer only.

return {
  "p00f/clangd_extensions.nvim",
  ft = { "c", "cpp" },
  config = function()
    require("clangd_extensions").setup({
      inlay_hints = {
        inline = true,
        only_current_line = false,
        show_parameter_hints = true,
        parameter_hints_prefix = "← ",
        other_hints_prefix = "» ",
      },
      ast = {
        role_icons = {
          type = "",
          declaration = "",
          expression = "󰆦",
          specifier = "",
          statement = "󰅩",
          ["template argument"] = "󰊄",
        },
      },
    })

    -- Toggle inlay hints with <leader>ih
    vim.keymap.set("n", "<leader>ih", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { desc = "Toggle inlay hints" })
  end,
}
