local map = vim.keymap.set

-- Neovim Local
map("i", "jk", "<Esc>", { noremap = true })
map("n", "<leader>r", "<C-r>", { desc = "Redo" })
map("v", "<leader>cc", "gc", { remap = true, desc = "Toggle Comment" })

-- Telescope / Neotree keybinds
map("n", "<leader>ff", function()
	local ok, manager = pcall(require, "neo-tree.sources.manager")
	local cwd = ok and manager.get_state("filesystem").path or vim.fn.getcwd()
	require("telescope.builtin").find_files({ cwd = cwd })
end, { desc = "Find file within Neo-tree root" })

map("n", "<leader>fb", ":Telescope buffers<CR>",            { desc = "Find buffer" })
map("n", "<leader>fg", ":Telescope live_grep<CR>",          { desc = "Live grep" })
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>",  { desc = "Document symbols" })
map("n", "<leader>fS", ":Telescope lsp_workspace_symbols<CR>", { desc = "Workspace symbols" })
map("n", "<C-h>", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
map("n", "<leader>.", ":vertical resize +5<CR>")
map("n", "<leader>+", ":vertical resize -5<CR>")

map("n", "<leader>;", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
		if bufname:match("neo%-tree filesystem") then
			vim.api.nvim_set_current_win(win)
			return
		end
	end
end, { desc = "Focus Neo-tree" })


map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)
map("n", "K", vim.lsp.buf.hover, {})
map("n", "<leader>gc", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= "" and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, false)
		end
	end
end, { desc = "Close floating windows" })

map({ "n", "v" }, "<leader>lf", function()
	require("conform").format({ lsp_fallback = true, timeout_ms = 500 })
end, { desc = "Format file or selection" })

-- Debugging (DAP)
map("n", "<Leader>dt", ":DapToggleBreakpoint<CR>", { desc = "Debug: Toggle Breakpoint" })
map("n", "<Leader>dc", ":DapContinue<CR>", { desc = "Debug: Start/Continue" })
map("n", "<Leader>dx", ":DapTerminate<CR>", { desc = "Debug: Terminate" })
map("n", "<Leader>ds", ":DapStepOver<CR>", { desc = "Debug: Step Over" })
map("n", "<Leader>di", ":DapStepInto<CR>", { desc = "Debug: Step Into" })
map("n", "<Leader>do", function()
	require("dapui").toggle()
end, { desc = "Debug: Toggle UI" })
map("n", "<Leader>dB", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Conditional Breakpoint" })

-- CMake Keymaps
map("n", "<leader>cg", ":CMakeGenerate<cr>", { desc = "CMake Generate" })
map("n", "<leader>cb", ":CMakeBuild<cr>", { desc = "CMake Build" })
map("n", "<leader>cr", ":CMakeRun<cr>", { desc = "CMake Run" })
map("n", "<leader>cd", ":CMakeDebug<cr>", { desc = "CMake Debug" })
map("n", "<leader>ct", ":CMakeSelectBuildType<cr>", { desc = "Select Build Type" })
map("n", "<leader>cx", ":CMakeStop<cr>", { desc = "Stop CMake Task" })



-- Indent Lines Keybinds
map("n", "<leader>n", ":IBLToggle<CR>", { desc = "Toggle Indent Lines" })

-- Cokeline (Buffer Navigation)
map("n", "<S-Tab>", "<Plug>(cokeline-focus-prev)", { silent = true, desc = "Prev Buffer" })
map("n", "<Tab>", "<Plug>(cokeline-focus-next)", { silent = true, desc = "Next Buffer" })

-- Direct jump to buffers 1-9
for i = 1, 9 do
	map(
		"n",
		("<F%s>"):format(i),
		("<Plug>(cokeline-focus-%s)"):format(i),
		{ silent = true, desc = "Focus Buffer " .. i }
	)
	map(
		"n",
		("<Leader>%s"):format(i),
		("<Plug>(cokeline-switch-%s)"):format(i),
		{ silent = true, desc = "Move Buffer to Pos " .. i }
	)
end


