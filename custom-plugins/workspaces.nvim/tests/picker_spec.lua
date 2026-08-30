local h = require("helpers")

local function with_stubs(stubs, test)
  local names = {
    "workspaces", "workspaces.registry", "workspaces.git",
    "workspace_session", "fzf-lua",
  }
  local saved = {}
  for _, name in ipairs(names) do saved[name] = package.loaded[name] end
  local input, notify, autocmds = vim.ui.input, vim.notify, vim.api.nvim_exec_autocmds
  local cwd = vim.uv.cwd()

  local ok, err = xpcall(function()
    package.loaded["workspaces"] = nil
    package.loaded["workspaces.registry"] = stubs.registry
    package.loaded["workspaces.git"] = stubs.git
    package.loaded["workspace_session"] = stubs.session
    package.loaded["fzf-lua"] = stubs.fzf
    test(require("workspaces"))
  end, debug.traceback)

  for _, name in ipairs(names) do package.loaded[name] = saved[name] end
  vim.ui.input, vim.notify = input, notify
  vim.api.nvim_exec_autocmds = autocmds
  if cwd then vim.cmd.cd(vim.fn.fnameescape(cwd)) end
  if not ok then error(err, 0) end
end

return {
  formats_git_status_and_active_workspace = function()
    local workspaces = require("workspaces")
    local row = workspaces.format_row(
      { label = "API", path = "/code/api" },
      { kind = "git", status = {
        branch = "main", staged = 1, unstaged = 2, untracked = 3,
        ahead = 4, behind = 5,
      } },
      "/code/api"
    )
    assert(row:match("^●"))
    assert(row:find("API", 1, true))
    assert(row:find("main", 1, true))
    assert(row:find("S:1 U:2 ?:3 ↑4 ↓5", 1, true))
    assert(row:find("/code/api", 1, true))
  end,

  formats_non_git_missing_and_error_states = function()
    local workspaces = require("workspaces")
    assert(workspaces.format_row({ label = "plain", path = "/code/plain" }, { kind = "non_git" }, nil):find("—", 1, true))
    assert(workspaces.format_row({ label = "gone", path = "/code/gone" }, { kind = "missing" }, nil):find("[missing]", 1, true))
    assert(workspaces.format_row({ label = "broken", path = "/code/broken" }, { kind = "error" }, nil):find("ERR", 1, true))
  end,

  registers_commands = function()
    local source = debug.getinfo(1, "S").source:sub(2)
    local plugin = vim.fs.dirname(vim.fs.dirname(source))
    dofile(plugin .. "/plugin/workspaces.lua")
    for _, command in ipairs({ "WorkspaceAdd", "WorkspaceList", "WorkspaceDelete" }) do
      h.eq(2, vim.fn.exists(":" .. command))
    end
  end,

  prompts_and_trims_add_label = function()
    local root = h.temp_dir()
    local added
    with_stubs({
      registry = { add = function(label, path) added = { label = label, path = path }; return {} end },
      git = {}, session = {}, fzf = {},
    }, function(workspaces)
      vim.cmd.cd(root)
      vim.ui.input = function(opts, callback)
        h.eq("Workspace label: ", opts.prompt)
        callback("  API  ")
      end
      workspaces.add()
      h.eq({ label = "API", path = vim.uv.cwd() }, added)
    end)
    h.cleanup(root)
  end,

  reports_add_and_delete_failures_without_raising = function()
    local root = h.temp_dir()
    local messages = {}
    with_stubs({
      registry = {
        add = function() return nil, "duplicate" end,
        remove = function() return nil, "not registered" end,
      },
      git = {}, session = {}, fzf = {},
    }, function(workspaces)
      vim.cmd.cd(root)
      vim.notify = function(message) table.insert(messages, message) end
      vim.ui.input = function(_, callback) callback("new") end
      workspaces.add()
      workspaces.delete()
      assert(messages[1]:find("duplicate", 1, true))
      assert(messages[2]:find("not registered", 1, true))
    end)
    h.cleanup(root)
  end,

  waits_for_all_live_metadata_before_opening_picker = function()
    local callbacks, picker = {}, nil
    local records = {
      { label = "same", path = "/repo/git" },
      { label = "same", path = "/repo/plain" },
      { label = "gone", path = "/repo/gone" },
    }
    with_stubs({
      registry = { load = function() return records end },
      git = { inspect_async = function(path, callback) callbacks[path] = callback end },
      session = {},
      fzf = { fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end },
    }, function(workspaces)
      workspaces.list()
      h.eq(3, vim.tbl_count(callbacks))
      assert(picker == nil)
      callbacks[records[1].path]({ kind = "git", status = { branch = "main" } })
      callbacks[records[2].path]({ kind = "non_git" })
      assert(picker == nil)
      callbacks[records[3].path]({ kind = "missing" })
      assert(picker and #picker.rows == 3)
      assert(picker.opts.previewer and picker.opts.preview == nil)
      for _, record in ipairs(records) do
        local found = false
        for _, row in ipairs(picker.rows) do
          if row:find(record.path, 1, true) then found = true end
        end
        assert(found, record.path .. " missing from picker")
      end
    end)
  end,

  ignores_stale_async_callbacks_from_an_older_picker = function()
    local callbacks, picker, call = {}, nil, 0
    local records = {
      { label = "one", path = "/repo/one" },
      { label = "two", path = "/repo/two" },
    }
    with_stubs({
      registry = { load = function() return records end },
      git = {
        inspect_async = function(path, callback)
          call = call + 1
          callbacks[call] = callback
        end,
      },
      session = {},
      fzf = { fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end },
    }, function(workspaces)
      workspaces.list()
      workspaces.list()
      h.eq(4, call)
      callbacks[1]({ kind = "git", status = {} })
      callbacks[2]({ kind = "git", status = {} })
      assert(picker == nil)
      callbacks[3]({ kind = "git", status = {} })
      callbacks[4]({ kind = "git", status = {} })
      assert(picker and #picker.rows == 2)
    end)
  end,

  rejects_missing_selection_and_removes_it_with_ctrl_d = function()
    local callbacks, picker, removed, switched, messages = {}, nil, nil, false, {}
    local record = { label = "gone", path = "/repo/gone" }
    with_stubs({
      registry = { load = function() return { record } end, remove = function(path) removed = path; return {} end },
      git = { inspect_async = function(path, callback) callbacks[path] = callback end },
      session = { switch = function() switched = true end },
      fzf = { fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end },
    }, function(workspaces)
      vim.notify = function(message) table.insert(messages, message) end
      workspaces.list()
      callbacks[record.path]({ kind = "missing" })
      local row = picker.rows[1]
      picker.opts.actions.default({ row })
      assert(not switched)
      assert(messages[1]:find("missing", 1, true))
      picker.opts.actions["ctrl-d"]({ row })
      h.eq(record.path, removed)
    end)
  end,

  switches_refreshed_record_and_emits_only_after_success = function()
    local callbacks, picker, switched, event
    local old = { label = "Destination", path = "/repo/destination" }
    local fresh = { label = "Destination", path = "/repo/destination/." }
    local registries = { { { label = "Source", path = "/source" }, old }, { { label = "Source", path = "/source" }, fresh } }
    with_stubs({
      registry = { load = function() local result = table.remove(registries, 1); return result end },
      git = { inspect_async = function(path, callback) callbacks[path] = callback end },
      session = {
        owner = function() return { label = "Source", path = "/source" } end,
        switch = function(sessions, destination, roots, opts)
          switched = { destination = destination, roots = roots, opts = opts }
          return true
        end,
      },
      fzf = { fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end },
    }, function(workspaces)
      vim.api.nvim_exec_autocmds = function(_, opts) event = opts end
      callbacks = {}
      workspaces.list()
      callbacks[old.path]({ kind = "git", status = {} })
      callbacks["/source"]({ kind = "git", status = {} })
      picker.opts.actions.default({ picker.rows[2] })
      assert(switched and switched.destination == fresh)
      h.eq({ require_source = false, allow_modified = true, first_visit = "clean" }, switched.opts)
      h.eq({ pattern = "WorkspaceChanged", data = { from = "/source", to = fresh.path } }, event)
    end)
  end,

  failed_and_current_switches_emit_no_event = function()
    local callbacks, picker, events = {}, nil, {}
    local source = { label = "Source", path = "/source" }
    local destination = { label = "Destination", path = "/destination" }
    local records = { source, destination }
    with_stubs({
      registry = { load = function() return records end },
      git = { inspect_async = function(path, callback) callbacks[path] = callback end },
      session = { switch = function() return false, "blocked" end },
      fzf = { fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end },
    }, function(workspaces)
      vim.notify = function() end
      vim.api.nvim_exec_autocmds = function(_, opts) table.insert(events, opts) end
      workspaces.list()
      callbacks[source.path]({ kind = "git", status = {} })
      callbacks[destination.path]({ kind = "git", status = {} })
      picker.opts.actions.default({ picker.rows[2] })
      h.eq({}, events)
    end)

    callbacks, picker = {}, nil
    local current = vim.uv.cwd()
    local current_record = { label = "Current", path = current }
    with_stubs({
      registry = { load = function() return { current_record } end },
      git = { inspect_async = function(path, callback) callbacks[path] = callback end },
      session = { switch = function() error("must not switch") end },
      fzf = { fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end },
    }, function(workspaces)
      vim.api.nvim_exec_autocmds = function(_, opts) table.insert(events, opts) end
      workspaces.list()
      callbacks[current]({ kind = "git", status = {} })
      picker.opts.actions.default({ picker.rows[1] })
      h.eq({}, events)
    end)
  end,
}
