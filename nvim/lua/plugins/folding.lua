-- Plugin: nvim-ufo
-- Description: LSP/treesitter-powered code folding. Shows folded line count.
-- Keybinds: zR (open all), zM (close all), zp (peek fold without opening)

return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "BufReadPost",
  init = function()
    vim.o.foldcolumn   = "1"
    vim.o.foldlevel    = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable   = true
  end,
  config = function()
    require("ufo").setup({
      provider_selector = function(_, filetype, _)
        local ts_fts = { "cpp", "c", "lua", "python", "typescript", "javascript" }
        for _, ft in ipairs(ts_fts) do
          if filetype == ft then return { "treesitter", "indent" } end
        end
        return { "lsp", "indent" }
      end,
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = ("  %d lines"):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            table.insert(newVirtText, { chunkText, chunk[2] })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end,
    })

    vim.keymap.set("n", "zR", require("ufo").openAllFolds,                    { desc = "Open all folds" })
    vim.keymap.set("n", "zM", require("ufo").closeAllFolds,                   { desc = "Close all folds" })
    vim.keymap.set("n", "zp", require("ufo").peekFoldedLinesUnderCursor,      { desc = "Peek fold" })
  end,
}
