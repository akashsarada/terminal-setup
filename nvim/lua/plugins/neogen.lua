-- Plugin: neogen
-- Description: A better annotation generator. Supports Doxygen, JSDoc, PyDoc, etc.
-- Dependency: nvim-treesitter/nvim-treesitter
-- Keybinds: <leader>m (Generate annotation)
return {
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = {
      enabled = true,
      languages = {
        cpp = {
          template = {
            annotation_convention = "doxygen",
          },
        },
        c = {
          template = {
            annotation_convention = "doxygen",
          },
        },
      },
    },
    keys = {
      {
        "<leader>m",
        function()
          require("neogen").generate()
        end,
        desc = "Neogen: Generate Annotation",
      },
    },
  },
}
