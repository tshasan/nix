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
        function()
          -- Files outside the cwd can't be served from it (the URL becomes
          -- /nil and 404s), so serve those from their own directory.
          local file = vim.api.nvim_buf_get_name(0)
          require("livepreview.config").config.dynamic_root = vim.fs.relpath(vim.fn.getcwd(), file) == nil
          vim.cmd("LivePreview start")
        end,
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
