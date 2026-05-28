-- Plugin: nvim-bqf
-- Description: Enhanced quickfix with preview pane and fuzzy filtering.
-- Usage: Automatically active in any quickfix window (CMake errors, grep results, etc.)

return {
  "kevinhwang91/nvim-bqf",
  ft = "qf",
  config = function()
    require("bqf").setup({
      auto_enable = true,
      auto_resize_height = true,
      preview = {
        win_height = 12,
        win_vheight = 12,
        delay_syntax = 80,
        border = "rounded",
        show_title = true,
      },
      func_map = {
        open = "<cr>",
        openc = "o",
        split = "<C-s>",
        vsplit = "<C-v>",
        tab = "t",
        prevfile = "<C-p>",
        nextfile = "<C-n>",
        pscrollup = "<C-b>",
        pscrolldown = "<C-f>",
      },
    })
  end,
}
