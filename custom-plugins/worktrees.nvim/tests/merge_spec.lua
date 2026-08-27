local h = require("helpers")
local git = require("worktrees.git")

local function fixture(test)
  local root = h.temp_repo()
  vim.fn.writefile({ "base" }, root .. "/conflict.txt")
  h.git(root, { "add", "conflict.txt" })
  h.git(root, { "commit", "-m", "conflict base" })
  vim.fn.writefile({ "/.worktrees/" }, root .. "/.git/info/exclude", "a")
  local linked = root .. "/.worktrees/feature"
  h.git(root, { "worktree", "add", "-b", "feature", linked })
  local repo = assert(git.repository(root))
  local source
  for _, worktree in ipairs(repo.worktrees) do
    if worktree.path ~= repo.main_root then source = worktree end
  end
  assert(source)

  local ok, err = xpcall(function()
    test({ root = repo.main_root, linked = source.path, repo = repo, source = source })
  end, debug.traceback)
  h.cleanup(root)
  if not ok then error(err, 0) end
end

local function heads(fx)
  return h.git(fx.root, { "rev-parse", "HEAD" }), h.git(fx.linked, { "rev-parse", "HEAD" })
end

local function rejects_without_moving_heads(fx, source, message)
  local main_before, source_before = heads(fx)
  local result = git.merge(fx.repo, source or fx.source)
  assert(not result.ok)
  assert(result.error:lower():find(message, 1, true), result.error)
  local main_after, source_after = heads(fx)
  h.eq(main_before, main_after)
  h.eq(source_before, source_after)
end

local function make_adversary(root, content)
  h.git(root, { "checkout", "-b", "adversary" })
  vim.fn.writefile({ content }, root .. "/conflict.txt")
  h.git(root, { "add", "conflict.txt" })
  h.git(root, { "commit", "-m", "adversary" })
  h.git(root, { "checkout", "main" })
end

local function with_orchestration_stubs(options, test)
  local names = { "worktrees", "worktrees.git", "worktrees.session", "fzf-lua" }
  local saved = {}
  for _, name in ipairs(names) do saved[name] = package.loaded[name] end
  local select, notify, cmd = vim.ui.select, vim.notify, vim.cmd

  local source = { path = "/repo/.worktrees/feature", branch = "feature", detached = false }
  local registry = { { path = "/repo", branch = "main" }, source }
  local merge_calls, checktime_calls = 0, 0
  local git_stub = {
    repository = function()
      return { current_root = options.current_root or "/repo", main_root = "/repo", worktrees = registry }
    end,
    status_async = function(_, callback)
      callback({ staged = 0, unstaged = 0, untracked = 0, conflicted = 0 })
    end,
    run = function(args)
      if args[1] == "symbolic-ref" then return { ok = true, stdout = "main\n", stderr = "" } end
      return { ok = true, stdout = "", stderr = "" }
    end,
    merge = function(_, selected)
      merge_calls = merge_calls + 1
      h.eq(source, selected)
      return options.merge_result or { ok = true, aborted = false }
    end,
  }
  local session_stub = {
    has_modified_file_buffers = function() return options.modified or false, { "/repo/changed.txt" } end,
    owner = function() return { path = options.owner_path or "/repo" } end,
  }
  local fzf_stub = {
    fzf_exec = function(rows, opts)
      h.eq(1, #rows)
      opts.actions.default({ rows[1] })
    end,
  }

  local ok, err = xpcall(function()
    package.loaded["worktrees"] = nil
    package.loaded["worktrees.git"] = git_stub
    package.loaded["worktrees.session"] = session_stub
    package.loaded["fzf-lua"] = fzf_stub
    vim.ui.select = function(choices, opts, callback)
      h.eq({ "Merge", "Cancel" }, choices)
      h.eq("Merge feature into main?", opts.prompt)
      callback(options.choice)
    end
    vim.notify = function() end
    vim.cmd = function(command)
      h.eq("checktime", command)
      checktime_calls = checktime_calls + 1
    end
    test(require("worktrees"), function() return merge_calls, checktime_calls end)
  end, debug.traceback)

  for _, name in ipairs(names) do package.loaded[name] = saved[name] end
  vim.ui.select, vim.notify, vim.cmd = select, notify, cmd
  if not ok then error(err, 0) end
end

return {
  rejects_main_as_source = function()
    fixture(function(fx)
      rejects_without_moving_heads(fx, fx.repo.worktrees[1], "main worktree")
    end)
  end,

  rejects_detached_source = function()
    fixture(function(fx)
      h.git(fx.linked, { "checkout", "--detach" })
      local refreshed = assert(git.repository(fx.root))
      local source
      for _, worktree in ipairs(refreshed.worktrees) do
        if worktree.path ~= refreshed.main_root then source = worktree end
      end
      fx.repo = refreshed
      rejects_without_moving_heads(fx, source, "source worktree is detached")
    end)
  end,

  rejects_detached_main = function()
    fixture(function(fx)
      h.git(fx.root, { "checkout", "--detach" })
      rejects_without_moving_heads(fx, nil, "main worktree is detached")
    end)
  end,

  rejects_equal_source_and_target_branches = function()
    fixture(function(fx)
      rejects_without_moving_heads(fx, { path = fx.linked, branch = "main", detached = false }, "branches must differ")
    end)
  end,

  rejects_staged_source = function()
    fixture(function(fx)
      vim.fn.writefile({ "staged" }, fx.linked .. "/base.txt")
      h.git(fx.linked, { "add", "base.txt" })
      rejects_without_moving_heads(fx, nil, "source worktree must be clean")
    end)
  end,

  rejects_unstaged_source = function()
    fixture(function(fx)
      vim.fn.writefile({ "unstaged" }, fx.linked .. "/base.txt")
      rejects_without_moving_heads(fx, nil, "source worktree must be clean")
    end)
  end,

  rejects_untracked_source = function()
    fixture(function(fx)
      vim.fn.writefile({ "untracked" }, fx.linked .. "/new.txt")
      rejects_without_moving_heads(fx, nil, "source worktree must be clean")
    end)
  end,

  rejects_conflicted_source = function()
    fixture(function(fx)
      make_adversary(fx.root, "main side")
      vim.fn.writefile({ "source side" }, fx.linked .. "/conflict.txt")
      h.git(fx.linked, { "add", "conflict.txt" })
      h.git(fx.linked, { "commit", "-m", "source side" })
      local conflict = vim.system({ "git", "-C", fx.linked, "merge", "adversary" }, { text = true }):wait()
      assert(conflict.code ~= 0)
      rejects_without_moving_heads(fx, nil, "source worktree must be clean")
    end)
  end,

  rejects_staged_main = function()
    fixture(function(fx)
      vim.fn.writefile({ "staged" }, fx.root .. "/base.txt")
      h.git(fx.root, { "add", "base.txt" })
      rejects_without_moving_heads(fx, nil, "main worktree must be clean")
    end)
  end,

  rejects_unstaged_main = function()
    fixture(function(fx)
      vim.fn.writefile({ "unstaged" }, fx.root .. "/base.txt")
      rejects_without_moving_heads(fx, nil, "main worktree must be clean")
    end)
  end,

  rejects_untracked_main = function()
    fixture(function(fx)
      vim.fn.writefile({ "untracked" }, fx.root .. "/new.txt")
      rejects_without_moving_heads(fx, nil, "main worktree must be clean")
    end)
  end,

  rejects_conflicted_main = function()
    fixture(function(fx)
      vim.fn.writefile({ "source side" }, fx.linked .. "/conflict.txt")
      h.git(fx.linked, { "add", "conflict.txt" })
      h.git(fx.linked, { "commit", "-m", "source side" })
      vim.fn.writefile({ "main side" }, fx.root .. "/conflict.txt")
      h.git(fx.root, { "add", "conflict.txt" })
      h.git(fx.root, { "commit", "-m", "main side" })
      local conflict = vim.system({ "git", "-C", fx.root, "merge", "feature" }, { text = true }):wait()
      assert(conflict.code ~= 0)
      rejects_without_moving_heads(fx, nil, "main worktree must be clean")
    end)
  end,

  merges_source_branch_without_removing_it = function()
    fixture(function(fx)
      vim.fn.writefile({ "feature" }, fx.linked .. "/feature.txt")
      h.git(fx.linked, { "add", "feature.txt" })
      h.git(fx.linked, { "commit", "-m", "feature" })
      fx.source.head_after_commit = h.git(fx.linked, { "rev-parse", "HEAD" })

      local result = git.merge(fx.repo, fx.source)

      assert(result.ok)
      h.eq(fx.source.head_after_commit, h.git(fx.root, { "rev-parse", "HEAD" }))
      assert(vim.uv.fs_stat(fx.source.path))
      h.eq("feature", h.git(fx.source.path, { "branch", "--show-current" }))
    end)
  end,

  aborts_a_conflicting_merge = function()
    fixture(function(fx)
      vim.fn.writefile({ "source side" }, fx.linked .. "/conflict.txt")
      h.git(fx.linked, { "add", "conflict.txt" })
      h.git(fx.linked, { "commit", "-m", "source side" })
      vim.fn.writefile({ "main side" }, fx.root .. "/conflict.txt")
      h.git(fx.root, { "add", "conflict.txt" })
      h.git(fx.root, { "commit", "-m", "main side" })
      local main_head_before = h.git(fx.root, { "rev-parse", "HEAD" })

      local result = git.merge(fx.repo, fx.source)

      assert(not result.ok)
      assert(result.aborted)
      h.eq(main_head_before, h.git(fx.root, { "rev-parse", "HEAD" }))
      local merge_head = vim.system({ "git", "-C", fx.root, "rev-parse", "-q", "--verify", "MERGE_HEAD" }):wait()
      assert(merge_head.code ~= 0)
    end)
  end,

  cancel_does_not_merge = function()
    with_orchestration_stubs({ choice = "Cancel" }, function(worktrees, calls)
      worktrees.merge()
      local merge_calls, checktime_calls = calls()
      h.eq(0, merge_calls)
      h.eq(0, checktime_calls)
    end)
  end,

  confirmation_merges_selected_source_once = function()
    with_orchestration_stubs({ choice = "Merge", owner_path = "/repo/.worktrees/feature" }, function(worktrees, calls)
      worktrees.merge()
      local merge_calls, checktime_calls = calls()
      h.eq(1, merge_calls)
      h.eq(0, checktime_calls)
    end)
  end,

  checktime_runs_only_for_success_in_main = function()
    for _, case in ipairs({
      { result = { ok = true }, owner = "/repo", expected = 1 },
      { result = { ok = true }, owner = "/repo/.worktrees/feature", expected = 0 },
      { result = { ok = false, error = "failed" }, owner = "/repo", expected = 0 },
    }) do
      with_orchestration_stubs({ choice = "Merge", owner_path = case.owner, merge_result = case.result }, function(worktrees, calls)
        worktrees.merge()
        local merge_calls, checktime_calls = calls()
        h.eq(1, merge_calls)
        h.eq(case.expected, checktime_calls)
      end)
    end
  end,

  modified_buffers_block_confirmation = function()
    with_orchestration_stubs({ choice = "Merge", modified = true }, function(worktrees, calls)
      local prompted = false
      vim.ui.select = function() prompted = true end
      worktrees.merge()
      local merge_calls, checktime_calls = calls()
      assert(not prompted)
      h.eq(0, merge_calls)
      h.eq(0, checktime_calls)
    end)
  end,
}
