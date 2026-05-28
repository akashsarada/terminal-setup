-- Plugins: Mason, Mason-LSPConfig, nvim-lspconfig
-- Description: Manages external tools and connects Neovim to Language Servers.
-- Languages: Lua, C++, Python, TypeScript, Verilog/SystemVerilog.
-- Keybinds: K (Hover), gd (Definition), gr (References), gi (Impl), <leader>rn (Rename).
return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "jay-babu/mason-nvim-dap.nvim",
        event = "VeryLazy",
        dependencies = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            handlers = {},
        },
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = {
            auto_install = true,
        },
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                            diagnostics = { globals = { "vim" } },
                            telemetry = { enable = false },
                            completion = { callSnippet = "Replace" },
                        },
                    },
                },
                ts_ls = {},
                pyright = {
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "standard",
                                autoImportCompletions = true,
                            },
                        },
                    },
                },
                svls = {},
                verible = {
                    cmd = { "verible-verilog-ls" },
                    filetypes = { "verilog", "systemverilog" },
                },
                clangd = {
                    on_attach = function(client, _)
                        client.server_capabilities.documentFormattingProvider = false
                        client.server_capabilities.documentRangeFormattingProvider = false
                        client.server_capabilities.documentOnTypeFormattingProvider = false
                    end,
                },
            }

            for server, config in pairs(servers) do
                config.capabilities = config.capabilities or capabilities
                vim.lsp.enable(server, config)
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    local tb = require("telescope.builtin")

                    vim.keymap.set("n", "K",          vim.lsp.buf.hover,          opts)
                    vim.keymap.set("n", "gd",          tb.lsp_definitions,         opts)
                    vim.keymap.set("n", "gr",          tb.lsp_references,          opts)
                    vim.keymap.set("n", "gi",          tb.lsp_implementations,     opts)
                    vim.keymap.set("n", "<leader>D",   tb.lsp_type_definitions,    opts)
                    vim.keymap.set("i", "<C-k>",       vim.lsp.buf.signature_help, opts)

                    -- Enable inlay hints if the server supports them
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.server_capabilities.inlayHintProvider then
                        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
                    end
                end,
            })
        end,
    },
}
