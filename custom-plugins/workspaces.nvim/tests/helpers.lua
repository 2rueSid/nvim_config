local M = {}

local original_cwd = vim.uv.cwd()

function M.reset_editor()
  pcall(vim.cmd, "silent! tabonly")
  pcall(vim.cmd, "silent! only")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  vim.cmd("enew")
  vim.cmd.cd(vim.fn.fnameescape(original_cwd))
end

function M.eq(expected, actual, message)
  assert(vim.deep_equal(expected, actual), message or vim.inspect({ expected = expected, actual = actual }))
end

function M.temp_dir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, "p")
  return vim.fs.normalize(path)
end

function M.cleanup(path)
  vim.fn.delete(path, "rf")
end

function M.git(cwd, args)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout or "")
end

function M.temp_repo()
  local root = M.temp_dir()
  local init = vim.system({ "git", "init", "-b", "main", root }, { text = true }):wait()
  assert(init.code == 0, init.stderr)
  M.git(root, { "config", "user.email", "workspace-tests@example.com" })
  M.git(root, { "config", "user.name", "Workspace Tests" })
  vim.fn.writefile({ "base" }, root .. "/base.txt")
  M.git(root, { "add", "base.txt" })
  M.git(root, { "commit", "-m", "base" })
  return root
end

return M
