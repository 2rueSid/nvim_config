for command, method in pairs({
  WorktreeCreate = "create",
  WorktreeList = "list",
  WorktreeMerge = "merge",
}) do
  vim.api.nvim_create_user_command(command, function()
    require("worktrees")[method]()
  end, {})
end
