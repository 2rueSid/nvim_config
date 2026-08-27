local M = {}

local sessions = {}

local function normalize(path)
  return vim.fs.normalize(path)
end

local function normal_file_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function same_path(left, right)
  return normalize(left) == normalize(right)
end

local function relative_to(path, root)
  path, root = normalize(path), normalize(root)
  if path == root then return "" end
  local prefix = root:sub(-1) == "/" and root or root .. "/"
  if path:sub(1, #prefix) == prefix then return path:sub(#prefix + 1) end
end

function M.owner(path, worktrees)
  path = normalize(path)
  local candidates = {}
  for _, worktree in ipairs(worktrees or {}) do
    table.insert(candidates, worktree)
  end
  table.sort(candidates, function(left, right) return #normalize(left.path) > #normalize(right.path) end)
  for _, worktree in ipairs(candidates) do
    if relative_to(path, worktree.path) ~= nil then return worktree end
  end
end

function M.has_modified_file_buffers()
  local names = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if normal_file_buffer(buf) and vim.bo[buf].modified then
      table.insert(names, normalize(vim.api.nvim_buf_get_name(buf)))
    end
  end
  table.sort(names)
  return #names > 0, names
end

local function close_non_file_windows()
  local normal_count = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if normal_file_buffer(vim.api.nvim_win_get_buf(win)) then normal_count = normal_count + 1 end
  end

  if normal_count == 0 then
    vim.cmd("tabonly!")
    vim.cmd("only!")
    vim.cmd("enew!")
    return
  end

  local tabs = vim.api.nvim_list_tabpages()
  for index = #tabs, 1, -1 do
    local tab = tabs[index]
    if vim.api.nvim_tabpage_is_valid(tab) then
      local normal_windows, other_windows = {}, {}
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if normal_file_buffer(vim.api.nvim_win_get_buf(win)) then
          table.insert(normal_windows, win)
        else
          table.insert(other_windows, win)
        end
      end
      if #normal_windows == 0 then
        vim.api.nvim_tabpage_close(tab, true)
      else
        for _, win in ipairs(other_windows) do
          if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
        end
      end
    end
  end
end

local function view_restore_commands()
  local commands = {}
  local current = vim.fn.win_id2tabwin(vim.api.nvim_get_current_win())
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local position = vim.fn.win_id2tabwin(win)
      local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
      table.insert(commands, string.format("tabnext %d", position[1]))
      table.insert(commands, string.format("%dwincmd w", position[2]))
      table.insert(commands, "call winrestview(" .. vim.fn.string(view) .. ")")
    end
  end
  table.insert(commands, string.format("tabnext %d", current[1]))
  table.insert(commands, string.format("%dwincmd w", current[2]))
  return commands
end

function M.capture(root)
  local previous = vim.o.sessionoptions
  local file = vim.fn.tempname() .. ".vim"
  local ok, result = xpcall(function()
    close_non_file_windows()
    local view_commands = view_restore_commands()
    vim.o.sessionoptions = "curdir,folds,tabpages,winsize"
    vim.cmd.cd(vim.fn.fnameescape(root))
    vim.cmd("silent mksession! " .. vim.fn.fnameescape(file))
    local lines = vim.fn.readfile(file)
    vim.list_extend(lines, view_commands)
    return table.concat(lines, "\n")
  end, debug.traceback)
  vim.o.sessionoptions = previous
  vim.fn.delete(file)
  if not ok then return nil, result end
  return result
end

function M.restore(script)
  local ok, err = xpcall(function() vim.api.nvim_exec2(script, {}) end, debug.traceback)
  if not ok then return false, err end
  return true
end

local function source_buffers(source, worktrees)
  local result = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if normal_file_buffer(buf) then
      local owned = M.owner(vim.api.nvim_buf_get_name(buf), worktrees)
      if owned and same_path(owned.path, source.path) then table.insert(result, buf) end
    end
  end
  return result
end

local function views_by_window()
  local result = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if normal_file_buffer(buf) then
      result[win] = {
        cursor = vim.api.nvim_win_get_cursor(win),
        view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
      }
    end
  end
  return result
end

local function clamp_views(views)
  for win, saved in pairs(views) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local line_count = math.max(vim.api.nvim_buf_line_count(buf), 1)
      local line = math.min(saved.cursor[1], line_count)
      local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or ""
      local cursor = { line, math.min(saved.cursor[2], #text) }
      saved.view.lnum = math.min(saved.view.lnum, line_count)
      saved.view.topline = math.min(saved.view.topline, line_count)
      saved.view.col = math.min(saved.view.col, #text)
      vim.api.nvim_win_call(win, function() vim.fn.winrestview(saved.view) end)
      vim.api.nvim_win_set_cursor(win, cursor)
    end
  end
end

local function map_first_visit(source, destination, worktrees, views)
  local source_root = normalize(source.path)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if normal_file_buffer(buf) then
      local path = normalize(vim.api.nvim_buf_get_name(buf))
      local owned = M.owner(path, worktrees)
      if owned and same_path(owned.path, source_root) then
        local destination_path = vim.fs.joinpath(destination.path, relative_to(path, source_root))
        vim.api.nvim_win_set_buf(win, vim.fn.bufadd(destination_path))
      end
    end
  end
  return views
end

local function stop_source_clients(source, worktrees)
  for _, client in ipairs(vim.lsp.get_clients()) do
    local root = client.root_dir or (client.config and client.config.root_dir)
    local owned = root and M.owner(root, worktrees) or nil
    if owned and same_path(owned.path, source.path) then client:stop() end
  end
end

local function delete_obsolete_buffers(buffers)
  local displayed = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    displayed[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) and not displayed[buf] and not vim.bo[buf].modified then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end

function M.switch(destination, worktrees)
  local selected
  for _, worktree in ipairs(worktrees or {}) do
    if destination and destination.path and same_path(worktree.path, destination.path) then
      selected = worktree
      break
    end
  end
  if not selected then return false, "destination worktree is no longer registered" end

  local source = M.owner(vim.uv.cwd(), worktrees)
  if not source then return false, "current directory is not owned by a registered worktree" end
  if same_path(source.path, selected.path) then return true end

  local modified, names = M.has_modified_file_buffers()
  if modified then return false, "modified file buffers block switching: " .. table.concat(names, ", ") end

  local source_script, capture_error = M.capture(source.path)
  if not source_script then return false, capture_error end
  sessions[normalize(source.path)] = source_script

  local obsolete = source_buffers(source, worktrees)
  local first_visit_views = views_by_window()
  local ok, operation_error = xpcall(function()
    stop_source_clients(source, worktrees)
    local destination_script = sessions[normalize(selected.path)]
    local views
    if destination_script then
      local restored, restore_error = M.restore(destination_script)
      if not restored then error(restore_error, 0) end
      views = views_by_window()
    else
      views = map_first_visit(source, selected, worktrees, first_visit_views)
    end
    vim.cmd.cd(vim.fn.fnameescape(selected.path))
    clamp_views(views)
    delete_obsolete_buffers(obsolete)
  end, debug.traceback)

  if ok then return true end
  local rolled_back, rollback_error = M.restore(source_script)
  if not rolled_back then
    return false, operation_error .. "\nrollback failed: " .. rollback_error
  end
  return false, operation_error
end

function M.reset()
  sessions = {}
end

return M
