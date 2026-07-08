-- Plugin: Comment.nvim
-- Description: Smart and powerful comment plugin for Neovim.
-- Keybinds: 'gcc' (line), 'gbc' (block), 'gc' (visual selection)

return {
	"numToStr/Comment.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
	config = function()
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})
		require("Comment").setup({
			sticky = true,
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		})
	end,
}
