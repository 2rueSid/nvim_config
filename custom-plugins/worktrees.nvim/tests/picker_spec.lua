local h = require("helpers")

local function with_stubs(stubs, test)
  local names = { "worktrees", "worktrees.git", "worktrees.session", "fzf-lua" }
  local saved = {}
  for _, name in ipairs(names) do
    saved[name] = package.loaded[name]
  end
  local input = vim.ui.input
  local notify = vim.notify

  local ok, err = xpcall(function()
    package.loaded["worktrees"] = nil
    package.loaded["worktrees.git"] = stubs.git
    package.loaded["worktrees.session"] = stubs.session
    package.loaded["fzf-lua"] = stubs.fzf
    test(require("worktrees"))
  end, debug.traceback)

  for _, name in ipairs(names) do
    package.loaded[name] = saved[name]
  end
  vim.ui.input = input
  vim.notify = notify
  if not ok then error(err, 0) end
end

return {
  formats_active_status_and_upstream = function()
    local worktrees = require("worktrees")
    local row = worktrees.format_row(
      { path = "/repo", branch = "main", detached = false },
      { staged = 1, unstaged = 2, untracked = 3, conflicted = 0, ahead = 4, behind = 5 },
      "/repo"
    )
    assert(row:match("^●"))
    assert(row:find("main", 1, true))
    assert(row:find("S:1 U:2 ?:3 ↑4 ↓5", 1, true))
    assert(row:find("/repo", 1, true))
  end,

  labels_detached_locked_prunable_and_errors = function()
    local worktrees = require("worktrees")
    local wt = { path = "/repo/w", detached = true, locked = "busy", prunable = "stale" }
    local row = worktrees.format_row(wt, nil, "/repo")
    assert(row:find("detached", 1, true))
    assert(row:find("locked", 1, true))
    assert(row:find("prunable", 1, true))
    assert(row:find("ERR", 1, true))
  end,

  registers_commands = function()
    local source = debug.getinfo(1, "S").source:sub(2)
    local plugin = vim.fs.dirname(vim.fs.dirname(source))
    dofile(plugin .. "/plugin/worktrees.lua")
    for _, command in ipairs({ "WorktreeCreate", "WorktreeList", "WorktreeMerge" }) do
      h.eq(2, vim.fn.exists(":" .. command))
    end
  end,

  gathers_all_statuses_before_opening_and_switches_fresh_selection = function()
    local callbacks = {}
    local picker
    local switched
    local repository_calls = 0
    local worktree_rows = {
      { path = "/repo", branch = "main" },
      { path = "/repo/w", branch = "w" },
    }
    with_stubs({
      git = {
        repository = function(cwd)
          repository_calls = repository_calls + 1
          if repository_calls == 1 then
            return { current_root = "/repo", main_root = "/repo", worktrees = worktree_rows }
          end
          h.eq("/repo/w", cwd)
          return {
            current_root = "/repo/w",
            main_root = "/repo",
            worktrees = {
              { path = "/repo", branch = "main" },
              { path = "/repo/w/../w", branch = "w" },
            },
          }
        end,
        status_async = function(path, callback)
          callbacks[path] = callback
        end,
        run = function() return { stdout = "", stderr = "" } end,
      },
      session = {
        switch = function(worktree, registry)
          switched = { worktree = worktree, registry = registry }
          return true
        end,
      },
      fzf = {
        fzf_exec = function(rows, opts)
          assert(#callbacks == 0)
          assert(opts.previewer, "native Lua previewer must use opts.previewer")
          assert(opts.preview == nil, "opts.preview is for shell preview specs")
          picker = { rows = rows, opts = opts }
        end,
      },
    }, function(worktrees)
      worktrees.list()
      h.eq(2, vim.tbl_count(callbacks))
      assert(picker == nil)
      callbacks["/repo"]({ staged = 0, unstaged = 0, untracked = 0, ahead = nil, behind = nil })
      assert(picker == nil)
      callbacks["/repo/w"](nil, "status failed")
      assert(picker)
      h.eq(2, #picker.rows)
      local error_row
      for _, row in ipairs(picker.rows) do
        if row:find("ERR", 1, true) then error_row = row end
      end
      assert(error_row)
      picker.opts.actions.default({ error_row })
      h.eq("/repo/w/../w", switched.worktree.path)
      h.eq(2, #switched.registry)
    end)
  end,

  create_trims_name_refreshes_and_switches = function()
    local created
    local switched
    local repositories = 0
    with_stubs({
      git = {
        repository = function(cwd)
          repositories = repositories + 1
          if repositories == 1 then
            return { current_root = "/repo/w", main_root = "/repo", worktrees = {} }
          end
          h.eq("/repo/.worktrees/new", cwd)
          return { worktrees = { { path = "/repo/.worktrees/new", branch = "new" } } }
        end,
        create = function(repo, name, start_root)
          created = { repo = repo, name = name, start_root = start_root }
          return { path = "/repo/.worktrees/new", branch = "new" }
        end,
      },
      session = {
        switch = function(worktree, registry)
          switched = { worktree = worktree, registry = registry }
          return true
        end,
      },
      fzf = {},
    }, function(worktrees)
      vim.ui.input = function(opts, callback)
        h.eq("Worktree name: ", opts.prompt)
        callback("  new  ")
      end
      worktrees.create()
      h.eq("new", created.name)
      h.eq("/repo/w", created.start_root)
      h.eq("/repo/.worktrees/new", switched.worktree.path)
      h.eq(1, #switched.registry)
    end)
  end,

  reports_selected_path_when_list_switch_fails = function()
    local callbacks = {}
    local picker
    local notifications = {}
    with_stubs({
      git = {
        repository = function(cwd)
          if cwd == "/repo/w" then
            return { current_root = "/repo/w", main_root = "/repo", worktrees = { { path = "/repo" }, { path = "/repo/w" } } }
          end
          return { current_root = "/repo", main_root = "/repo", worktrees = { { path = "/repo" }, { path = "/repo/w" } } }
        end,
        status_async = function(path, callback) callbacks[path] = callback end,
        run = function() return { stdout = "", stderr = "" } end,
      },
      session = {
        switch = function() return false, "modified buffers" end,
      },
      fzf = {
        fzf_exec = function(rows, opts) picker = { rows = rows, opts = opts } end,
      },
    }, function(worktrees)
      vim.notify = function(message) table.insert(notifications, message) end
      worktrees.list()
      callbacks["/repo"]({ staged = 0, unstaged = 0, untracked = 0 })
      callbacks["/repo/w"]({ staged = 0, unstaged = 0, untracked = 0 })
      local selected = picker.rows[2]
      picker.opts.actions.default({ selected })
      assert(notifications[1]:find("modified buffers", 1, true))
      assert(notifications[1]:find("/repo/w", 1, true))
    end)
  end,

  reports_retained_path_when_created_worktree_cannot_switch = function()
    local notifications = {}
    with_stubs({
      git = {
        repository = function(cwd)
          if cwd == "/repo/.worktrees/new" then
            return { worktrees = { { path = cwd, branch = "new" } } }
          end
          return { current_root = "/repo", main_root = "/repo", worktrees = {} }
        end,
        create = function()
          return { path = "/repo/.worktrees/new", branch = "new" }
        end,
      },
      session = {
        switch = function() return false, "modified buffers" end,
      },
      fzf = {},
    }, function(worktrees)
      vim.notify = function(message) table.insert(notifications, message) end
      vim.ui.input = function(_, callback) callback("new") end
      worktrees.create()
      assert(notifications[1]:find("/repo/.worktrees/new", 1, true))
      assert(notifications[1]:find("modified buffers", 1, true))
    end)
  end,
}
