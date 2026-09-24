-- Plugin: nvim-dap
-- Description: Debug Adapter Protocol client for Neovim.
-- Dependency: codelldb (installed via Mason), nvim-dap-ui, nvim-nio.
-- Keybinds: <leader>dt (Toggle Breakpoint), <leader>dc (Continue), <leader>ds (Step Over).


return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
	},

	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		local mason_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/"
		local extension_path = vim.fn.isdirectory(mason_path .. "extension/extension") == 1
			and (mason_path .. "extension/extension/")
			or (mason_path .. "extension/")

		local is_win = vim.fn.has("win32") == 1
		local is_mac = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
		local codelldb_path = extension_path .. "adapter/codelldb" .. (is_win and ".exe" or "")
		local lib_ext = is_mac and ".dylib" or (is_win and ".dll" or ".so")
		local liblldb_path = extension_path .. "lldb/lib/liblldb" .. lib_ext

		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = codelldb_path,
				args = { "--liblldb", liblldb_path, "--port", "${port}" },
			},
		}

		-- Debug configurations
		dap.configurations.cpp = {
			{
				name = "Launch file",
				type = "codelldb",
				request = "launch",
				program = function()
					local cmake = require("cmake-tools")
					local launch_target = cmake.get_launch_target()
					if launch_target then
						return launch_target
					end
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
			{
				name = "Launch file (with arguments)",
				type = "codelldb",
				request = "launch",
				program = function()
					local cmake = require("cmake-tools")
					local launch_target = cmake.get_launch_target()
					if launch_target then
						return launch_target
					end
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				args = function()
					local input = vim.fn.input("Program arguments: ")
					return vim.split(input, "%s+", { trimempty = true })
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
		dap.configurations.c = dap.configurations.cpp

		-- Setup dapui
		require("dapui").setup()

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		-- Keybindings
	end,
}
