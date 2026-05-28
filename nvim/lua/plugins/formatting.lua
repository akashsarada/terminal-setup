-- Plugin: conform.nvim
-- Description: Modern formatting engine.
-- Note: Manual formatting via <leader>f (configured in keymaps.lua)

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("conform").setup({
			-- 1. Map filetypes to formatters
			formatters_by_ft = {
				lua = { "stylua" },
				cpp = { "clang-format" },
				c = { "clang-format" },
				verilog = { "verible" },
				systemverilog = { "verible" },
			},

			-- 2. Customize specific formatter settings
			formatters = {
				["clang-format"] = {
					prepend_args = { "--style=file", "--fallback-style=Google" },
				},
				verible = {
					command = "verible-verilog-format",
					args = { "-" }, -- Use stdin for better undo history
					stdin = true,
				},
			},

			-- 3. We leave 'format_on_save' out entirely to avoid conflicts with auto-save
		})
	end,
}
