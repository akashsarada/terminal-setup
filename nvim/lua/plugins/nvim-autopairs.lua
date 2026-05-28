-- Plugin: nvim-autopairs
-- Description: Automatically closes brackets, quotes, and parenthesis.
-- Integration: Configured to work with nvim-cmp for function completion.

return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		local autopairs = require("nvim-autopairs")

		autopairs.setup({
			check_ts = true, -- Enable Treesitter integration
			ts_config = {
				lua = { "string" }, -- Don't add pairs in lua string nodes
				javascript = { "template_string" },
			},
		})

		-- If you use nvim-cmp, this part is crucial:
		-- It adds brackets automatically after you select a function or method
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}
