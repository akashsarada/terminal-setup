-- Plugin: kanagawa.nvim & doom-one.nvim
-- Description: Aesthetic color schemes for Neovim.
-- Config: Using Kanagawa-Dragon with native transparency enabled.

return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false, -- Themes should load immediately
		priority = 1000, -- Load this before everything else
		config = function()
			require("kanagawa").setup({
				transparent = true, -- Cleaner than manual 'guibg=none'
				theme = "dragon", -- Options: wave, dragon, lotus
				overrides = function(colors)
					return {
						-- Ensures the gutter (line numbers) is also transparent
						LineNr = { bg = "none" },
						SignColumn = { bg = "none" },
					}
				end,
			})
			vim.cmd.colorscheme("kanagawa-dragon")
		end,
	},

	{ "NTBBloodbath/doom-one.nvim" }, -- Kept as a backup
}
