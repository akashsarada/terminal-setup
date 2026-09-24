-- Plugin: jupynvim
-- Description: Jupyter notebooks in Neovim with visual cell blocks, inline images, and kernel-backed completion.
-- Keybinds: <leader>nr (Run cell), <leader>nb (Add code cell below), <leader>nm (To markdown), <leader>nK (Kernel picker)

return {
  "sheng-tse/jupynvim",
  build = function(plugin)
    local install = loadfile(plugin.dir .. "/lua/jupynvim/install.lua")()
    install.run(plugin)
  end,
  opts = {
    log_level = "info",
    image_renderer = "placeholder",
  },
  config = function(_, opts)
    require("jupynvim").setup(opts)
  end,
}
