-- Plugin: rainbow-delimiters.nvim
-- Description: Color-codes nested parentheses, brackets, and braces using Treesitter.
-- Benefit: Makes navigating nested C++/Verilog logic much easier.

return {
	"HiPhish/rainbow-delimiters.nvim",
	dependencies = "nvim-treesitter/nvim-treesitter",
	config = function()
		local rb = require("rainbow-delimiters")

		require("rainbow-delimiters.setup").setup({
			strategy = {
				-- 'Global' is the default, but we can use 'Local' for
				-- better performance in very large files.
				[""] = rb.strategy["global"],
				vim = rb.strategy["local"],
			},
			query = {
				[""] = "rainbow-delimiters",
				lua = "rainbow-blocks",
			},
			highlight = {
				"RainbowDelimiterRed",
				"RainbowDelimiterYellow",
				"RainbowDelimiterBlue",
				"RainbowDelimiterOrange",
				"RainbowDelimiterGreen",
				"RainbowDelimiterViolet",
				"RainbowDelimiterCyan",
			},
		})
	end,
}
