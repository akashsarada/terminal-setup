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

		-- Paths to codelldb components installed by Mason
		local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
		local codelldb_path = extension_path .. "adapter/codelldb"
		local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"

		-- Setup codelldb adapter
		dap.adapters.codelldb = function(on_adapter)
			vim.fn.jobstart({ codelldb_path, "--liblldb", liblldb_path, "--port", "0" }, {
				stdout_buffered = true,
				on_stdout = function(_, data)
					for _, line in ipairs(data) do
						local port = line:match("Listening on port (%d+)")
						if port then
							on_adapter({
								type = "server",
								host = "127.0.0.1",
								port = tonumber(port)
							})
							break
						end
					end
				end,
			})
		end

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
