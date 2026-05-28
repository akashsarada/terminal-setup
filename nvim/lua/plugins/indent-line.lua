-- Plugin: indent-blankline.nvim (IBL)
-- Description: Adds vertical indentation guides to help track code blocks.
-- Keybinds: <leader>n (Toggle indent lines)

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {
    indent = { 
        char = "▏", 
        highlight = "IblIndent" -- Uses our grey color
    },
    scope = { 
        enabled = true,
        highlight = "IblScope", -- Uses our blue color
        show_start = false,
        show_end = false,
    },
  },
}
