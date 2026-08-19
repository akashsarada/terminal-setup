-- Plugins: Mason, Mason-LSPConfig, nvim-lspconfig
-- Description: Manages external tools and connects Neovim to Language Servers.
-- Languages: Lua, C++, Python, TypeScript, JSON, Kotlin, Verilog/SystemVerilog, Markdown (harper-ls grammar).
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
            ensure_installed = { "lua_ls", "ts_ls", "jsonls", "clangd", "harper-ls", "kotlin_language_server", "html", "cssls" },
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
                jsonls = {},
                cssls = {},
                html = {
                    filetypes = { "html", "htmldjango" },
                },
                htmx = {
                    filetypes = { "html", "htmldjango" },
                },
                kotlin_language_server = {
                    init_options = {
                        storagePath = vim.fn.stdpath("cache") .. "/kotlin-language-server",
                    },
                    handlers = {
                        ["textDocument/publishDiagnostics"] = function() end,
                    },
                },
                harper_ls = {
                    filetypes = { "markdown" },
                },
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
                vim.lsp.config(server, config)
                vim.lsp.enable(server)
            end

            local function smart_goto_definition()
                local tb = require("telescope.builtin")
                local ft = vim.bo.filetype
                local is_web = ft == "html" or ft == "htmldjango" or ft == "jinja" or ft == "javascriptreact" or ft == "typescriptreact"

                if is_web then
                    local cword = vim.fn.expand("<cword>")
                    local line = vim.api.nvim_get_current_line()
                    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
                    
                    -- Check if cursor is on/near a class or id attribute in HTML
                    local before_cursor = line:sub(1, col)
                    local is_class = before_cursor:match('class%s*=%s*["\'][^"\']*$') ~= nil
                    local is_id = before_cursor:match('id%s*=%s*["\'][^"\']*$') ~= nil

                    if is_class and cword ~= "" then
                        tb.grep_string({
                            search = "." .. cword,
                            prompt_title = "CSS Class Definition: ." .. cword,
                        })
                        return
                    elseif is_id and cword ~= "" then
                        tb.grep_string({
                            search = "#" .. cword,
                            prompt_title = "CSS ID Definition: #" .. cword,
                        })
                        return
                    end
                end

                -- Fallback to standard LSP definition
                tb.lsp_definitions()
            end

            local function smart_goto_references()
                local tb = require("telescope.builtin")
                local ft = vim.bo.filetype
                local is_css = ft == "css" or ft == "scss" or ft == "less" or ft == "sass"
                local is_html = ft == "html" or ft == "htmldjango" or ft == "jinja" or ft == "javascriptreact" or ft == "typescriptreact"

                if is_css or is_html then
                    local cword = vim.fn.expand("<cword>")
                    cword = cword:gsub("^[.#]", "")
                    if cword ~= "" then
                        tb.grep_string({
                            search = cword,
                            prompt_title = "Find CSS/HTML Usages: " .. cword,
                        })
                        return
                    end
                end

                -- Fallback to standard LSP references
                tb.lsp_references()
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    local tb = require("telescope.builtin")

                    vim.keymap.set("n", "K",          vim.lsp.buf.hover,          opts)
                    vim.keymap.set("n", "gd",         smart_goto_definition,      vim.tbl_extend("force", opts, { desc = "Go to Definition (LSP / CSS)" }))
                    vim.keymap.set("n", "<leader>gd", smart_goto_definition,      vim.tbl_extend("force", opts, { desc = "Go to Definition (LSP / CSS)" }))
                    vim.keymap.set("n", "gr",         smart_goto_references,      vim.tbl_extend("force", opts, { desc = "Find References / CSS Usages" }))
                    vim.keymap.set("n", "<leader>gr", smart_goto_references,      vim.tbl_extend("force", opts, { desc = "Find References / CSS Usages" }))
                    vim.keymap.set("n", "gi",         tb.lsp_implementations,     opts)
                    vim.keymap.set("n", "<leader>D",  tb.lsp_type_definitions,    opts)
                    vim.keymap.set("i", "<C-k>",      vim.lsp.buf.signature_help, opts)

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
