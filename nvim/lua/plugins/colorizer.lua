-- Plugin: nvim-colorizer.lua
-- Description: Inline hex/RGB/CSS color swatches rendered as background highlights.

return {
  "NvChad/nvim-colorizer.lua",
  event = "BufReadPost",
  config = function()
    require("colorizer").setup({
      filetypes = { "*", "!lazy", "!alpha" },
      user_default_options = {
        RGB      = true,
        RRGGBB   = true,
        names    = false,
        RRGGBBAA = true,
        css      = true,
        css_fn   = true,
        mode     = "background",
      },
    })
  end,
}
