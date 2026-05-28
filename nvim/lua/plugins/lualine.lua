-- Plugin: lualine.nvim
-- Updated to use vim.lsp.get_clients() (Neovim 0.10+ standard)

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("lualine").setup({
            options = {
                theme = "auto",
                section_separators = { left = "", right = "" },
                component_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { 
                    "branch", 
                    {
                        "diagnostics",
                        sources = { "nvim_lsp" },
                        -- SYMBOLS: Modern Nerd Font icons
                        symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
                        colored = true,
                    }
                },
                lualine_c = { { "filename", path = 1 } }, -- Shows parent dir for better context
                lualine_x = { 
                    {
                        function()
                            -- Get clients attached to the current buffer
                            local clients = vim.lsp.get_clients({ bufnr = 0 })
                            if #clients == 0 then
                                return "No LSP"
                            end
                            
                            -- Gather names of all active clients
                            local names = {}
                            for _, client in ipairs(clients) do
                                table.insert(names, client.name)
                            end
                            return " " .. table.concat(names, "|")
                        end,
                        color = { fg = "#ffffff", gui = "bold" },
                    },
                    "encoding", 
                    "filetype" 
                },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        })
    end,
}
