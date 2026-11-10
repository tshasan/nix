return {
  -- Yazi in a float. Opening a file there opens it in this Neovim;
  -- <c-v>/<c-x>/<c-t> open it in a split or tab, <tab> jumps between open buffers.
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    dependencies = { { "nvim-lua/plenary.nvim", lazy = true } },
    keys = {
      { "<leader>y", "<cmd>Yazi<cr>", mode = { "n", "v" }, desc = "Yazi (Current File)" },
      { "<leader>Y", "<cmd>Yazi cwd<cr>", desc = "Yazi (cwd)" },
    },
    opts = {
      keymaps = { show_help = "<f1>" },
    },
  },

  -- Number the buffers in the bufferline and jump straight to one with <leader>1-9.
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = { numbers = "ordinal" },
    },
    keys = function(_, keys)
      for i = 1, 9 do
        table.insert(keys, { "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", desc = "Buffer " .. i })
      end
      table.insert(keys, { "<leader>0", "<cmd>BufferLineGoToBuffer -1<cr>", desc = "Last Buffer" })
    end,
  },
}
