-- Plugin: gitsigns.nvim
-- Description: Git hunk indicators, inline blame, and hunk actions.
-- Keybinds: ]h/[h (nav hunks), <leader>gs (stage), <leader>gp (preview), <leader>gb (blame)

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      current_line_blame_opts = {
        delay = 500,
        virt_text_pos = "eol",
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        map("n", "]h", function() gs.nav_hunk("next") end, { desc = "Next hunk" })
        map("n", "[h", function() gs.nav_hunk("prev") end, { desc = "Prev hunk" })
        map("n", "<leader>gs", gs.stage_hunk,                { desc = "Git: Stage hunk" })
        map("n", "<leader>gu", gs.undo_stage_hunk,           { desc = "Git: Undo stage hunk" })
        map("n", "<leader>gp", gs.preview_hunk,              { desc = "Git: Preview hunk" })
        map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Git: Toggle blame" })
        map("n", "<leader>gB", function() gs.blame_line({ full = true }) end, { desc = "Git: Full blame" })
        map("v", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Git: Stage selected hunks" })
      end,
    })
  end,
}
