local M = {}

local registry = require("workspaces.registry")
local git = require("workspaces.git")
local session = require("workspace_session")

local sessions = {}
local list_generation = 0

local function canonical(path)
  return vim.fs.normalize(vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ":p"))
end

local function live_directory(path)
  local real = vim.uv.fs_realpath(path)
  if not real then return nil, "missing" end
  local stat = vim.uv.fs_stat(real)
  if not stat or stat.type ~= "directory" then return nil, "not a directory" end
  return vim.fs.normalize(real)
end

local function display_label(label)
  return label:gsub("%c", " ")
end

local function owns(path, root)
  path, root = canonical(path), canonical(root)
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function owner(path, roots)
  local result
  for _, root in ipairs(roots or {}) do
    if owns(path, root.path) and (not result or #canonical(root.path) > #canonical(result.path)) then
      result = root
    end
  end
  return result
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.ERROR)
end

local function registered_owner(path, roots)
  if session.owner then return session.owner(path, roots) end
  return owner(path, roots)
end

function M.format_row(workspace, metadata, active_path)
  local marker = active_path and canonical(workspace.path) == canonical(active_path) and "● " or "  "
  local kind = metadata and metadata.kind
  local branch, details
  if kind == "git" then
    local status = metadata.status or {}
    branch = status.detached and "(detached)" or (status.branch or "—")
    details = string.format(
      "S:%d U:%d ?:%d ↑%s ↓%s",
      status.staged or 0,
      status.unstaged or 0,
      status.untracked or 0,
      status.ahead ~= nil and tostring(status.ahead) or "-",
      status.behind ~= nil and tostring(status.behind) or "-"
    )
  elseif kind == "non_git" then
    branch, details = "—", "—"
  elseif kind == "missing" then
    branch, details = "—", "[missing]"
  else
    branch, details = "—", "ERR"
  end
  return string.format("%s%-15s %-15s %-25s %s", marker, display_label(workspace.label), branch, details, workspace.path)
end

local function create_previewer(row_lookup)
  return {
    _ctor = function()
      local preview = require("fzf-lua.previewer.builtin").base:extend()
      function preview:populate_preview_buf(entry)
        local path = row_lookup[entry]
        local buf = self:get_tmp_buffer()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, git.preview(path))
        self:set_preview_buf(buf)
        self.win:update_preview_title(path)
      end
      return preview
    end,
  }
end

local function find_record(records, path)
  local target = canonical(path)
  for _, record in ipairs(records) do
    if canonical(record.path) == target then return record end
  end
end

local function switch_selected(path, metadata_by_path)
  if metadata_by_path[path] and metadata_by_path[path].kind == "missing" then
    notify("Workspace is missing: " .. path)
    return
  end

  local fresh, load_error = registry.load()
  if not fresh then
    notify("Failed to reload workspace registry: " .. (load_error or "unknown error"))
    return
  end
  local destination = find_record(fresh, path)
  if not destination then
    notify("Workspace selection became stale: " .. path, vim.log.levels.WARN)
    return
  end

  local destination_path, destination_error = live_directory(destination.path)
  if not destination_path then
    notify("Workspace destination is missing or is " .. destination_error .. ": " .. destination.path)
    return
  end
  destination.path = destination_path

  local cwd = vim.uv.cwd()
  local source = registered_owner(cwd, fresh)
  local from = source and canonical(source.path) or canonical(cwd)
  if canonical(destination.path) == from then return end

  local ok, switched, switch_error = pcall(session.switch, sessions, destination, fresh, {
    require_source = false,
    allow_modified = true,
    first_visit = "clean",
  })
  if not ok then
    notify("Workspace switch failed: " .. tostring(switched))
    return
  end
  if not switched then
    notify(string.format("Workspace switch failed: %s at %s", switch_error or "unknown error", destination.path))
    return
  end

  vim.api.nvim_exec_autocmds("User", {
    pattern = "WorkspaceChanged",
    data = { from = from, to = destination.path },
  })
end

function M.add()
  vim.ui.input({ prompt = "Workspace label: " }, function(input)
    if input == nil then return end
    local rows, err = registry.add(vim.trim(input), vim.uv.cwd())
    if not rows then notify(err or "failed to add workspace") end
  end)
end

function M.delete()
  local rows, err = registry.remove(vim.uv.cwd())
  if not rows then notify(err or "failed to delete workspace") end
end

function M.list()
  local records, load_error = registry.load()
  if not records then
    notify("Failed to load workspace registry: " .. (load_error or "unknown error"))
    return
  end
  if #records == 0 then
    notify("No workspaces found", vim.log.levels.INFO)
    return
  end

  list_generation = list_generation + 1
  local generation = list_generation
  local metadata, pending = {}, #records
  local row_lookup, rows = {}, {}
  local opened = false

  local function open_picker()
    if opened or generation ~= list_generation then return end
    opened = true
    local active = registered_owner(vim.uv.cwd(), records)
    local active_path = active and active.path
    for _, record in ipairs(records) do
      local path = canonical(record.path)
      local row = M.format_row(record, metadata[path], active_path)
      table.insert(rows, row)
      row_lookup[row] = path
    end
    require("fzf-lua").fzf_exec(rows, {
      previewer = create_previewer(row_lookup),
      actions = {
        default = function(selected)
          local path = selected[1] and row_lookup[selected[1]]
          if path then switch_selected(path, metadata) end
        end,
        ["ctrl-d"] = function(selected)
          local path = selected[1] and row_lookup[selected[1]]
          if not path then return end
          local removed, remove_error = registry.remove(path)
          if not removed then notify(remove_error or "failed to delete workspace") end
          return true
        end,
      },
    })
  end

  for _, record in ipairs(records) do
    local path = canonical(record.path)
    git.inspect_async(record.path, function(result)
      if generation ~= list_generation then return end
      metadata[path] = result
      pending = pending - 1
      if pending == 0 then open_picker() end
    end)
  end
end

return M
