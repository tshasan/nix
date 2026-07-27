return {
  -- Disable diffview.nvim (LazyVim default)
  { "sindrets/diffview.nvim", enabled = false },

  -- Replace with codediff.nvim
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff" },
      { "<leader>gh", "<cmd>CodeDiff HEAD~1<cr>", desc = "CodeDiff HEAD~1" },
    },
  },
}
