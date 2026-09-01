return {
  {
    dir = vim.fn.stdpath("config") .. "/custom-plugins/worktrees.nvim",
    name = "worktrees.nvim",
    dependencies = {
      "ibhagwan/fzf-lua",
      {
        dir = vim.fn.stdpath("config") .. "/custom-plugins/workspace-session.nvim",
        name = "workspace-session.nvim",
      },
    },
    cmd = { "WorktreeCreate", "WorktreeList", "WorktreeMerge" },
    opts = {
      propagate = {
        paths = { ".env*", ".venv" },
        mode = "copy",
      },
    },
    keys = {
      { "<leader>wc", function() require("worktrees").create() end, desc = "Create worktree" },
      { "<leader>wl", function() require("worktrees").list() end, desc = "List worktrees" },
      { "<leader>wm", function() require("worktrees").merge() end, desc = "Merge worktree" },
    },
  },
}
