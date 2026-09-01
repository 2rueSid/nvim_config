local M = {}
local config = {}

local git = require("worktrees.git")
local session = require("worktrees.session")

function M.setup(opts)
  config = opts or {}
end

-- Helper: Create a previewer for fzf-lua
local function create_previewer(row_lookup)
  return {
    _ctor = function()
      local preview = require("fzf-lua.previewer.builtin").base:extend()

      function preview:populate_preview_buf(entry)
        local path = row_lookup[entry]
        if not path then
          return
        end

        local status = git.run({ "status", "--short", "--branch" }, { cwd = path })
        local log = git.run({ "log", "-n", "10", "--oneline", "--decorate" }, { cwd = path })

        local lines = {}
        if status.stdout then
          for line in (status.stdout or ""):gmatch("[^\n]+") do
            table.insert(lines, line)
          end
        end
        table.insert(lines, "")
        if log.stdout then
          for line in (log.stdout or ""):gmatch("[^\n]+") do
            table.insert(lines, line)
          end
        end

        local buf = self:get_tmp_buffer()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        self:set_preview_buf(buf)
        self.win:update_preview_title(path)
      end

      return preview
    end,
  }
end

-- Format a row for the fzf picker
-- Params:
--   worktree: table with path, branch, detached, locked, prunable
--   status: table with staged, unstaged, untracked, conflicted, ahead, behind (or nil if error)
--   active_path: path of the current worktree (for marking with ●)
function M.format_row(worktree, status, active_path)
  local prefix = ""
  if worktree.path == active_path then
    prefix = "● "
  else
    prefix = "  "
  end

  -- Worktree name
  local name = vim.fs.basename(worktree.path)
  if worktree.path == active_path or vim.fs.basename(active_path) == "main" then
    -- For main worktree, display "main" as name
    if not worktree.branch or (not worktree.branch:find("main", 1, true) and worktree.detached) then
      name = "main"
    elseif worktree.branch then
      name = worktree.branch
    end
  end

  -- Branch text
  local branch = ""
  if worktree.detached then
    branch = "(detached)"
  else
    branch = worktree.branch or "(unknown)"
  end

  -- Status metrics
  local metrics = ""
  if status == nil then
    metrics = "ERR"
  else
    local staged = status.staged or 0
    local unstaged = status.unstaged or 0
    local untracked = status.untracked or 0
    local ahead = status.ahead
    local behind = status.behind

    local ahead_str = ahead ~= nil and tostring(ahead) or "-"
    local behind_str = behind ~= nil and tostring(behind) or "-"

    metrics = string.format("S:%d U:%d ?:%d ↑%s ↓%s", staged, unstaged, untracked, ahead_str, behind_str)
  end

  -- Labels for special states
  local labels = {}
  if worktree.detached then
    table.insert(labels, "detached")
  end
  if worktree.locked then
    table.insert(labels, "locked")
  end
  if worktree.prunable then
    table.insert(labels, "prunable")
  end
  if status == nil then
    table.insert(labels, "ERR")
  end

  local label_str = ""
  if #labels > 0 then
    label_str = "[" .. table.concat(labels, ",") .. "]"
  end

  return string.format("%s%-15s %-15s %s %s %s", prefix, name, branch, metrics, label_str, worktree.path)
end

local function pick(repo, worktrees, on_select)
  local row_lookup, rows, statuses = {}, {}, {}
  local pending = #worktrees

  for _, worktree in ipairs(worktrees) do
    git.status_async(worktree.path, function(status, status_err)
      statuses[worktree.path] = { status = status, error = status_err }
      pending = pending - 1
      if pending ~= 0 then return end

      for _, candidate in ipairs(worktrees) do
        local row = M.format_row(candidate, statuses[candidate.path].status, repo.current_root)
        table.insert(rows, row)
        row_lookup[row] = candidate.path
      end

      require("fzf-lua").fzf_exec(rows, {
        previewer = create_previewer(row_lookup),
        actions = {
          default = function(selected)
            if selected[1] and row_lookup[selected[1]] then on_select(row_lookup[selected[1]]) end
          end,
        },
      })
    end)
  end
end

local function canonical(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or path)
end

local function find_worktree(worktrees, path)
  path = canonical(path)
  for _, worktree in ipairs(worktrees) do
    if canonical(worktree.path) == path then return worktree end
  end
end

-- List all worktrees with an fzf picker
function M.list()
  local repo, err = git.repository(vim.fn.getcwd())
  if not repo then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if #repo.worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.INFO)
    return
  end

  pick(repo, repo.worktrees, function(selected_path)
    local fresh_repo, repo_err = git.repository(selected_path)
    if not fresh_repo then
      vim.notify("Failed to re-resolve repository: " .. (repo_err or "unknown error"), vim.log.levels.ERROR)
      return
    end
    local selected = find_worktree(fresh_repo.worktrees, selected_path)
    if not selected then
      vim.notify("Worktree selection became stale", vim.log.levels.WARN)
      return
    end
    local ok, switch_err = session.switch(selected, fresh_repo.worktrees)
    if not ok then
      vim.notify(string.format("Worktree switch failed: %s at %s", switch_err, selected.path), vim.log.levels.ERROR)
    end
  end)
end

-- Create a worktree with user input
function M.create()
  local repo, err = git.repository(vim.fn.getcwd())
  if not repo then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "Worktree name: " }, function(input)
    if input == nil then
      return
    end

    local name = vim.trim(input)

    -- Attempt creation
    local created_worktree, create_err = git.create(repo, name, repo.current_root, config.propagate)
    if not created_worktree then
      vim.notify(create_err, vim.log.levels.ERROR)
      return
    end
    if create_err then vim.notify(create_err, vim.log.levels.WARN) end

    -- Refresh registry from the created worktree's location
    local fresh_repo, repo_err = git.repository(created_worktree.path)
    if not fresh_repo then
      vim.notify(repo_err, vim.log.levels.ERROR)
      return
    end

    -- Switch to the created worktree
    local ok, switch_err = session.switch(created_worktree, fresh_repo.worktrees)
    if not ok then
      vim.notify(string.format("Worktree created but switch failed: %s at %s", switch_err, created_worktree.path), vim.log.levels.WARN)
    end
  end)
end

function M.merge()
  local repo, err = git.repository(vim.fn.getcwd())
  if not repo then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local sources = {}
  for _, worktree in ipairs(repo.worktrees) do
    if canonical(worktree.path) ~= canonical(repo.main_root) then table.insert(sources, worktree) end
  end
  if #sources == 0 then
    vim.notify("No source worktrees found", vim.log.levels.INFO)
    return
  end

  pick(repo, sources, function(selected_path)
    local fresh_repo, repo_err = git.repository(selected_path)
    if not fresh_repo then
      vim.notify("Failed to re-resolve repository: " .. (repo_err or "unknown error"), vim.log.levels.ERROR)
      return
    end
    local source = find_worktree(fresh_repo.worktrees, selected_path)
    if not source or canonical(source.path) == canonical(fresh_repo.main_root) then
      vim.notify("Worktree selection became stale", vim.log.levels.WARN)
      return
    end
    if source.detached or not source.branch then
      vim.notify("Source worktree is detached", vim.log.levels.ERROR)
      return
    end

    local modified = session.has_modified_file_buffers()
    if modified then
      vim.notify("Cannot merge while file buffers have unsaved changes", vim.log.levels.ERROR)
      return
    end

    local target = git.run({ "symbolic-ref", "--quiet", "--short", "HEAD" }, { cwd = fresh_repo.main_root })
    if not target.ok then
      vim.notify("Main worktree is detached", vim.log.levels.ERROR)
      return
    end
    local target_branch = vim.trim(target.stdout)
    if source.branch == target_branch then
      vim.notify("Source and target branches must differ", vim.log.levels.ERROR)
      return
    end

    vim.ui.select({ "Merge", "Cancel" }, {
      prompt = string.format("Merge %s into %s?", source.branch, target_branch),
    }, function(choice)
      if choice ~= "Merge" then return end

      local result = git.merge(fresh_repo, source)
      if not result.ok then
        local message = (result.aborted and "Merge failed and was aborted: " or "Merge failed: ")
          .. (result.error or "unknown error")
        if result.abort_error then message = message .. "\nAbort failed: " .. result.abort_error end
        vim.notify(message, vim.log.levels.ERROR)
        return
      end

      vim.notify(string.format("Merged %s into %s", source.branch, target_branch), vim.log.levels.INFO)
      local owner = session.owner(vim.uv.cwd(), fresh_repo.worktrees)
      if owner and canonical(owner.path) == canonical(fresh_repo.main_root) then vim.cmd("checktime") end
    end)
  end)
end

return M
