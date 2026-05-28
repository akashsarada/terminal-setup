-- Plugin: nvim-cokeline
-- Description: A highly customizable bufferline that displays open files as tabs.
-- Features: Custom Powerline styling, "Pick" mode for jumping, and F-key focus.

return {
	"willothy/nvim-cokeline",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local get_hex = require("cokeline.hlgroups").get_hl_attr
		local is_picking_focus = require("cokeline/mappings").is_picking_focus
		local is_picking_close = require("cokeline/mappings").is_picking_close

		-- Colors fetched from your theme
		local colors = {
			red = vim.g.terminal_color_1,
			yellow = vim.g.terminal_color_4,
			dark = get_hex("Normal", "bg"),
			text = get_hex("Comment", "fg"),
			grey = get_hex("ColorColumn", "bg"),
			high = "#20fc03", -- Your signature green
		}

		require("cokeline").setup({
			default_hl = {
				fg = function(buffer)
					return buffer.is_focused and colors.dark or colors.text
				end,
				bg = function(buffer)
					return buffer.is_focused and colors.high or colors.grey
				end,
			},
			components = {
				{
					text = function(buffer)
						return buffer.index ~= 1 and "" or ""
					end,
					fg = colors.dark,
					bg = function(buffer)
						return buffer.is_focused and colors.high or colors.grey
					end,
				},
				{ text = " " },
				{
					text = function(buffer)
						if is_picking_focus() or is_picking_close() then
							return buffer.pick_letter .. " "
						end
						return buffer.devicon.icon
					end,
					fg = function(buffer)
						if is_picking_focus() then
							return colors.yellow
						end
						if is_picking_close() then
							return colors.red
						end
						return buffer.is_focused and colors.dark or colors.text
					end,
				},
				{
					text = function(buffer)
						return buffer.unique_prefix .. buffer.filename .. " "
					end,
					style = function(buffer)
						return buffer.is_focused and "bold" or nil
					end,
				},
				{
					text = "",
					fg = function(buffer)
						return buffer.is_focused and colors.high or colors.grey
					end,
					bg = colors.dark,
				},
			},
		})
	end,
}
