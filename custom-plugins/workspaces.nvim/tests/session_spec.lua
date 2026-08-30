local h = require("helpers")
local engine = require("workspace_session")

local function switch(sessions, destination, roots, options)
  options = options or {}
  if options.require_source == nil then options.require_source = false end
  if options.allow_modified == nil then options.allow_modified = true end
  options.first_visit = options.first_visit or "clean"
  return engine.switch(sessions, destination, roots, options)
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
      if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
        local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
        table.insert(windows, {
          path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf)),
          cursor = vim.api.nvim_win_get_cursor(win),
          view = { lnum = view.lnum, col = view.col, topline = view.topline, leftcol = view.leftcol },
        })
      end
    end
    table.insert(result, {
      layout = layout_snapshot(vim.fn.winlayout(vim.api.nvim_tabpage_get_number(tab))),
      windows = windows,
    })
  end
  return result
end

local function roots(source, destination)
  return {
    { label = "source", path = assert(vim.uv.fs_realpath(source)) },
    { label = "destination", path = assert(vim.uv.fs_realpath(destination)) },
  }
end

return {
  first_visit_is_clean_and_preserves_modified_source_buffer = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local source_file = source .. "/source.txt"
    vim.fn.writefile({ "saved" }, source_file)
    vim.cmd.cd(source)
    vim.cmd.edit(vim.fn.fnameescape(source_file))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved" })
    local source_buf = vim.api.nvim_get_current_buf()
    local sessions = {}
    local workspace_roots = roots(source, destination)

    assert(switch(sessions, workspace_roots[2], workspace_roots))
    h.eq(vim.fs.normalize(assert(vim.uv.fs_realpath(destination))), vim.uv.cwd())
    h.eq("", vim.api.nvim_buf_get_name(0))
    assert(vim.api.nvim_buf_is_valid(source_buf))
    assert(vim.bo[source_buf].modified)
    h.eq({ "unsaved" }, vim.api.nvim_buf_get_lines(source_buf, 0, -1, false))

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,

  restores_source_tabs_layout_cursors_and_modified_contents = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local source_file, other_file = source .. "/source.txt", source .. "/other.txt"
    vim.fn.writefile({ "one", "two", "three" }, source_file)
    vim.fn.writefile({ "alpha", "beta", "gamma" }, other_file)
    vim.cmd.cd(source)
    vim.cmd.edit(vim.fn.fnameescape(source_file))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved", "two", "three" })
    vim.api.nvim_win_set_cursor(0, { 2, 1 })
    vim.cmd.vsplit(vim.fn.fnameescape(other_file))
    vim.api.nvim_win_set_cursor(0, { 3, 2 })
    vim.cmd.tabnew(vim.fn.fnameescape(source_file))
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    local expected = workspace_snapshot()
    local sessions = {}
    local workspace_roots = roots(source, destination)

    assert(switch(sessions, workspace_roots[2], workspace_roots))
    assert(switch(sessions, workspace_roots[1], workspace_roots))
    h.eq(vim.fs.normalize(assert(vim.uv.fs_realpath(source))), vim.uv.cwd())
    h.eq(expected, workspace_snapshot())
    h.eq({ "unsaved", "two", "three" }, vim.api.nvim_buf_get_lines(vim.fn.bufnr(source_file), 0, -1, false))

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,

  allows_unregistered_source_without_persisting_its_session = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local source_file = source .. "/external.txt"
    vim.fn.writefile({ "saved" }, source_file)
    vim.cmd.cd(source)
    vim.cmd.edit(vim.fn.fnameescape(source_file))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved" })
    local source_buf = vim.api.nvim_get_current_buf()
    local sessions = {}
    local workspace_roots = { { label = "destination", path = destination } }

    assert(switch(sessions, workspace_roots[1], workspace_roots))
    h.eq(vim.fs.normalize(assert(vim.uv.fs_realpath(destination))), vim.uv.cwd())
    h.eq("", vim.api.nvim_buf_get_name(0))
    assert(vim.api.nvim_buf_is_valid(source_buf))
    assert(vim.bo[source_buf].modified)
    h.eq({}, sessions)
    h.eq({ "unsaved" }, vim.api.nvim_buf_get_lines(source_buf, 0, -1, false))

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,

  stops_only_source_rooted_lsp_clients = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local source_file = source .. "/source.txt"
    vim.fn.writefile({ "source" }, source_file)
    vim.cmd.cd(source)
    vim.cmd.edit(vim.fn.fnameescape(source_file))
    local stopped = {}
    local clients = {
      { root_dir = assert(vim.uv.fs_realpath(source)), stop = function() table.insert(stopped, "source") end },
      { root_dir = assert(vim.uv.fs_realpath(destination)), stop = function() table.insert(stopped, "destination") end },
      { root_dir = h.temp_dir(), stop = function() table.insert(stopped, "external") end },
    }
    local original = vim.lsp.get_clients
    local sessions = {}
    local workspace_roots = roots(source, destination)
    local ok, err = xpcall(function()
      vim.lsp.get_clients = function() return clients end
      assert(switch(sessions, workspace_roots[2], workspace_roots))
      h.eq({ "source" }, stopped)
    end, debug.traceback)
    vim.lsp.get_clients = original
    if not ok then error(err) end

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
    h.cleanup(clients[3].root_dir)
  end,

  stops_transient_source_rooted_lsp_clients_without_prefix_collisions = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local nested = source .. "/nested"
    vim.fn.mkdir(nested, "p")
    vim.cmd.cd(source)
    local stopped = {}
    local clients = {
      { root_dir = assert(vim.uv.fs_realpath(source)), stop = function() table.insert(stopped, "source") end },
      { root_dir = assert(vim.uv.fs_realpath(nested)), stop = function() table.insert(stopped, "nested") end },
      { root_dir = source .. "-sibling", stop = function() table.insert(stopped, "sibling") end },
      { root_dir = assert(vim.uv.fs_realpath(destination)), stop = function() table.insert(stopped, "destination") end },
    }
    local original = vim.lsp.get_clients
    local sessions = {}
    local workspace_roots = { { label = "destination", path = assert(vim.uv.fs_realpath(destination)) } }
    local ok, err = xpcall(function()
      vim.lsp.get_clients = function() return clients end
      assert(switch(sessions, workspace_roots[1], workspace_roots))
      h.eq({ "source", "nested" }, stopped)
    end, debug.traceback)
    vim.lsp.get_clients = original
    if not ok then error(err) end

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,

  rolls_back_source_when_first_destination_restore_fails = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local source_file, destination_file = source .. "/source.txt", destination .. "/destination.txt"
    vim.fn.writefile({ "source" }, source_file)
    vim.fn.writefile({ "destination" }, destination_file)
    vim.cmd.cd(source)
    vim.cmd.edit(vim.fn.fnameescape(source_file))
    local workspace_roots = roots(source, destination)
    local sessions = {}
    assert(switch(sessions, workspace_roots[2], workspace_roots))
    vim.cmd.edit(vim.fn.fnameescape(destination_file))
    assert(switch(sessions, workspace_roots[1], workspace_roots))

    local original = engine.restore
    local calls = 0
    local switch_ok, switch_err
    local protected, err = xpcall(function()
      engine.restore = function(script)
        calls = calls + 1
        if calls == 1 then return false, "injected destination failure" end
        return original(script)
      end
      switch_ok, switch_err = switch(sessions, workspace_roots[2], workspace_roots)
    end, debug.traceback)
    engine.restore = original
    if not protected then error(err) end
    assert(not switch_ok)
    assert(switch_err:match("injected destination failure"))
    h.eq(vim.fs.normalize(assert(vim.uv.fs_realpath(source))), vim.uv.cwd())
    h.eq(2, calls)

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,

  rejects_modified_buffers_when_allow_modified_is_false = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    local source_file = source .. "/source.txt"
    vim.fn.writefile({ "saved" }, source_file)
    vim.cmd.cd(source)
    vim.cmd.edit(vim.fn.fnameescape(source_file))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local workspace_roots = roots(source, destination)
    local sessions = {}
    local ok, err = switch(sessions, workspace_roots[2], workspace_roots, { allow_modified = false })
    assert(not ok)
    assert(err:match("modified file buffers block switching"))

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,

  rejects_unknown_first_visit_policies_clearly = function()
    h.reset_editor()
    local source, destination = h.temp_dir(), h.temp_dir()
    vim.cmd.cd(source)
    local workspace_roots = roots(source, destination)
    local sessions = {}
    local ok, err = switch(sessions, workspace_roots[2], workspace_roots, { first_visit = "unknown" })
    assert(not ok)
    assert(err:match("unsupported first%-visit policy: unknown"))

    h.reset_editor()
    h.cleanup(source)
    h.cleanup(destination)
  end,
}
