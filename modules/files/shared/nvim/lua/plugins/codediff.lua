return {
  -- Disable diffview.nvim (LazyVim default)
  { "sindrets/diffview.nvim", enabled = false },

  -- Replace with codediff.nvim
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    init = function()
      -- Keep the review keys on screen above the file list
      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffOpen",
        callback = function(args)
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(args.data.tabpage)) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "codediff-explorer" then
              vim.wo[win].winbar = " ]c next change  [c prev  ? help  q quit"
            end
          end
        end,
      })
    end,
    keys = {
      { "<leader>rd", "<cmd>CodeDiff<cr>", desc = "Uncommitted changes (Claude's edits)" },
      { "<leader>rc", "<cmd>CodeDiff HEAD~1 HEAD<cr>", desc = "Last commit" },
      { "<leader>rm", "<cmd>CodeDiff origin/main...<cr>", desc = "Branch vs origin/main (Phabricator patch)" },
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff" },
    },
    opts = {
      diff = {
        -- ]c / [c walk every change in every file, so there's no separate file step
        cycle_hunks_across_files = true,
        compute_moves = true,
        highlight_added_deleted_files = true,
      },
      explorer = {
        -- Start in the new code at the first change, not in the file list
        initial_focus = "modified",
        line_stats = { enabled = true },
      },
      keymaps = {
        view = { show_help = "?" },
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "review" },
      },
    },
  },
}
