for command, method in pairs({
  WorkspaceAdd = "add",
  WorkspaceList = "list",
  WorkspaceDelete = "delete",
}) do
  vim.api.nvim_create_user_command(command, function()
    require("workspaces")[method]()
  end, {})
end
