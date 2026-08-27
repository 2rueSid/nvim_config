local M = {}

local git = require("worktrees.git")
local session = require("worktrees.session")

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

  -- Row -> canonical path lookup for the current picker
  local row_lookup = {}

  -- Gather status for all worktrees asynchronously
  local pending = #repo.worktrees
  local rows = {}
  local statuses = {}

  for _, worktree in ipairs(repo.worktrees) do
    git.status_async(worktree.path, function(status, status_err)
      statuses[worktree.path] = { status = status, error = status_err }
      pending = pending - 1

      if pending == 0 then
        -- All statuses gathered, now create rows and open fzf
        for _, wt in ipairs(repo.worktrees) do
          local st = statuses[wt.path]
          local row = M.format_row(wt, st.status, repo.current_root)
          table.insert(rows, row)
          row_lookup[row] = wt.path
        end

        if #rows > 0 then
          local fzf = require("fzf-lua")
          local previewer_instance = create_previewer(row_lookup)

          fzf.fzf_exec(rows, {
            preview = previewer_instance,
            actions = {
              default = function(selected)
                if #selected > 0 then
                  local selected_row = selected[1]
                  local selected_path = row_lookup[selected_row]

                  if selected_path then
                    -- Re-resolve from fresh registry to catch external changes
                    local fresh_repo, repo_err = git.repository(selected_path)
                    if fresh_repo then
                      local found_worktree = nil
                      for _, wt in ipairs(fresh_repo.worktrees) do
                        if vim.fs.normalize(wt.path) == vim.fs.normalize(selected_path) then
                          found_worktree = wt
                          break
                        end
                      end

                      if found_worktree then
                        session.switch(found_worktree, fresh_repo.worktrees)
                      else
                        vim.notify("Worktree selection became stale", vim.log.levels.WARN)
                      end
                    else
                      vim.notify("Failed to re-resolve repository: " .. (repo_err or "unknown error"), vim.log.levels.ERROR)
                    end
                  end
                end
              end,
            },
          })
        end
      end
    end)
  end
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
    local created_worktree, create_err = git.create(repo, name, repo.current_root)
    if not created_worktree then
      vim.notify(create_err, vim.log.levels.ERROR)
      return
    end

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

-- Merge a worktree (stub for now, will be implemented in Task 5)
function M.merge()
  vim.notify("merge not yet implemented", vim.log.levels.INFO)
end

return M
