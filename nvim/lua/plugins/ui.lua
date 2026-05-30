-- Plugin: kanagawa.nvim
-- Description: Color scheme matching tmux (blue/purple on black).
-- Config: Kanagawa-Dragon base with custom overrides for blue/purple accent.

return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				transparent = true,
				theme = "dragon",
				colors = {
					theme = {
						all = {
							ui = {
								bg_gutter = "none",
							},
						},
					},
				},
				overrides = function(colors)
					return {
						-- Match tmux primary (colour81 = #5fd7ff)
						CursorLineNr = { fg = "#5fd7ff", bold = true },
						Title = { fg = "#5fd7ff", bold = true },
						-- Match tmux secondary (colour141 = #af87ff)
						Statement = { fg = "#af87ff" },
						-- Keep gutter transparent
						LineNr = { bg = "none" },
						SignColumn = { bg = "none" },
					}
				end,
			})
			vim.cmd.colorscheme("kanagawa-dragon")
		end,
	},
}
