-- Plugin: alpha-nvim
-- Description: Fast and fully customizable greeter (dashboard) for Neovim.
-- Features: Dynamic time-based greetings, custom ASCII art, and quick-access buttons.
-- Keybinds: Triggered automatically on empty startup or :Alpha.

return {
	"goolord/alpha-nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},

	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		_Gopts = {
			position = "center",
			hl = "Type",
			wrap = "overflow",
		}

		-- DASHBOARD HEADER
		local function getGreeting(name)
			local tableTime = os.date("*t")
			local datetime = os.date(" %Y-%m-%d-%A   %H:%M:%S ")
			local hour = tableTime.hour
			local greetingsTable = {
				[1] = "  Sleep well",
				[2] = "  Good morning",
				[3] = "  Good afternoon",
				[4] = "  Good evening",
				[5] = "�  Good night",
			}
			local greetingIndex = 0
			if hour == 23 or hour < 7 then
				greetingIndex = 1
			elseif hour < 12 then
				greetingIndex = 2
			elseif hour >= 12 and hour < 18 then
				greetingIndex = 3
			elseif hour >= 18 and hour < 21 then
				greetingIndex = 4
			elseif hour >= 21 then
				greetingIndex = 5
			end
			return datetime .. "  " .. greetingsTable[greetingIndex] .. ", " .. name
		end

		dashboard.section.header.val = {
			[[                                                                       ]],
			[[                                                                       ]],
			[[                                                                       ]],
			[[                                                                       ]],
			[[                                                                     ]],
			[[       ████ ██████           █████      ██                     ]],
			[[      ███████████             █████                             ]],
			[[      █████████ ███████████████████ ███   ███████████   ]],
			[[     █████████  ███    █████████████ █████ ██████████████   ]],
			[[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
			[[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
			[[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
			[[                                                                       ]],
			[[                                                                       ]],
			[[                                                                       ]],
		}

		dashboard.section.buttons.val = {
			dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
			dashboard.button(
				"f",
				"  Find file",
				":cd $HOME | silent Telescope find_files hidden=true no_ignore=true <CR>"
			),
			dashboard.button("1", "  Find text", ":Telescope live_grep <CR>"),
			dashboard.button("2", "�  Recent files", ":Telescope oldfiles <CR>"),
			dashboard.button("3", "�  Update plugins", "<cmd>Lazy update<CR>"),
			dashboard.button("4", "  Settings", ":e $HOME/.config/nvim/lua/plugins<CR>"),
			dashboard.button("5", "  Projects", ":e $HOME/Documents/ <CR>"),
			dashboard.button("6", "�  Quit", "<cmd>qa<CR>"),
		}

		dashboard.section.footer.val = vim.split("\n\n" .. getGreeting("Chagu"), "\n")

		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyVimStarted",
			desc = "Add Alpha dashboard footer",
			once = true,
			callback = function()
				local stats = require("lazy").stats()
				local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
				dashboard.section.footer.val =
					--	{ " ", " ", " ", " Loaded " .. stats.count .. " plugins  in " .. ms .. " ms " }
					vim.split("\n\n" .. getGreeting("Chagu"), "\n")
				dashboard.section.header.opts.hl = "DashboardFooter"
				pcall(vim.cmd.AlphaRedraw)
			end,
		})

		dashboard.opts.opts.noautocmd = true
		alpha.setup(dashboard.opts)
	end,
}
