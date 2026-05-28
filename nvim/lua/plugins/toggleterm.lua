-- Plugin: toggleterm.nvim
-- Description: Persistent terminal management + lazygit floating integration.
-- Keybinds: <leader>gg (lazygit), <leader>t` (float), <leader>th (horizontal), <leader>tv (vertical)

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<leader>t`", "<cmd>ToggleTerm direction=float<cr>",              desc = "Terminal: Float" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>",         desc = "Terminal: Horizontal" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=70<cr>",   desc = "Terminal: Vertical" },
    {
      "<leader>gg",
      function()
        local Terminal = require("toggleterm.terminal").Terminal
        local lazygit = Terminal:new({
          cmd = "lazygit",
          hidden = true,
          direction = "float",
          float_opts = { border = "curved" },
          on_open = function(term)
            vim.keymap.set("t", "q", function() term:toggle() end, { buffer = term.bufnr, silent = true })
          end,
        })
        lazygit:toggle()
      end,
      desc = "LazyGit",
    },
  },
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then return 15
        elseif term.direction == "vertical" then return vim.o.columns * 0.4
        end
      end,
      float_opts = { border = "curved" },
      shell = vim.o.shell,
    })

    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*toggleterm#*",
      callback = function()
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = 0 })
        vim.keymap.set("t", "jk",   [[<C-\><C-n>]], { buffer = 0 })
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { buffer = 0 })
        vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { buffer = 0 })
      end,
    })
  end,
}
