local h = require("helpers")
local git = require("worktrees.git")

return {
  parses_worktree_porcelain = function()
    local rows = git.parse_worktrees(table.concat({
      "worktree /repo",
      "HEAD 1111111",
      "branch refs/heads/main",
      "",
      "worktree /repo/.worktrees/a",
      "HEAD 2222222",
      "detached",
      "locked editor",
      "prunable stale metadata",
      "",
    }, "\n"))
    h.eq(2, #rows)
    h.eq({
      path = "/repo/.worktrees/a",
      head = "2222222",
      branch = nil,
      detached = true,
      locked = "editor",
      prunable = "stale metadata",
    }, rows[2])
  end,

  parses_status_counts = function()
    local status = git.parse_status(table.concat({
      "# branch.oid 1111111",
      "# branch.head feature",
      "# branch.upstream origin/feature",
      "# branch.ab +3 -2",
      "1 M. N... 100644 100644 100644 a a staged.txt",
      "1 .M N... 100644 100644 100644 a a unstaged.txt",
      "1 MM N... 100644 100644 100644 a a both.txt",
      "? untracked.txt",
      "u UU N... 100644 100644 100644 100644 a a a conflict.txt",
    }, "\n"))
    h.eq({ staged = 2, unstaged = 2, untracked = 1, conflicted = 1, ahead = 3, behind = 2 }, status)
    assert(not git.is_clean(status))
  end,

  runs_git_without_a_shell = function()
    local result = git.run({ "--version" })
    assert(result.ok)
    assert(result.stdout:match("git version"))
  end,

  repository_discovers_main_from_linked_worktree = function()
    local root = h.temp_repo()
    local linked = root .. "/outside-linked"
    h.git(root, { "worktree", "add", "-b", "linked", linked })
    local repo = assert(git.repository(linked))
    h.eq(vim.fs.normalize(root), repo.main_root)
    h.eq(vim.fs.normalize(linked), repo.current_root)
    h.eq(vim.fs.normalize(root .. "/.git"), repo.common_dir)
    h.cleanup(linked)
    h.cleanup(root)
  end,

  repository_discovers_from_subdirectory = function()
    local root = h.temp_repo()
    local subdirectory = root .. "/packages/app"
    vim.fn.mkdir(subdirectory, "p")
    local repo = assert(git.repository(subdirectory))
    h.eq(vim.fs.normalize(root), repo.main_root)
    h.eq(vim.fs.normalize(root), repo.current_root)
    h.cleanup(root)
  end,

  status_collects_changes_and_upstream_counts = function()
    local root = h.temp_repo()
    local remote = vim.fn.tempname()
    vim.fn.mkdir(remote, "p")
    local init = vim.system({ "git", "init", "--bare", remote }, { text = true }):wait()
    assert(init.code == 0, init.stderr)
    h.git(root, { "remote", "add", "origin", remote })
    h.git(root, { "push", "-u", "origin", "main" })
    vim.fn.writefile({ "staged" }, root .. "/staged.txt")
    h.git(root, { "add", "staged.txt" })
    vim.fn.writefile({ "changed" }, root .. "/base.txt")
    vim.fn.writefile({ "untracked" }, root .. "/untracked.txt")
    local status = assert(git.status(root))
    h.eq({ staged = 1, unstaged = 1, untracked = 1, conflicted = 0, ahead = 0, behind = 0 }, status)
    h.git(root, { "commit", "-m", "local" })
    status = assert(git.status(root))
    h.eq(1, status.ahead)
    h.eq(0, status.behind)
    h.cleanup(remote)
    h.cleanup(root)
  end,

  status_async_reports_status = function()
    local root = h.temp_repo()
    local done, status, err = false, nil, nil
    git.status_async(root, function(result, result_err)
      status, err, done = result, result_err, true
    end)
    assert(vim.wait(1000, function() return done end))
    assert(status)
    h.eq(nil, err)
    h.eq(0, status.staged)
    h.eq(0, status.unstaged)
    h.cleanup(root)
  end,

  status_async_reports_command_failure = function()
    local done, status, err = false, nil, nil
    git.status_async(vim.fn.tempname(), function(result, result_err)
      status, err, done = result, result_err, true
    end)
    assert(vim.wait(1000, function() return done end))
    h.eq(nil, status)
    assert(type(err) == "string" and err ~= "")
  end,

  creates_same_named_branch_and_local_exclusion = function()
    local root = h.temp_repo()
    local repo = assert(git.repository(root))
    local worktree = assert(git.create(repo, "feature-a", root))
    h.eq(root .. "/.worktrees/feature-a", worktree.path)
    h.eq("feature-a", h.git(root, { "-C", worktree.path, "branch", "--show-current" }))
    local exclude_path = root .. "/.git/info/exclude"
    local exclude = table.concat(vim.fn.readfile(exclude_path), "\n")
    assert(exclude:find("/.worktrees/", 1, true))
    assert(git.create(repo, "feature-b", root))
    exclude = table.concat(vim.fn.readfile(exclude_path), "\n")
    local _, occurrences = exclude:gsub("/.worktrees/", "")
    h.eq(1, occurrences)
    h.cleanup(root)
  end,

  rejects_unsafe_or_existing_names = function()
    local root = h.temp_repo()
    local repo = assert(git.repository(root))
    local valid, err = git.validate_name(repo, "")
    assert(not valid)
    h.eq("worktree name is required", err)
    valid, err = git.validate_name(repo, "feature/auth")
    assert(not valid)
    h.eq("worktree name cannot contain path separators", err)
    assert(not git.validate_name(repo, ".."))
    assert(git.create(repo, "taken", root))
    valid, err = git.validate_name(assert(git.repository(root)), "taken")
    assert(not valid)
    h.eq("branch already exists: taken", err)
    h.cleanup(root)
  end,
}
