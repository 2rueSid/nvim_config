local M = {}

function M.eq(expected, actual, message)
  assert(vim.deep_equal(expected, actual), message or vim.inspect({ expected = expected, actual = actual }))
end

function M.git(cwd, args)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout or "")
end

function M.temp_repo()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local init = vim.system({ "git", "init", "-b", "main", root }, { text = true }):wait()
  assert(init.code == 0, init.stderr)
  M.git(root, { "config", "user.email", "tests@example.com" })
  M.git(root, { "config", "user.name", "Worktree Tests" })
  vim.fn.writefile({ "base" }, root .. "/base.txt")
  M.git(root, { "add", "base.txt" })
  M.git(root, { "commit", "-m", "base" })
  return root
end

function M.cleanup(path)
  vim.fn.delete(path, "rf")
end

return M
