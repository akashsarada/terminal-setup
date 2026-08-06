return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
        ensure_installed = { "cpp", "lua", "vim", "markdown", "markdown_inline", "python", "typescript", "javascript", "kotlin" },
        highlight = { enable = true },
        indent = { enable = true },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = { query = "@function.outer", desc = "outer function" },
                    ["if"] = { query = "@function.inner", desc = "inner function" },
                    ["ac"] = { query = "@class.outer",    desc = "outer class" },
                    ["ic"] = { query = "@class.inner",    desc = "inner class" },
                    ["aa"] = { query = "@parameter.outer", desc = "outer parameter" },
                    ["ia"] = { query = "@parameter.inner", desc = "inner parameter" },
                },
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]f"] = { query = "@function.outer", desc = "Next function" },
                    ["]c"] = { query = "@class.outer",    desc = "Next class" },
                },
                goto_prev_start = {
                    ["[f"] = { query = "@function.outer", desc = "Prev function" },
                    ["[c"] = { query = "@class.outer",    desc = "Prev class" },
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ["<leader>sa"] = "@parameter.inner",
                },
                swap_previous = {
                    ["<leader>sA"] = "@parameter.inner",
                },
            },
        },
    },
}
