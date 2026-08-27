local h = require("helpers")
local git = require("worktrees.git")
local session = require("worktrees.session")

local original_cwd = vim.uv.cwd()

local function reset_editor()
  pcall(vim.cmd, "silent! tabonly")
  pcall(vim.cmd, "silent! only")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
  end
  vim.cmd("enew")
  vim.cmd.cd(vim.fn.fnameescape(original_cwd))
  session.reset()
end

local function fixture(test)
  reset_editor()
  local root = h.temp_repo()
  local shared = {}
  for line = 1, 80 do shared[line] = string.rep("x", 100) .. line end
  vim.fn.writefile(shared, root .. "/shared.txt")
  vim.fn.writefile({ "alpha", "beta", "gamma" }, root .. "/other.txt")
  h.git(root, { "add", "shared.txt", "other.txt" })
  h.git(root, { "commit", "-m", "layout files" })
  local linked = root .. "/.worktrees/A"
  h.git(root, { "worktree", "add", "-b", "A", linked })
  local repo = assert(git.repository(root))
  vim.cmd.cd(vim.fn.fnameescape(repo.worktrees[1].path))
  local ok, err = xpcall(function()
    test({
      root = repo.worktrees[1].path,
      linked = repo.worktrees[2].path,
      worktrees = repo.worktrees,
      destination = repo.worktrees[2],
    })
  end, debug.traceback)
  reset_editor()
  h.cleanup(root)
  if not ok then error(err) end
end

local function normal_file(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function normal_paths_by_tab()
  local result = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local paths = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if normal_file(buf) then table.insert(paths, vim.fs.normalize(vim.api.nvim_buf_get_name(buf))) end
    end
    table.insert(result, paths)
  end
  return result
end

local function layout_snapshot(layout)
  if layout[1] == "leaf" then
    local buf = vim.api.nvim_win_get_buf(layout[2])
    return { "leaf", vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) }
  end
  local children = {}
  for _, child in ipairs(layout[2]) do table.insert(children, layout_snapshot(child)) end
  return { layout[1], children }
end

local function workspace_snapshot()
  local result = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local windows = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if normal_file(buf) then
        local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
        table.insert(windows, {
          path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf)),
          cursor = vim.api.nvim_win_get_cursor(win),
          view = { lnum = view.lnum, col = view.col, topline = view.topline, leftcol = view.leftcol },
        })
      end
    end
    local layout = vim.fn.winlayout(vim.api.nvim_tabpage_get_number(tab))
    table.insert(result, { layout = layout_snapshot(layout), windows = windows })
  end
  return result
end

return {
  resolves_nested_worktree_by_longest_root = function()
    local worktrees = {
      { path = "/repo" },
      { path = "/repo/.worktrees/a" },
    }
    h.eq("/repo/.worktrees/a", session.owner("/repo/.worktrees/a/docs/x.md", worktrees).path)
    assert(session.owner("/repo-other/file.md", worktrees) == nil)
    assert(session.owner("/tmp/external.md", worktrees) == nil)
    h.eq("/", session.owner("/any/descendant", { { path = "/" } }).path)
  end,

  maps_files_relative_to_a_root_worktree = function()
    reset_editor()
    local source = vim.fn.tempname() .. ".txt"
    local destination = vim.fn.tempname()
    vim.fn.writefile({ "source" }, source)
    vim.fn.mkdir(destination, "p")
    local worktrees = { { path = "/" }, { path = vim.fs.normalize(destination) } }
    local ok, err = xpcall(function()
      vim.cmd.cd("/")
      vim.cmd.edit(vim.fn.fnameescape(source))
      local source_path = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
      assert(session.switch(worktrees[2], worktrees))
      local expected = vim.fs.joinpath(destination, source_path:sub(2))
      h.eq(vim.fs.normalize(expected), vim.fs.normalize(vim.api.nvim_buf_get_name(0)))
    end, debug.traceback)
    reset_editor()
    h.cleanup(destination)
    vim.fn.delete(source)
    if not ok then error(err) end
  end,

  rejects_modified_file_buffers = function()
    reset_editor()
    local path = vim.fn.tempname() .. ".md"
    vim.fn.writefile({ "saved" }, path)
    vim.cmd.edit(vim.fn.fnameescape(path))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local modified, names = session.has_modified_file_buffers()
    assert(modified)
    h.eq(vim.fs.normalize(vim.api.nvim_buf_get_name(0)), names[1])
    vim.cmd("bwipeout!")
    vim.fn.delete(path)
    reset_editor()
  end,

  maps_first_visit_layout_and_closes_non_file_windows = function()
    fixture(function(fx)
      local missing = fx.root .. "/only-main.txt"
      local external = vim.fn.tempname() .. ".txt"
      vim.fn.writefile({ "main only" }, missing)
      vim.fn.writefile({ "external" }, external)

      vim.cmd.edit(vim.fn.fnameescape(fx.root .. "/base.txt"))
      vim.cmd.vsplit(vim.fn.fnameescape(missing))
      vim.cmd.split(vim.fn.fnameescape(external))
      vim.cmd.tabnew(vim.fn.fnameescape(fx.root .. "/shared.txt"))
      vim.cmd.split(vim.fn.fnameescape(fx.root .. "/base.txt"))
      vim.fn.setqflist({ { filename = fx.root .. "/base.txt", lnum = 1, text = "item" } })
      vim.cmd("copen")

      local source_layout = normal_paths_by_tab()
      local expected = vim.deepcopy(source_layout)
      for _, paths in ipairs(expected) do
        for index, path in ipairs(paths) do
          local owned = session.owner(path, fx.worktrees)
          if owned and owned.path == fx.root then
            paths[index] = vim.fs.joinpath(fx.linked, path:sub(#fx.root + 2))
          end
        end
      end

      assert(session.switch(fx.destination, fx.worktrees))
      h.eq(vim.fs.normalize(fx.linked), vim.uv.cwd())
      h.eq(expected, normal_paths_by_tab())
      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
          assert(vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "")
        end
      end

      local missing_destination = vim.fs.joinpath(fx.linked, "only-main.txt")
      assert(vim.uv.fs_stat(missing_destination) == nil)
      local missing_buf = vim.fn.bufnr(missing_destination)
      assert(missing_buf > 0)
      assert(not vim.bo[missing_buf].modified)
      assert(vim.fn.bufnr(external) > 0)
      vim.fn.delete(external)
    end)
  end,

  restores_saved_destination_layout_and_cursor = function()
    fixture(function(fx)
      vim.cmd.edit(vim.fn.fnameescape(fx.root .. "/base.txt"))
      assert(session.switch(fx.destination, fx.worktrees))

      vim.cmd("tabonly | only")
      vim.cmd.edit(vim.fn.fnameescape(fx.linked .. "/shared.txt"))
      vim.wo.wrap = false
      vim.fn.winrestview({ lnum = 40, col = 30, topline = 25, leftcol = 15 })
      vim.cmd.vsplit(vim.fn.fnameescape(fx.linked .. "/other.txt"))
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      vim.cmd.tabnew(vim.fn.fnameescape(fx.linked .. "/shared.txt"))
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      local saved = workspace_snapshot()

      assert(session.switch(fx.worktrees[1], fx.worktrees))
      vim.cmd("tabonly | only")
      vim.cmd.edit(vim.fn.fnameescape(fx.root .. "/other.txt"))
      assert(session.switch(fx.destination, fx.worktrees))
      h.eq(saved, workspace_snapshot())
    end)
  end,

  stops_only_source_owned_lsp_clients = function()
    fixture(function(fx)
      vim.cmd.edit(vim.fn.fnameescape(fx.root .. "/base.txt"))
      local stopped = {}
      local clients = {
        { root_dir = fx.root, stop = function() table.insert(stopped, "source") end },
        { root_dir = fx.linked, stop = function() table.insert(stopped, "destination") end },
        { root_dir = vim.fn.tempname(), stop = function() table.insert(stopped, "external") end },
      }
      local original = vim.lsp.get_clients
      local ok, err = xpcall(function()
        vim.lsp.get_clients = function() return clients end
        assert(session.switch(fx.destination, fx.worktrees))
        h.eq({ "source" }, stopped)
      end, debug.traceback)
      vim.lsp.get_clients = original
      if not ok then error(err) end
    end)
  end,

  rolls_back_when_saved_destination_restore_fails = function()
    fixture(function(fx)
      vim.cmd.edit(vim.fn.fnameescape(fx.root .. "/base.txt"))
      assert(session.switch(fx.destination, fx.worktrees))
      assert(session.switch(fx.worktrees[1], fx.worktrees))

      local original = session.restore
      local calls = 0
      local switch_ok, switch_err
      local protected, err = xpcall(function()
        session.restore = function(script)
          calls = calls + 1
          if calls == 1 then return false, "injected destination failure" end
          return original(script)
        end
        switch_ok, switch_err = session.switch(fx.destination, fx.worktrees)
      end, debug.traceback)
      session.restore = original
      if not protected then error(err) end
      assert(not switch_ok)
      assert(switch_err:match("injected destination failure"))
      h.eq(vim.fs.normalize(fx.root), vim.uv.cwd())
      h.eq(2, calls)
    end)
  end,

  replaces_a_modified_non_file_window_when_hidden_is_disabled = function()
    reset_editor()
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")
    local previous_hidden = vim.o.hidden
    local ok, err = xpcall(function()
      vim.o.hidden = false
      vim.bo.buftype = "nofile"
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "modified plugin state" })
      vim.bo.modified = true
      local plugin_buf = vim.api.nvim_get_current_buf()

      assert(session.capture(root))
      h.eq(1, #vim.api.nvim_list_wins())
      local buf = vim.api.nvim_get_current_buf()
      assert(buf ~= plugin_buf)
      h.eq("", vim.bo[buf].buftype)
      h.eq("", vim.api.nvim_buf_get_name(buf))
    end, debug.traceback)
    vim.o.hidden = previous_hidden
    reset_editor()
    h.cleanup(root)
    if not ok then error(err) end
  end,

  restores_sessionoptions_when_capture_fails = function()
    reset_editor()
    local previous = vim.o.sessionoptions
    local script, err = session.capture(vim.fn.tempname() .. "/missing")
    assert(script == nil)
    assert(type(err) == "string" and err ~= "")
    h.eq(previous, vim.o.sessionoptions)
    reset_editor()
  end,
}
