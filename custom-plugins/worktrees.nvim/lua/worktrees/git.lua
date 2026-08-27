local M = {}

local function normalize(result)
  return {
    ok = result.code == 0,
    code = result.code,
    stdout = result.stdout or "",
    stderr = vim.trim(result.stderr or ""),
  }
end

local function command(args, opts)
  local cmd = { "git" }
  if opts and opts.cwd then
    vim.list_extend(cmd, { "-C", opts.cwd })
  end
  vim.list_extend(cmd, args)
  return cmd
end

function M.run(args, opts)
  return normalize(vim.system(command(args, opts), { text = true }):wait())
end

function M.run_async(args, opts, callback)
  vim.system(command(args, opts), { text = true }, function(result)
    vim.schedule(function()
      callback(normalize(result))
    end)
  end)
end

function M.parse_worktrees(stdout)
  local worktrees, current = {}, nil
  for line in (stdout .. "\n"):gmatch("([^\n]*)\n") do
    if line == "" then
      if current then
        table.insert(worktrees, current)
        current = nil
      end
    else
      local key, value = line:match("^(%S+)%s*(.*)$")
      if key == "worktree" then
        current = { path = vim.fs.normalize(value), detached = false }
      elseif current and key == "HEAD" then
        current.head = value
      elseif current and key == "branch" then
        current.branch = value:gsub("^refs/heads/", "")
      elseif current and key == "detached" then
        current.detached = true
      elseif current and key == "locked" then
        current.locked = value ~= "" and value or true
      elseif current and key == "prunable" then
        current.prunable = value ~= "" and value or true
      end
    end
  end
  return worktrees
end

function M.parse_status(stdout)
  local status = { staged = 0, unstaged = 0, untracked = 0, conflicted = 0, ahead = nil, behind = nil }
  for line in stdout:gmatch("[^\n]+") do
    local ahead, behind = line:match("^# branch%.ab %+(%d+) %-(%d+)$")
    if ahead then
      status.ahead, status.behind = tonumber(ahead), tonumber(behind)
    elseif line:sub(1, 2) == "? " then
      status.untracked = status.untracked + 1
    elseif line:sub(1, 2) == "u " then
      status.conflicted = status.conflicted + 1
    elseif line:sub(1, 2) == "1 " or line:sub(1, 2) == "2 " then
      local xy = line:match("^[12] (%S%S)")
      if xy and xy:sub(1, 1) ~= "." then status.staged = status.staged + 1 end
      if xy and xy:sub(2, 2) ~= "." then status.unstaged = status.unstaged + 1 end
    end
  end
  return status
end

function M.is_clean(status)
  return status.staged == 0 and status.unstaged == 0 and status.untracked == 0 and status.conflicted == 0
end

local function canonical(path)
  path = vim.trim(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or path)
end

local function display_root(cwd, root)
  local cwd_path = vim.fs.normalize(vim.fn.fnamemodify(cwd, ":p"))
  local cwd_canonical, root_canonical = canonical(cwd_path), canonical(root)
  local prefix = root_canonical .. "/"
  if cwd_canonical == root_canonical then return cwd_path end
  if cwd_canonical:sub(1, #prefix) ~= prefix then return vim.fs.normalize(root) end
  local relative = cwd_canonical:sub(#prefix + 1)
  local result = cwd_path
  for _ in relative:gmatch("[^/]+") do
    result = vim.fs.dirname(result)
  end
  return result
end

local function failure(result)
  return result.stderr ~= "" and result.stderr or "git command failed"
end

local function worktree_registry(cwd)
  local result = M.run({ "worktree", "list", "--porcelain" }, { cwd = cwd })
  if not result.ok then return nil, failure(result) end
  return M.parse_worktrees(result.stdout)
end

function M.repository(cwd)
  local current = M.run({ "rev-parse", "--show-toplevel" }, { cwd = cwd })
  if not current.ok then return nil, failure(current) end
  local common = M.run({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, { cwd = cwd })
  if not common.ok then return nil, failure(common) end
  local worktrees, err = worktree_registry(cwd)
  if not worktrees then return nil, err end
  local main = worktrees[1]
  if not main then return nil, "bare repositories are not supported" end

  local main_root = display_root(cwd, main.path)
  local common_dir = canonical(common.stdout)
  if common_dir ~= canonical(vim.fs.joinpath(main_root, ".git")) then
    return nil, "bare repositories are not supported"
  end

  local current_root = canonical(current.stdout)
  for _, worktree in ipairs(worktrees) do
    if canonical(worktree.path) == current_root then
      return {
        current_root = display_root(cwd, current.stdout),
        main_root = main_root,
        common_dir = vim.fs.joinpath(main_root, ".git"),
        worktrees = worktrees,
      }
    end
  end
  return nil, "current worktree is not registered"
end

local status_args = { "status", "--porcelain=v2", "--branch", "--untracked-files=all" }

function M.status(path)
  local result = M.run(status_args, { cwd = path })
  if not result.ok then return nil, failure(result) end
  return M.parse_status(result.stdout)
end

function M.status_async(path, callback)
  M.run_async(status_args, { cwd = path }, function(result)
    if not result.ok then
      callback(nil, result.stderr)
      return
    end
    callback(M.parse_status(result.stdout), nil)
  end)
end

function M.merge(repo, source)
  if canonical(source.path) == canonical(repo.main_root) then
    return { ok = false, aborted = false, error = "cannot merge the main worktree" }
  end
  if source.detached or not source.branch then
    return { ok = false, aborted = false, error = "source worktree is detached" }
  end

  local target = M.run({ "symbolic-ref", "--quiet", "--short", "HEAD" }, { cwd = repo.main_root })
  if not target.ok then
    return { ok = false, aborted = false, error = "main worktree is detached" }
  end
  local target_branch = vim.trim(target.stdout)
  if source.branch == target_branch then
    return { ok = false, aborted = false, error = "source and target branches must differ" }
  end

  local source_status, source_error = M.status(source.path)
  if not source_status then
    return { ok = false, aborted = false, error = "cannot read source worktree status: " .. source_error }
  end
  if not M.is_clean(source_status) then
    return { ok = false, aborted = false, error = "source worktree must be clean" }
  end
  local main_status, main_error = M.status(repo.main_root)
  if not main_status then
    return { ok = false, aborted = false, error = "cannot read main worktree status: " .. main_error }
  end
  if not M.is_clean(main_status) then
    return { ok = false, aborted = false, error = "main worktree must be clean" }
  end

  local result = M.run({ "merge", source.branch }, { cwd = repo.main_root })
  if result.ok then return { ok = true, aborted = false } end

  local merge_head = M.run({ "rev-parse", "-q", "--verify", "MERGE_HEAD" }, { cwd = repo.main_root })
  if not merge_head.ok then
    return { ok = false, aborted = false, error = result.stderr }
  end

  local abort = M.run({ "merge", "--abort" }, { cwd = repo.main_root })
  if abort.ok then
    return { ok = false, aborted = true, error = result.stderr }
  end
  return {
    ok = false,
    aborted = false,
    error = result.stderr,
    abort_error = string.format("%s (manual recovery required at %s)", failure(abort), repo.main_root),
  }
end

function M.validate_name(repo, name)
  if type(name) ~= "string" or vim.trim(name) == "" then
    return false, "worktree name is required"
  end
  if name:find("/", 1, true) or name:find("\\", 1, true) then
    return false, "worktree name cannot contain path separators"
  end
  local ref = M.run({ "check-ref-format", "--branch", name }, { cwd = repo.main_root })
  if not ref.ok then return false, "invalid Git branch name: " .. name end
  local branch = M.run({ "show-ref", "--verify", "--quiet", "refs/heads/" .. name }, { cwd = repo.main_root })
  if branch.code == 0 then return false, "branch already exists: " .. name end
  local destination = vim.fs.joinpath(repo.main_root, ".worktrees", name)
  if vim.uv.fs_stat(destination) then return false, "path already exists: " .. destination end
  return true
end

function M.create(repo, name, start_root)
  local valid, err = M.validate_name(repo, name)
  if not valid then return nil, err end

  local worktrees_dir = vim.fs.joinpath(repo.main_root, ".worktrees")
  vim.fn.mkdir(worktrees_dir, "p")
  local exclude_path = vim.fs.joinpath(repo.common_dir, "info", "exclude")
  local lines = vim.fn.readfile(exclude_path) or {}
  local excluded = false
  for _, line in ipairs(lines) do
    if line == "/.worktrees/" then
      excluded = true
      break
    end
  end
  if not excluded then
    table.insert(lines, "/.worktrees/")
    vim.fn.writefile(lines, exclude_path)
  end

  local destination = vim.fs.joinpath(worktrees_dir, name)
  local result = M.run({ "worktree", "add", "-b", name, destination, "HEAD" }, { cwd = start_root })
  if not result.ok then return nil, failure(result) end

  local worktrees, registry_error = worktree_registry(start_root)
  if not worktrees then return nil, registry_error end
  local destination_root = canonical(destination)
  for _, worktree in ipairs(worktrees) do
    if canonical(worktree.path) == destination_root then
      worktree.path = destination
      return worktree
    end
  end
  return nil, "created worktree is not registered: " .. destination
end

return M
