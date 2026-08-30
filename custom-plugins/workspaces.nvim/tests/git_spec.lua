local h = require("helpers")
local git = require("workspaces.git")

local function await_inspect(path)
  local value
  git.inspect_async(path, function(result) value = result end)
  vim.wait(3000, function() return value ~= nil end)
  return assert(value)
end

return {
  parses_branch_counts_and_upstream = function()
    local status = git.parse_status(table.concat({
      "# branch.oid 1111111",
      "# branch.head feature",
      "# branch.upstream origin/feature",
      "# branch.ab +3 -2",
      "1 M. N... 100644 100644 100644 a a staged.txt",
      "1 .M N... 100644 100644 100644 a a unstaged.txt",
      "? untracked.txt",
      "u UU N... 100644 100644 100644 100644 a a a conflict.txt",
    }, "\n"))
    h.eq("feature", status.branch)
    h.eq({ 1, 1, 1, 1, 3, 2 }, {
      status.staged, status.unstaged, status.untracked,
      status.conflicted, status.ahead, status.behind,
    })
  end,

  parses_detached_head_and_missing_upstream = function()
    local detached = git.parse_status(table.concat({
      "# branch.oid 1111111",
      "# branch.head (detached)",
    }, "\n"))
    h.eq(true, detached.detached)
    h.eq(nil, detached.branch)

    local no_upstream = git.parse_status(table.concat({
      "# branch.oid 1111111",
      "# branch.head main",
    }, "\n"))
    h.eq(nil, no_upstream.ahead)
    h.eq(nil, no_upstream.behind)
  end,

  distinguishes_git_non_git_and_missing_paths = function()
    local repo = h.temp_repo()
    local plain = h.temp_dir()
    h.eq("git", await_inspect(repo).kind)
    h.eq("non_git", await_inspect(plain).kind)
    h.eq("missing", await_inspect(plain .. "/gone").kind)
    h.cleanup(repo)
    h.cleanup(plain)
  end,

  preview_contains_status_and_recent_commit = function()
    local repo = h.temp_repo()
    local output = table.concat(git.preview(repo), "\n")
    assert(output:find("main", 1, true))
    assert(output:find("base", 1, true))
    h.cleanup(repo)
  end,
}
