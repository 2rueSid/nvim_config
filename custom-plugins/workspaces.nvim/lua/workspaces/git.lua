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
  if opts and opts.cwd then vim.list_extend(cmd, { "-C", opts.cwd }) end
  vim.list_extend(cmd, args)
  return cmd
end

function M.run(args, opts)
  return normalize(vim.system(command(args, opts), { text = true }):wait())
end

function M.run_async(args, opts, callback)
  vim.system(command(args, opts), { text = true }, function(result)
    vim.schedule(function() callback(normalize(result)) end)
  end)
end

function M.parse_status(stdout)
  local status = {
    branch = nil,
    detached = false,
    staged = 0,
    unstaged = 0,
    untracked = 0,
    conflicted = 0,
    ahead = nil,
    behind = nil,
  }
  for line in (stdout .. "\n"):gmatch("([^\n]*)\n") do
    local branch = line:match("^# branch%.head (.*)$")
    local ahead, behind = line:match("^# branch%.ab %+(%d+) %-(%d+)$")
    if branch then
      if branch == "(detached)" then
        status.detached = true
      else
        status.branch = branch
      end
    elseif ahead then
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

local status_args = { "status", "--porcelain=v2", "--branch", "--untracked-files=all" }

function M.inspect_async(path, callback)
  local stat, stat_error, stat_code = vim.uv.fs_stat(path)
  if not stat then
    local missing = stat_code == "ENOENT"
      or (type(stat_error) == "string" and stat_error:match("^ENOENT") ~= nil)
    local result
    if missing then
      result = { kind = "missing" }
    else
      result = {
        kind = "error",
        error = stat_error ~= nil and tostring(stat_error)
          or stat_code ~= nil and tostring(stat_code)
          or "failed to stat path",
      }
    end
    vim.schedule(function() callback(result) end)
    return
  end
  M.run_async(status_args, { cwd = path }, function(result)
    if result.ok then
      callback({ kind = "git", status = M.parse_status(result.stdout) })
    elseif result.stderr:find("not a git repository", 1, true) then
      callback({ kind = "non_git" })
    else
      callback({ kind = "error", error = result.stderr ~= "" and result.stderr or "git status failed" })
    end
  end)
end

local function absolute(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

function M.preview(path)
  path = absolute(path)
  local lines = { path }
  if not vim.uv.fs_stat(path) then
    table.insert(lines, "")
    table.insert(lines, "Path does not exist")
    return lines
  end

  local status = M.run({ "status", "--short", "--branch" }, { cwd = path })
  if not status.ok then
    table.insert(lines, "")
    if status.stderr:find("not a git repository", 1, true) then
      table.insert(lines, "Not a Git repository")
    else
      table.insert(lines, status.stderr ~= "" and status.stderr or "Git status failed")
    end
    return lines
  end

  table.insert(lines, "")
  for line in (status.stdout .. "\n"):gmatch("([^\n]*)\n") do
    if line ~= "" then table.insert(lines, line) end
  end
  table.insert(lines, "")
  local log = M.run({ "log", "--oneline", "-5" }, { cwd = path })
  if log.ok then
    for line in (log.stdout .. "\n"):gmatch("([^\n]*)\n") do
      if line ~= "" then table.insert(lines, line) end
    end
  elseif log.stderr ~= "" then
    table.insert(lines, log.stderr)
  end
  return lines
end

return M
