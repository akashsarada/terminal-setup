-- Plugin: lualine.nvim
-- Description: Status bar themed to match tmux (blue/purple).

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local custom_theme = {
            normal = {
                a = { fg = "#000000", bg = "#5fd7ff", gui = "bold" },
                b = { fg = "#5fd7ff", bg = "#1a1a2e" },
                c = { fg = "#a0a0a0", bg = "none" },
            },
            insert = {
                a = { fg = "#000000", bg = "#af87ff", gui = "bold" },
                b = { fg = "#af87ff", bg = "#1a1a2e" },
            },
            visual = {
                a = { fg = "#000000", bg = "#ff87af", gui = "bold" },
                b = { fg = "#ff87af", bg = "#1a1a2e" },
            },
            command = {
                a = { fg = "#000000", bg = "#5fd7ff", gui = "bold" },
                b = { fg = "#5fd7ff", bg = "#1a1a2e" },
            },
            inactive = {
                a = { fg = "#af87ff", bg = "#1a1a2e" },
                c = { fg = "#606060", bg = "none" },
            },
        }

        require("lualine").setup({
            options = {
                theme = custom_theme,
                section_separators = { left = "", right = "" },
                component_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {
                    "branch",
                    {
                        "diagnostics",
                        sources = { "nvim_lsp" },
                        symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
                        colored = true,
                    }
                },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = {
                    {
                        function()
                            local clients = vim.lsp.get_clients({ bufnr = 0 })
                            if #clients == 0 then return "No LSP" end
                            local names = {}
                            for _, client in ipairs(clients) do
                                table.insert(names, client.name)
                            end
                            return " " .. table.concat(names, "|")
                        end,
                        color = { fg = "#5fd7ff", gui = "bold" },
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
