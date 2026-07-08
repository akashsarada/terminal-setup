-- Plugin: neo-tree.nvim
-- Description: Next-generation file explorer for Neovim.
-- Config: Filters CMake/Build artifacts, follows current file, width 50.
-- Keybinds: <C-h> (Toggle), <leader>ff (Find in current tree root).

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			window = {
				width = 50,
				height = 30,
				mappings = {
					["<BS>"] = "noop",
					["o"] = "open",
					["<CR>"] = "open",
					["a"] = "add",
					["d"] = "delete",
					["r"] = "rename",
					["-"] = "close_node",
				},
			},
			filesystem = {
				bind_to_cwd = false,
				use_libuv_file_watcher = true,
				follow_current_file = {
					enabled = true,
					leave_dirs_open = true,
				},
				filtered_items = {
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_by_name = {
						".DS_Store",
						"thumbs.db",
						".version482",
						".clang-format",
						"cmake_install.cmake",
						"CMakeCache.txt",
						"cmake-build-debug/",
						"CMakeFiles",
						"build/",
						".idea",
						".cache",
						"compile_commands.json",
						".git",
					},
					never_show = {},
					hide_by_pattern = {
						"*.a",
						"*.o",
						"*.dSYM",
						".ninja*",
					},
				},
			},
			buffers = {
				follow_current_file = {
					enabled = true,
				},
				group_empty_dirs = true,
				show_unloaded = true,
			},
			git_status = {
				show_ignored = false,
				show_untracked = true,
				symbols = {
            added     = "✚",
            modified  = "",
            deleted   = "✖",
            renamed   = "󰁕",
            untracked = "",
            ignored   = "",
            unstaged  = "󰄱",
            staged    = "",
            conflict  = "",
        }
			},
		})
	end,
}
