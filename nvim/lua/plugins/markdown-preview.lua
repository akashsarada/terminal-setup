-- Plugin: markdown-preview.nvim
-- Description: Zero-dependency live markdown preview in default browser with first-class interactive Mermaid diagrams and LaTeX support.
-- Keybinds: <leader>mp (Preview), <leader>ms (Stop preview), <leader>mr (Refresh preview)

return {
  "selimacerbas/markdown-preview.nvim",
  dependencies = { "selimacerbas/live-server.nvim" },
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewRefresh" },
  ft = { "markdown", "mermaid" },
  keys = {
    {
      "<leader>mp",
      "<cmd>MarkdownPreview<cr>",
      desc = "Markdown: Live Preview (Mermaid/Math)",
      ft = "markdown",
    },
    {
      "<leader>ms",
      "<cmd>MarkdownPreviewStop<cr>",
      desc = "Markdown: Stop Preview",
      ft = "markdown",
    },
    {
      "<leader>mr",
      "<cmd>MarkdownPreviewRefresh<cr>",
      desc = "Markdown: Refresh Preview",
      ft = "markdown",
    },
  },
  opts = {
    instance_mode = "takeover",
    port = 0,
    open_browser = true,
    default_theme = "dark",
    debounce_ms = 300,
    browser = vim.fn.has("wsl") == 1 and { "cmd.exe", "/c", "start", '""' } or nil,
  },
  config = function(_, opts)
    require("markdown_preview").setup(opts)
  end,
}
