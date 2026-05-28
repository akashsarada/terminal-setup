-- Plugin: nvim-spectre
-- Description: Project-wide search & replace with regex preview (like IntelliJ "Replace in Files").
-- Keybinds: <leader>sr (open), <leader>sw (search word under cursor)

return {
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>sr", function() require("spectre").open() end,                          desc = "Spectre: Search & Replace" },
    { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, mode = { "n", "v" }, desc = "Spectre: Search Word" },
    { "<leader>sf", function() require("spectre").open_file_search() end,              desc = "Spectre: Search in File" },
  },
  config = function()
    require("spectre").setup({
      open_cmd = "vnew",
      replace_vim_cmd = "cfdo",
    })
  end,
}
