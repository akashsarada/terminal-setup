-- Plugin: telescope.nvim
-- Description: Highly extendable fuzzy finder over lists.
-- Features: Project search, live grep, and UI-select for LSP actions.

return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					path_display = { "smart" },
					preview = {
						treesitter = false,
						filetype_hook = function(filepath, bufnr, _)
							local ft = vim.filetype.match({ filename = filepath, buf = bufnr })
							if ft then
								vim.bo[bufnr].filetype = ft
								local lang = vim.treesitter.language.get_lang and
									vim.treesitter.language.get_lang(ft)
								if lang then
									pcall(vim.treesitter.start, bufnr, lang)
								end
							end
							return true
						end,
					},
				},
				pickers = {
					lsp_references = { trim_text = true, fname_width = 45 },
					lsp_definitions = { trim_text = true, fname_width = 45 },
					lsp_implementations = { trim_text = true, fname_width = 45 },
					live_grep = { trim_text = true },
					grep_string = { trim_text = true },
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			telescope.load_extension("ui-select")
		end,
	},
}
