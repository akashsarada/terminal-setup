-- Plugin: neotest
-- Description: Test runner with inline pass/fail, output panel, summary view.
-- Keybinds: <leader>tt (nearest), <leader>tf (file), <leader>ts (summary), <leader>to (output)

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-neotest/neotest-python",
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end,                       desc = "Test: Run Nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,     desc = "Test: Run File" },
    { "<leader>tT", function() require("neotest").run.run(vim.loop.cwd()) end,         desc = "Test: Run All" },
    { "<leader>ts", function() require("neotest").summary.toggle() end,                desc = "Test: Summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end,   desc = "Test: Output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end,           desc = "Test: Output Panel" },
    { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end,   desc = "Test: Debug Nearest" },
    { "]T", function() require("neotest").jump.next({ status = "failed" }) end,        desc = "Next failed test" },
    { "[T", function() require("neotest").jump.prev({ status = "failed" }) end,        desc = "Prev failed test" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({ dap = { justMyCode = false } }),
      },
      status = { virtual_text = true },
      output = { open_on_run = false },
      quickfix = { open = false },
    })
  end,
}
