local shared = {
  dir = vim.fn.stdpath("config") .. "/custom-plugins/workspace-session.nvim",
  name = "workspace-session.nvim",
}

return {
  {
    dir = vim.fn.stdpath("config") .. "/custom-plugins/workspaces.nvim",
    name = "workspaces.nvim",
    dependencies = { "ibhagwan/fzf-lua", shared },
    cmd = { "WorkspaceAdd", "WorkspaceList", "WorkspaceDelete" },
    keys = {
      { "<leader>wa", function() require("workspaces").add() end, desc = "Add workspace" },
      { "<leader>ww", function() require("workspaces").list() end, desc = "List workspaces" },
      { "<leader>wd", function() require("workspaces").delete() end, desc = "Delete workspace" },
    },
  },
}
