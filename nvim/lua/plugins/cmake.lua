return {
  {
    "Civitasv/cmake-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      cmake_command = "cmake",
      cmake_build_directory = "build/${variant:buildType}", -- Organizes builds by type
      cmake_build_type = "Debug",
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
      cmake_regenerate_on_save = false, -- Manual is often smoother
      cmake_statusline = { enabled = true }, -- Great for your Lualine/Bar
      cmake_executor = {
        name = "quickfix", -- Sends build errors directly to quickfix list
        opts = {
          show = "only_on_error", -- Keeps UI clean unless something breaks
        },
      },
      cmake_runner = {
        name = "terminal", -- Use Neovim terminal for execution output
      },
      cmake_notifications = {
        runner = { enabled = true },
        executor = { enabled = true },
      },
    }
  },
}
