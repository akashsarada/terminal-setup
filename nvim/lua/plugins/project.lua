-- Plugin: project.nvim
-- Description: Auto-detects project root (git/cmake/cargo/package.json), telescope integration.
-- Keybinds: <leader>fp (find projects)

return {
  "ahmedkhalf/project.nvim",
  event = "VeryLazy",
  config = function()
    require("project_nvim").setup({
      detection_methods = { "pattern", "lsp" },
      patterns = {
        ".git",
        "CMakeLists.txt",
        "Cargo.toml",
        "package.json",
        "pyproject.toml",
        ".python-version",
        "Makefile",
      },
      silent_chdir = true,
      scope_chdir = "global",
    })

    local ok, telescope = pcall(require, "telescope")
    if ok then
      telescope.load_extension("projects")
      vim.keymap.set("n", "<leader>fp", "<cmd>Telescope projects<cr>", { desc = "Find: Projects" })
    end
  end,
}
