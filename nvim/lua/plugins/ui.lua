-- Plugin: EdenEast/nightfox.nvim
-- Description: Color scheme matching tmux (muted blue/purple).
-- Config: nordfox (arctic blue-grey), transparent bg, tmux blue accent override.

return {
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("nightfox").setup({
				options = {
					transparent = true,
				},
				groups = {
					all = {
						-- Match tmux primary (colour81 = #5fd7ff)
						CursorLineNr = { fg = "#5fd7ff", style = "bold" },
						Title = { fg = "#5fd7ff", style = "bold" },
						-- Keep gutter transparent
						LineNr = { bg = "NONE" },
						SignColumn = { bg = "NONE" },
					},
				},
			})
			vim.cmd.colorscheme("nordfox")
		end,
	},
}
