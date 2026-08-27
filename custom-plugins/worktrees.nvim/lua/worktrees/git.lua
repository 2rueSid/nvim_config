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

return M
