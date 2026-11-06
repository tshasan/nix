return {
  -- Use one browser preview for Markdown and HTML; keep render-markdown.nvim
  -- for rendering Markdown inside the editor.
  { "iamcco/markdown-preview.nvim", enabled = false },
  {
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    keys = {
      {
        "<leader>cp",
        "<cmd>LivePreview start<cr>",
        ft = { "markdown", "html" },
        desc = "Preview in Browser",
      },
      {
        "<leader>cP",
        "<cmd>LivePreview close<cr>",
        ft = { "markdown", "html" },
        desc = "Stop Browser Preview",
      },
    },
    -- Markdown updates as you type; HTML (including CSS/JS) updates on save.
    -- Serve from Neovim's working directory so project-relative assets resolve.
  },
}
