return {
  "nosduco/remote-sshfs.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    connections = {
      ssh_configs = {
        vim.fn.expand("$HOME") .. "/.ssh/config",
      },
      sshfs_args = {
        "-o", "ConnectTimeout=5",
      },
    },
    mounts = {
      base_dir = vim.fn.expand("$HOME") .. "/.sshfs/",
      unmount_on_exit = true,
    },
    handlers = {
      on_connect = {
        change_dir = true,
      },
      on_disconnect = {
        clean_mount_folders = true,
      },
    },
    ui = {
      select_prompts = false,
      confirm = {
        connect = true,
        change_dir = false,
      },
    },
  },
  config = function(_, opts)
    local connections = require("remote-sshfs.connections")
    local handler = require("remote-sshfs.handler")
    local orig_wrapper = handler.sshfs_wrapper
    local orig_connect = connections.connect

    local password_prompted = {}
    local cancelled = false

    connections.connect = function(host)
      cancelled = false
      local hostname = host and (host["Name"] or host["HostName"])
      if hostname then
        password_prompted[hostname] = nil
      end
      orig_connect(host)
    end

    local orig_inputsecret = vim.fn.inputsecret
    vim.fn.inputsecret = function(_)
      local host = connections.get_current_host()
      local hostname = host and (host["Name"] or host["HostName"]) or "host"
      local res = orig_inputsecret("Enter password for " .. hostname .. " (<Esc> to cancel): ")
      if not res or res == "" then
        cancelled = true
        password_prompted[hostname] = nil
        vim.schedule(function()
          connections.unmount_host()
          vim.notify("Connection to " .. hostname .. " cancelled.", vim.log.levels.WARN)
        end)
        return ""
      end
      return res
    end

    handler.sshfs_wrapper = function(data, host, mount_dir, callback)
      if cancelled then
        return
      end

      local output = table.concat(data, "\n")
      if output == "" or string.match(output, "read:") or string.match(output, "Interrupted system call") then
        return
      end

      local hostname = host and (host["Name"] or host["HostName"]) or "host"

      if string.match(output, "Permission denied") or string.match(output, "password:") or string.match(output, "ssh_askpass") then
        if not password_prompted[hostname] then
          password_prompted[hostname] = true
          vim.schedule(function()
            handler.askpass_handler(callback)
          end)
          return
        else
          password_prompted[hostname] = nil
          cancelled = true
          vim.schedule(function()
            connections.unmount_host()
            vim.notify("Authentication failed for " .. hostname .. ": incorrect password or key rejected.", vim.log.levels.ERROR)
          end)
          return
        end
      end

      if string.match(output, "Authenticated") then
        password_prompted[hostname] = nil
      end

      orig_wrapper(data, host, mount_dir, callback)
    end

    require("remote-sshfs").setup(opts)
    require("telescope").load_extension("remote-sshfs")
  end,
}
