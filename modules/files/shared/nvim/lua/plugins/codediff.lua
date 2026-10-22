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
              vim.wo[win].winbar = " ]h next change  [h prev  ? help  q quit"
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
        -- ]h / [h walk every change in every file, so there's no separate file step
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
        view = {
          show_help = "?",
          -- Match LazyVim's gitsigns keys so hunks work the same in and out of a review
          next_hunk = "]h",
          prev_hunk = "[h",
          stage_hunk = "<leader>ghs",
          unstage_hunk = "<leader>ghu",
          discard_hunk = "<leader>ghr",
          -- <leader>e toggles the sidebar like LazyVim's explorer; leave <leader>b, t and gc alone
          toggle_explorer = "<leader>e",
          focus_explorer = false,
          toggle_layout = "<leader>rl",
          toggle_compact = "<leader>rz",
        },
      },
    },
  },

  -- gitsigns re-maps ]h / [h when a review opens a new file, so hand off to codediff there
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local on_attach = opts.on_attach
      opts.on_attach = function(buffer)
        on_attach(buffer)
        for key, dir in pairs({ ["]h"] = "next", ["[h"] = "prev" }) do
          vim.keymap.set("n", key, function()
            if package.loaded.codediff and require("codediff")[dir .. "_hunk"]() then
              return
            end
            if vim.wo.diff then
              vim.cmd.normal({ dir == "next" and "]c" or "[c", bang = true })
            else
              require("gitsigns").nav_hunk(dir)
            end
          end, { buffer = buffer, silent = true, desc = dir == "next" and "Next Hunk" or "Prev Hunk" })
        end
      end
    end,
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
