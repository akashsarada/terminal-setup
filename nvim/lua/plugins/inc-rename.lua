-- Plugin: inc-rename.nvim
-- Description: Live inline preview while renaming symbols (replaces silent lsp rename).
-- Keybinds: <leader>rn (rename with live preview in cmdline)

return {
  "smjonas/inc-rename.nvim",
  event = "LspAttach",
  config = function()
    require("inc_rename").setup({
      input_buffer_type = "dressing",
    })

    -- Override the lsp rename keymap set in lsp-config with live preview version
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        vim.keymap.set("n", "<leader>rn", function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end, { expr = true, buffer = args.buf, desc = "Rename (live preview)" })
      end,
    })
  end,
}
