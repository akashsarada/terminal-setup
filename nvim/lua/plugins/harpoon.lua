-- Plugin: harpoon (v2)
-- Description: Per-project file bookmarks with instant jump. Mark files you
--              constantly switch between; jump to them with a single keymap.
-- Keybinds: <leader>ha (add), <leader>hh (menu), <leader>h1-4 (jump to mark)

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  lazy = false,
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    })

    -- Something (neo-tree follow_current_file / aerial / ufo) fires BufLeave on
    -- the harpoon buffer immediately after it opens, causing immediate close.
    -- Suppress no-arg close calls that happen within 300ms of opening.
    local orig_toggle = harpoon.ui.toggle_quick_menu
    local open_time = nil
    harpoon.ui.toggle_quick_menu = function(self, list, opts)
      if list ~= nil and self.win_id == nil then
        open_time = vim.uv.now()
      elseif list == nil and self.win_id ~= nil and open_time ~= nil then
        if (vim.uv.now() - open_time) < 300 then
          return
        end
        open_time = nil
      end
      return orig_toggle(self, list, opts)
    end

    local map = function(k, fn, desc)
      vim.keymap.set("n", k, fn, { desc = desc })
    end

    map("<leader>ha", function() harpoon:list():add() end,      "Harpoon: Add File")
    map("<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Harpoon: Menu")
    map("<leader>h1", function() harpoon:list():select(1) end,  "Harpoon: File 1")
    map("<leader>h2", function() harpoon:list():select(2) end,  "Harpoon: File 2")
    map("<leader>h3", function() harpoon:list():select(3) end,  "Harpoon: File 3")
    map("<leader>h4", function() harpoon:list():select(4) end,  "Harpoon: File 4")
    map("<leader>hp", function() harpoon:list():prev() end,     "Harpoon: Prev")
    map("<leader>hn", function() harpoon:list():next() end,     "Harpoon: Next")
  end,
}
