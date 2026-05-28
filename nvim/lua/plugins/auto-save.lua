return {
  "okuuva/auto-save.nvim",
  config = function()
    require("auto-save").setup({
      debounce_delay = 135,
      condition = function(buf)
        -- 1. First, check if the buffer is still valid to avoid the "Invalid buffer id" error
        if not vim.api.nvim_buf_is_valid(buf) then
          return false
        end

        -- 2. Then perform your usual checks
        return vim.bo[buf].filetype ~= "" and vim.bo[buf].modifiable
      end,
    })
  end,
}
