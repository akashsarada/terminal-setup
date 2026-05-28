-- Plugin: vim-visual-multi
-- Description: Multi-cursor support. Ctrl+D selects next occurrence like VSCode.
-- Usage: <C-d> select next, <C-Up>/<C-Down> add cursor, <Tab> toggle cursor/select mode

return {
  "mg979/vim-visual-multi",
  branch = "master",
  event = "BufReadPost",
  init = function()
    vim.g.VM_maps = {
      ["Find Under"]         = "<C-d>",
      ["Find Subword Under"] = "<C-d>",
      ["Add Cursor Up"]      = "<C-Up>",
      ["Add Cursor Down"]    = "<C-Down>",
      ["Select All"]         = "<C-M-d>",
      ["Skip Region"]        = "<C-x>",
    }
    vim.g.VM_theme = "iceblue"
  end,
}
