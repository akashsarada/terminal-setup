-- Plugin: Comment.nvim
-- Description: Smart and powerful comment plugin for Neovim.
-- Keybinds: 'gcc' (line), 'gbc' (block), 'gc' (visual selection)

return {
	"numToStr/Comment.nvim",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		-- Module name MUST be lowercase
		require("Comment").setup({
			sticky = true,
		})
	end,
}
