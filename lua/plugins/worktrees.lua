return {
  {
    dir = vim.fn.stdpath("config") .. "/custom-plugins/worktrees.nvim",
    name = "worktrees.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    cmd = { "WorktreeCreate", "WorktreeList", "WorktreeMerge" },
    keys = {
      { "<leader>wc", function() require("worktrees").create() end, desc = "Create worktree" },
      { "<leader>wl", function() require("worktrees").list() end, desc = "List worktrees" },
      { "<leader>wm", function() require("worktrees").merge() end, desc = "Merge worktree" },
    },
  },
}
