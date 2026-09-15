return {
  "nosduco/remote-sshfs.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    connections = {
      ssh_configs = {
        vim.fn.expand("$HOME") .. "/.ssh/config",
      },
      sshfs_args = {
        "-o", "reconnect",
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
    require("remote-sshfs").setup(opts)
    require("telescope").load_extension("remote-sshfs")
  end,
}
