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
}
