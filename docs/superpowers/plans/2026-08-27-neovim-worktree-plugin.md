# Neovim Worktree Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an extraction-ready local Neovim plugin that creates, displays, switches, and safely merges Git worktrees while preserving per-worktree file-window sessions during the current Neovim process.

**Architecture:** `custom-plugins/worktrees.nvim/` is a standard Neovim runtime plugin with command registration under `plugin/` and focused Git, session, and picker modules under `lua/worktrees/`. The parent config integrates it through one lazy.nvim spec, installs `fzf-lua` separately, and owns the three mappings. Native `vim.system` executes Git without shell interpolation, and native `:mksession` serializes per-worktree editor state into Lua memory.

**Tech Stack:** Neovim 0.11.6 Lua API, LuaJIT, Git 2.39+, lazy.nvim, fzf-lua, headless Neovim assertions

**Spec:** `docs/superpowers/specs/2026-08-26-neovim-worktree-plugin-design.md`

## Global Constraints

- Create plugin-owned worktrees only at `<main-repository-root>/.worktrees/<simple-name>`.
- Create the branch and worktree with the same name from the invoking worktree's current `HEAD`.
- Reject names containing `/` or `\`; do not silently rewrite names.
- Treat `git worktree list --porcelain` as the complete worktree registry.
- Keep workspace sessions only in Lua memory for the current Neovim process.
- Block switching when any normal file buffer is modified; never save, stash, or discard automatically.
- Close non-file windows instead of restoring terminal, quickfix, help, nvim-tree, or plugin windows.
- Merge only into the branch currently checked out in the main worktree; require clean source and main worktrees.
- Abort an active conflicted merge and retain both source worktree and branch.
- Use argument arrays with `vim.system`; never interpolate user-controlled paths or names into shell commands.
- Add no dependencies beyond separately installed `ibhagwan/fzf-lua`.
- Add no README, Vim help, license, CI, release configuration, or public-package metadata.

## File Structure

```text
custom-plugins/worktrees.nvim/
├── plugin/
│   └── worktrees.lua           Register the three user commands
├── lua/worktrees/
│   ├── init.lua                Public API, fzf-lua picker, orchestration
│   ├── git.lua                 Git process execution and porcelain parsing
│   └── session.lua             In-memory sessions and workspace switching
└── tests/
    ├── minimal_init.lua        Headless runtime-path setup
    ├── helpers.lua             Assertions and temporary Git repositories
    ├── run.lua                 Test runner
    ├── git_spec.lua            Parser, discovery, creation, and status tests
    ├── session_spec.lua        Buffer mapping and session restoration tests
    ├── picker_spec.lua         Row formatting and picker orchestration tests
    └── merge_spec.lua          Merge preflight, success, and abort tests

lua/plugins/worktrees.lua       lazy.nvim dependency, commands, and mappings
```

---

### Task 1: Headless Harness and Git Porcelain Model

**Files:**
- Create: `custom-plugins/worktrees.nvim/tests/minimal_init.lua`
- Create: `custom-plugins/worktrees.nvim/tests/helpers.lua`
- Create: `custom-plugins/worktrees.nvim/tests/run.lua`
- Create: `custom-plugins/worktrees.nvim/tests/git_spec.lua`
- Create: `custom-plugins/worktrees.nvim/lua/worktrees/git.lua`

**Interfaces:**
- Produces: `git.run(args, opts) -> result`, where `result` is `{ ok: boolean, code: integer, stdout: string, stderr: string }`.
- Produces: `git.run_async(args, opts, callback)`, where `callback(result)` receives the same result shape on Neovim's main loop.
- Produces: `git.parse_worktrees(stdout) -> Worktree[]`, where each worktree has `path`, `head`, `branch`, `detached`, `locked`, and `prunable`.
- Produces: `git.parse_status(stdout) -> Status`, where status has `staged`, `unstaged`, `untracked`, `conflicted`, `ahead`, and `behind`.
- Produces: `git.is_clean(status) -> boolean`.
- Consumes: only native Neovim APIs and Git.

- [ ] **Step 1: Create the minimal headless test harness**

`tests/minimal_init.lua` must prepend the plugin root and tests directory without loading the user's config:

```lua
local source = debug.getinfo(1, "S").source:sub(2)
local tests = vim.fs.dirname(source)
local plugin = vim.fs.dirname(tests)
vim.opt.runtimepath:prepend(plugin)
package.path = tests .. "/?.lua;" .. package.path
```

`tests/helpers.lua` must provide deterministic equality and Git helpers:

```lua
local M = {}

function M.eq(expected, actual, message)
  assert(vim.deep_equal(expected, actual), message or vim.inspect({ expected = expected, actual = actual }))
end

function M.git(cwd, args)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout or "")
end

function M.temp_repo()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local init = vim.system({ "git", "init", "-b", "main", root }, { text = true }):wait()
  assert(init.code == 0, init.stderr)
  M.git(root, { "config", "user.email", "tests@example.com" })
  M.git(root, { "config", "user.name", "Worktree Tests" })
  vim.fn.writefile({ "base" }, root .. "/base.txt")
  M.git(root, { "add", "base.txt" })
  M.git(root, { "commit", "-m", "base" })
  return root
end

function M.cleanup(path)
  vim.fn.delete(path, "rf")
end

return M
```

`tests/run.lua` must execute each returned test function, report its name, and fail Neovim on the first assertion:

```lua
for _, suite in ipairs({ "git_spec", "session_spec", "picker_spec", "merge_spec" }) do
  local ok, tests = pcall(require, suite)
  if ok then
    for name, test in pairs(tests) do
      io.write(string.format("%s.%s ... ", suite, name))
      test()
      io.write("ok\n")
    end
  elseif not tostring(tests):match("module '" .. suite .. "' not found") then
    error(tests)
  end
end
```

- [ ] **Step 2: Write failing parser and process tests**

Create `tests/git_spec.lua` with these initial cases:

```lua
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
```

- [ ] **Step 3: Run the tests to verify RED**

Run:

```bash
nvim --headless --clean \
  -u custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  -l custom-plugins/worktrees.nvim/tests/run.lua
```

Expected: failure loading `worktrees.git` or calling `parse_worktrees` because the implementation does not exist.

- [ ] **Step 4: Implement the minimal Git runner and parsers**

In `lua/worktrees/git.lua`:

```lua
local M = {}

local function normalize(result)
  return {
    ok = result.code == 0,
    code = result.code,
    stdout = result.stdout or "",
    stderr = vim.trim(result.stderr or ""),
  }
end

local function command(args, opts)
  local cmd = { "git" }
  if opts and opts.cwd then
    vim.list_extend(cmd, { "-C", opts.cwd })
  end
  vim.list_extend(cmd, args)
  return cmd
end

function M.run(args, opts)
  return normalize(vim.system(command(args, opts), { text = true }):wait())
end

function M.run_async(args, opts, callback)
  vim.system(command(args, opts), { text = true }, function(result)
    vim.schedule(function()
      callback(normalize(result))
    end)
  end)
end

function M.parse_worktrees(stdout)
  local worktrees, current = {}, nil
  for line in (stdout .. "\n"):gmatch("([^\n]*)\n") do
    if line == "" then
      if current then
        table.insert(worktrees, current)
        current = nil
      end
    else
      local key, value = line:match("^(%S+)%s*(.*)$")
      if key == "worktree" then
        current = { path = vim.fs.normalize(value), detached = false }
      elseif current and key == "HEAD" then
        current.head = value
      elseif current and key == "branch" then
        current.branch = value:gsub("^refs/heads/", "")
      elseif current and key == "detached" then
        current.detached = true
      elseif current and key == "locked" then
        current.locked = value ~= "" and value or true
      elseif current and key == "prunable" then
        current.prunable = value ~= "" and value or true
      end
    end
  end
  return worktrees
end

function M.parse_status(stdout)
  local status = { staged = 0, unstaged = 0, untracked = 0, conflicted = 0, ahead = nil, behind = nil }
  for line in stdout:gmatch("[^\n]+") do
    local ahead, behind = line:match("^# branch%.ab %+(%d+) %-(%d+)$")
    if ahead then
      status.ahead, status.behind = tonumber(ahead), tonumber(behind)
    elseif line:sub(1, 2) == "? " then
      status.untracked = status.untracked + 1
    elseif line:sub(1, 2) == "u " then
      status.conflicted = status.conflicted + 1
    elseif line:sub(1, 2) == "1 " or line:sub(1, 2) == "2 " then
      local xy = line:match("^[12] (%S%S)")
      if xy and xy:sub(1, 1) ~= "." then status.staged = status.staged + 1 end
      if xy and xy:sub(2, 2) ~= "." then status.unstaged = status.unstaged + 1 end
    end
  end
  return status
end

function M.is_clean(status)
  return status.staged == 0 and status.unstaged == 0 and status.untracked == 0 and status.conflicted == 0
end

return M
```

The implementation may be refactored for readability, but it must retain these public signatures and porcelain-v2 semantics.

- [ ] **Step 5: Run the focused tests to verify GREEN**

Run the headless command from Step 3.

Expected: all `git_spec` tests print `ok`; absent later suites are skipped.

- [ ] **Step 6: Commit the tested foundation**

```bash
git add custom-plugins/worktrees.nvim/lua/worktrees/git.lua \
  custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  custom-plugins/worktrees.nvim/tests/helpers.lua \
  custom-plugins/worktrees.nvim/tests/run.lua \
  custom-plugins/worktrees.nvim/tests/git_spec.lua
git commit -m "feat(worktrees): parse Git worktree state"
```

---

### Task 2: Repository Discovery, Status, and Worktree Creation

**Files:**
- Modify: `custom-plugins/worktrees.nvim/lua/worktrees/git.lua`
- Modify: `custom-plugins/worktrees.nvim/tests/git_spec.lua`

**Interfaces:**
- Consumes: `git.run`, `git.run_async`, `git.parse_worktrees`, and `git.parse_status` from Task 1.
- Produces: `git.repository(cwd) -> Repository|nil, error`, where `Repository` has `current_root`, `main_root`, `common_dir`, and `worktrees`.
- Produces: `git.status(path) -> Status|nil, error` and `git.status_async(path, callback)`.
- Produces: `git.validate_name(repo, name) -> boolean, error`.
- Produces: `git.create(repo, name, start_root) -> Worktree|nil, error`.

- [ ] **Step 1: Add failing discovery, status, validation, and creation tests**

Extend `tests/git_spec.lua` with temporary-repository cases that:

```lua
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

creates_same_named_branch_and_local_exclusion = function()
  local root = h.temp_repo()
  local repo = assert(git.repository(root))
  local worktree = assert(git.create(repo, "feature-a", root))
  h.eq(root .. "/.worktrees/feature-a", worktree.path)
  h.eq("feature-a", h.git(root, { "-C", worktree.path, "branch", "--show-current" }))
  local exclude = table.concat(vim.fn.readfile(root .. "/.git/info/exclude"), "\n")
  assert(exclude:find("/.worktrees/", 1, true))
  assert(git.create(repo, "feature-b", root))
  local _, occurrences = exclude:gsub("/.worktrees/", "")
  h.eq(1, occurrences)
  h.cleanup(root)
end,

rejects_unsafe_or_existing_names = function()
  local root = h.temp_repo()
  local repo = assert(git.repository(root))
  assert(not git.validate_name(repo, "feature/auth"))
  assert(not git.validate_name(repo, ".."))
  assert(git.create(repo, "taken", root))
  assert(not git.validate_name(assert(git.repository(root)), "taken"))
  h.cleanup(root)
end,
```

Correct the exclusion occurrence assertion to reread `info/exclude` after the second creation, so the test proves idempotency rather than checking stale test data.

Add a subdirectory case (`<root>/packages/app`) and assert `git.repository(subdirectory)` returns the same `main_root` and `current_root` as the main worktree. Also test `git.status(root)` against staged, unstaged, untracked, and configured upstream fixtures using a local bare remote.

- [ ] **Step 2: Run the tests to verify RED**

Run the Task 1 headless command.

Expected: failure with `attempt to call field 'repository' (a nil value)`.

- [ ] **Step 3: Implement repository discovery and status collection**

Use these exact Git commands:

```lua
-- Current root
git.run({ "rev-parse", "--show-toplevel" }, { cwd = cwd })

-- Common directory
git.run({ "rev-parse", "--path-format=absolute", "--git-common-dir" }, { cwd = cwd })

-- Registry
git.run({ "worktree", "list", "--porcelain" }, { cwd = cwd })

-- Status and upstream counts in one parseable stream
git.run({ "status", "--porcelain=v2", "--branch", "--untracked-files=all" }, { cwd = path })
```

`repository()` must choose the registry record whose path equals `rev-parse --show-toplevel` as `current_root`, and the first `git worktree list --porcelain` record as `main_root`. It must still validate that the absolute common directory is `<main_root>/.git`; otherwise return `nil, "bare repositories are not supported"` rather than guessing a filesystem layout.

`status_async()` must invoke `run_async` with the same status arguments and convert command failure to `callback(nil, stderr)`.

- [ ] **Step 4: Implement name validation, exclusion, and creation**

Validation order must be deterministic:

```lua
if type(name) ~= "string" or vim.trim(name) == "" then return false, "worktree name is required" end
if name:find("/", 1, true) or name:find("\\", 1, true) then return false, "worktree name cannot contain path separators" end
local ref = M.run({ "check-ref-format", "--branch", name }, { cwd = repo.main_root })
if not ref.ok then return false, "invalid Git branch name: " .. name end
local branch = M.run({ "show-ref", "--verify", "--quiet", "refs/heads/" .. name }, { cwd = repo.main_root })
if branch.code == 0 then return false, "branch already exists: " .. name end
local destination = vim.fs.joinpath(repo.main_root, ".worktrees", name)
if vim.uv.fs_stat(destination) then return false, "path already exists: " .. destination end
```

`create()` must:

1. validate the name;
2. create `<main_root>/.worktrees` with `vim.fn.mkdir(path, "p")`;
3. read `<common_dir>/info/exclude`, append `/.worktrees/` only if an exact line is absent, and preserve a final newline through `vim.fn.writefile`;
4. run `git worktree add -b <name> <destination> HEAD` with `cwd = start_root`;
5. re-read the porcelain registry and return the record whose canonical path matches the destination.

A failed `git worktree add` must return its stderr and leave the exclusion in place; it must not attempt speculative branch or directory rollback.

- [ ] **Step 5: Run focused and full Git tests**

Run the headless command.

Expected: all parser, discovery, status, validation, exclusion, and creation cases print `ok`.

- [ ] **Step 6: Commit repository operations**

```bash
git add custom-plugins/worktrees.nvim/lua/worktrees/git.lua \
  custom-plugins/worktrees.nvim/tests/git_spec.lua
git commit -m "feat(worktrees): create repository worktrees"
```

---

### Task 3: In-Memory Session Switching

**Files:**
- Create: `custom-plugins/worktrees.nvim/lua/worktrees/session.lua`
- Create: `custom-plugins/worktrees.nvim/tests/session_spec.lua`

**Interfaces:**
- Consumes: `Worktree[]` records from `git.repository()`.
- Produces: `session.owner(path, worktrees) -> Worktree|nil`, using the longest path-boundary match.
- Produces: `session.has_modified_file_buffers() -> boolean, string[]`.
- Produces: `session.capture(root) -> string|nil, error`.
- Produces: `session.restore(script) -> boolean, error`.
- Produces: `session.switch(destination, worktrees) -> boolean, error`.
- Produces: `session.reset()` for deterministic test isolation; this only clears the process-local session table.

- [ ] **Step 1: Write failing ownership and safety tests**

Create `tests/session_spec.lua` with cases that prove nested `.worktrees` ownership uses the longest root, external files have no owner, and modified normal file buffers block switching:

```lua
local h = require("helpers")
local session = require("worktrees.session")

return {
  resolves_nested_worktree_by_longest_root = function()
    local worktrees = {
      { path = "/repo" },
      { path = "/repo/.worktrees/a" },
    }
    h.eq("/repo/.worktrees/a", session.owner("/repo/.worktrees/a/docs/x.md", worktrees).path)
    assert(session.owner("/tmp/external.md", worktrees) == nil)
  end,

  rejects_modified_file_buffers = function()
    vim.cmd("tabonly | only | enew")
    local path = vim.fn.tempname() .. ".md"
    vim.fn.writefile({ "saved" }, path)
    vim.cmd.edit(vim.fn.fnameescape(path))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local modified, names = session.has_modified_file_buffers()
    assert(modified)
    h.eq(vim.fs.normalize(path), names[1])
    vim.cmd("bwipeout!")
  end,
}
```

- [ ] **Step 2: Add failing first-visit and return-session tests**

Use a temporary repository with linked worktree `A`. Build two tabs with normal files and vertical/horizontal splits, plus one help or quickfix window. Assert after `session.switch(A, worktrees)` that:

- cwd equals A;
- non-file windows are absent;
- tab and normal-file split counts match the source layout;
- every source-owned window now points to the same relative path below A;
- a source file absent from A has a destination-named buffer with `vim.bo[buf].modified == false` and no file on disk;
- an external file keeps its absolute path.

Then change A's layout, switch back to main, change main's layout, and switch to A again. Assert A's saved layout and cursor view return instead of cloning main's latest layout.

Add a focused LSP case by replacing `vim.lsp.get_clients` with clients rooted in the source, destination, and an external repository. Each fake client records `stop()` calls. Assert switching stops only the source-owned client, then restore `vim.lsp.get_clients` under `xpcall` cleanup.

- [ ] **Step 3: Add a failing rollback test without test-only production hooks**

Because `session.restore` is an internal module interface used by `session.switch`, temporarily replace that table function in the test:

```lua
local original = session.restore
local calls = 0
session.restore = function(script)
  calls = calls + 1
  if calls == 1 then return false, "injected destination failure" end
  return original(script)
end
local ok, err = session.switch(destination, worktrees)
session.restore = original
assert(not ok)
assert(err:match("injected destination failure"))
h.eq(source_root, vim.uv.cwd())
```

Set up a previously captured destination before injecting the failure so the first `restore` is the destination and the second is rollback to the just-captured source.

Add a capture-cleanup case: save `vim.o.sessionoptions`, call `session.capture()` with a nonexistent root so `:cd` fails, assert capture returns `nil, error`, and assert the original option value is restored. This directly covers the failure path without a test-only hook.

- [ ] **Step 4: Run session tests to verify RED**

Run the common headless command.

Expected: failure loading `worktrees.session`.

- [ ] **Step 5: Implement path ownership and modified-buffer checks**

`owner()` must normalize paths and require either exact equality or a separator boundary; prefix-only matching is incorrect. Sort candidate roots by descending path length before matching.

A normal file buffer is `vim.bo[buf].buftype == ""` with a non-empty name. Inspect all valid buffers, including hidden ones. Return normalized names sorted for deterministic notifications and tests.

- [ ] **Step 6: Implement controlled native session capture**

`capture(root)` must use this failure-safe shape:

```lua
local previous = vim.o.sessionoptions
local file = vim.fn.tempname() .. ".vim"
local ok, result = xpcall(function()
  vim.o.sessionoptions = "curdir,folds,tabpages,winsize"
  vim.cmd.cd(vim.fn.fnameescape(root))
  vim.cmd("silent mksession! " .. vim.fn.fnameescape(file))
  return table.concat(vim.fn.readfile(file), "\n")
end, debug.traceback)
vim.o.sessionoptions = previous
vim.fn.delete(file)
if not ok then return nil, result end
return result
```

Before capture, close windows whose buffer is not a normal named file. Remove tabs left without a normal file window. If no normal file window survives anywhere, retain one ordinary unnamed window so Neovim remains operational; do not serialize plugin buffers.

`restore(script)` executes `vim.api.nvim_exec2(script, {})` under `xpcall` and returns `false, error` instead of raising.

- [ ] **Step 7: Implement first-visit mapping and return restoration**

`switch(destination, worktrees)` must perform this exact order:

1. Verify destination is still present in `worktrees`.
2. Resolve source from `vim.uv.cwd()` with `owner()`.
3. Return success immediately if source and destination paths are equal.
4. Reject modified normal file buffers.
5. Close non-file windows and capture the source session.
6. Store the source script in `sessions[source.path]`.
7. Stop only LSP clients whose normalized `root_dir` is owned by the source worktree.
8. If `sessions[destination.path]` exists, call `M.restore()` with it.
9. Otherwise, preserve current tab/split topology and replace each source-owned window buffer with `vim.fn.bufadd(vim.fs.joinpath(destination.path, relative_path))`; leave external buffers unchanged.
10. Set global cwd to destination.
11. Clamp cursor lines to destination buffer line counts and reapply each window view with `vim.fn.winrestview`.
12. Delete obsolete unmodified source-owned buffers with `nvim_buf_delete`.
13. On any failure after capture, call `M.restore(source_script)` and return an error containing the original failure; include rollback failure text if rollback also fails.

The process-local `sessions` table must remain private. `reset()` clears it by replacing its contents, which supports tests without adding persistent state or a general configuration API.

- [ ] **Step 8: Run session tests to verify GREEN**

Run the common headless command.

Expected: Git and session suites print only `ok`; verify the test process exits rather than hanging on LSP or temporary buffers.

- [ ] **Step 9: Commit switching**

```bash
git add custom-plugins/worktrees.nvim/lua/worktrees/session.lua \
  custom-plugins/worktrees.nvim/tests/session_spec.lua
git commit -m "feat(worktrees): switch in-memory worktree sessions"
```

---

### Task 4: fzf-lua Picker, Public API, and Commands

**Files:**
- Create: `custom-plugins/worktrees.nvim/lua/worktrees/init.lua`
- Create: `custom-plugins/worktrees.nvim/plugin/worktrees.lua`
- Create: `custom-plugins/worktrees.nvim/tests/picker_spec.lua`

**Interfaces:**
- Consumes: `git.repository`, `git.status_async`, `git.create`, and `session.switch`.
- Produces: `worktrees.format_row(worktree, status, active_path) -> string`.
- Produces: `worktrees.create()`, `worktrees.list()`, and the picker support needed by `worktrees.merge()` in Task 5.
- Produces user commands: `:WorktreeCreate`, `:WorktreeList`, and `:WorktreeMerge`.

- [ ] **Step 1: Write failing row-format tests**

Create `tests/picker_spec.lua`:

```lua
local h = require("helpers")
local worktrees = require("worktrees")

return {
  formats_active_status_and_upstream = function()
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
    local wt = { path = "/repo/w", detached = true, locked = "busy", prunable = "stale" }
    local row = worktrees.format_row(wt, nil, "/repo")
    assert(row:find("detached", 1, true))
    assert(row:find("locked", 1, true))
    assert(row:find("prunable", 1, true))
    assert(row:find("ERR", 1, true))
  end,
}
```

Add a command-registration test that sources `plugin/worktrees.lua` and asserts `vim.fn.exists(":WorktreeCreate") == 2` for all three commands.

- [ ] **Step 2: Write failing orchestration tests with module stubs**

Before requiring `worktrees`, assign stubs through `package.loaded["worktrees.git"]`, `package.loaded["worktrees.session"]`, and `package.loaded["fzf-lua"]`. Verify:

- `list()` requests all registry worktrees;
- status calls start for every row before fzf opens;
- one status failure produces an `ERR` row but still opens fzf;
- the selected row is re-resolved by canonical path and passed to `session.switch`;
- `create()` trims the `vim.ui.input` value, calls `git.create`, then calls `session.switch` with the refreshed registry;
- creation success plus switch failure notifies the retained worktree path.

Restore every replaced `package.loaded` and `vim.ui.input` value at test end, including assertion failures via `xpcall`, so suites do not leak mocks.

- [ ] **Step 3: Run picker tests to verify RED**

Run the common headless command.

Expected: failure loading `worktrees.init`.

- [ ] **Step 4: Implement deterministic row formatting and parallel status gathering**

Worktree name is `vim.fs.basename(path)` except the main record, whose display name is `main`. Branch text is the branch name or `(detached)`. Missing upstream values render `↑- ↓-`; status failure replaces the complete metric group with `ERR`.

`list()` must call every `git.status_async` first, decrement a pending counter in each callback, and open `require("fzf-lua").fzf_exec(rows, opts)` only when all callbacks have completed. If the registry is empty, notify and return without opening fzf.

Store `row -> canonical worktree path` in a local lookup for that picker invocation. The default action receives selected rows, resolves the selected path against a freshly fetched repository registry, and rejects stale selections.

- [ ] **Step 5: Implement a shell-free built-in previewer**

Inside `init.lua`, create the previewer with fzf-lua's built-in base rather than `--preview` shell text:

```lua
local function previewer(rows)
  return {
    _ctor = function()
      local preview = require("fzf-lua.previewer.builtin").base:extend()
      function preview:populate_preview_buf(entry)
        local path = rows[entry]
        local status = git.run({ "status", "--short", "--branch" }, { cwd = path })
        local log = git.run({ "log", "-n", "10", "--oneline", "--decorate" }, { cwd = path })
        local lines = vim.split(status.stdout .. "\n" .. log.stdout, "\n", { plain = true })
        local buf = self:get_tmp_buffer()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        self:set_preview_buf(buf)
        self.win:update_preview_title(path)
      end
      return preview
    end,
  }
end
```

Use the exact selected row as the lookup key. Git commands still receive argument arrays and cwd, so paths never enter shell command strings.

- [ ] **Step 6: Implement create orchestration and command registration**

`create()` must call `vim.ui.input({ prompt = "Worktree name: " }, callback)`. Cancellation (`nil`) does nothing. Empty input reaches `git.validate_name` through `git.create` and produces its precise validation error. On success, refresh `git.repository(worktree.path)` and pass the created record plus refreshed registry to `session.switch`.

`plugin/worktrees.lua` must contain only:

```lua
for command, method in pairs({
  WorktreeCreate = "create",
  WorktreeList = "list",
  WorktreeMerge = "merge",
}) do
  vim.api.nvim_create_user_command(command, function()
    require("worktrees")[method]()
  end, {})
end
```

All public operations catch expected `(nil, error)` returns and report through `vim.notify`; do not wrap programming errors in broad silent `pcall` calls.

- [ ] **Step 7: Run picker and command tests to verify GREEN**

Run the common headless command.

Expected: all current suites print `ok`.

- [ ] **Step 8: Commit picker and commands**

```bash
git add custom-plugins/worktrees.nvim/lua/worktrees/init.lua \
  custom-plugins/worktrees.nvim/plugin/worktrees.lua \
  custom-plugins/worktrees.nvim/tests/picker_spec.lua
git commit -m "feat(worktrees): add fzf worktree commands"
```

---

### Task 5: Safe Main-Worktree Merge

**Files:**
- Modify: `custom-plugins/worktrees.nvim/lua/worktrees/git.lua`
- Modify: `custom-plugins/worktrees.nvim/lua/worktrees/init.lua`
- Create: `custom-plugins/worktrees.nvim/tests/merge_spec.lua`

**Interfaces:**
- Consumes: repository/worktree/status APIs from Tasks 1-2 and picker infrastructure from Task 4.
- Produces: `git.merge(repo, source) -> MergeResult`, where `MergeResult` has `ok`, `error`, `aborted`, and optional `abort_error`.
- Completes: `worktrees.merge()` source picker, confirmation, merge execution, notification, and conditional `:checktime`.

- [ ] **Step 1: Write failing merge preflight tests**

Create `tests/merge_spec.lua` using temporary repositories and assert rejection for:

- main worktree selected as source;
- detached source;
- main worktree detached;
- source branch equal to target branch;
- staged, unstaged, untracked, or conflicted changes in source;
- staged, unstaged, untracked, or conflicted changes in main.

Each rejection must assert both `result.ok == false` and a message naming the failed precondition. Record main and source `HEAD` before each rejection and assert neither changes.

- [ ] **Step 2: Write failing merge success and conflict-abort tests**

For success, commit `feature.txt` in source, call `git.merge(repo, source)`, and assert:

```lua
assert(result.ok)
h.eq(source.head_after_commit, h.git(root, { "rev-parse", "HEAD" }))
assert(vim.uv.fs_stat(source.path))
h.eq("feature", h.git(source.path, { "branch", "--show-current" }))
```

For conflict abort, commit competing content to the same file in main and source. After `git.merge`, assert:

```lua
assert(not result.ok)
assert(result.aborted)
h.eq(main_head_before, h.git(root, { "rev-parse", "HEAD" }))
local merge_head = vim.system({ "git", "-C", root, "rev-parse", "-q", "--verify", "MERGE_HEAD" }):wait()
assert(merge_head.code ~= 0)
```

- [ ] **Step 3: Run merge tests to verify RED**

Run the common headless command.

Expected: failure with `attempt to call field 'merge' (a nil value)`.

- [ ] **Step 4: Implement merge preflight and conflict abort**

`git.merge(repo, source)` must:

1. reject `source.path == repo.main_root`;
2. reject missing `source.branch` or `source.detached`;
3. read target with `git symbolic-ref --quiet --short HEAD` in main and reject detached main;
4. reject equal source and target branch names;
5. call `git.status` for source and main and require `git.is_clean` for both;
6. run `git merge <source.branch>` in main without `--ff`, `--no-ff`, checkout, stash, or shell;
7. on failure, run `git rev-parse -q --verify MERGE_HEAD` in main;
8. if and only if `MERGE_HEAD` exists, run `git merge --abort`;
9. return the original merge stderr plus `aborted = true` after successful abort;
10. return `abort_error` and the main path when abort fails.

Do not update or remove the source worktree or branch.

- [ ] **Step 5: Implement merge picker and confirmation**

`worktrees.merge()` must reuse the status-enriched picker rows but exclude the main worktree from selectable sources. Revalidate the selected source against a refreshed registry before confirmation.

Prompt with:

```lua
vim.ui.select({ "Merge", "Cancel" }, {
  prompt = string.format("Merge %s into %s?", source.branch, target_branch),
}, function(choice)
  if choice ~= "Merge" then return end
  -- invoke git.merge and notify
end)
```

Before opening confirmation, reject modified normal Neovim buffers using `session.has_modified_file_buffers()`.

On successful merge, compare `session.owner(vim.uv.cwd(), repo.worktrees).path` to `repo.main_root`; only then execute `vim.cmd("checktime")`. Neovim stays in its current worktree in every merge outcome.

- [ ] **Step 6: Add orchestration tests for confirmation and checktime**

Stub `vim.ui.select` to choose `Cancel` and assert `git.merge` is not called. Stub it to choose `Merge` and assert the selected source is passed once. Spy on `vim.cmd` and assert `checktime` runs only when cwd belongs to main and merge succeeds.

- [ ] **Step 7: Run all plugin tests to verify GREEN**

Run the common headless command.

Expected: parser, creation, session, picker, and merge suites all print `ok`; conflict fixtures leave no `MERGE_HEAD`.

- [ ] **Step 8: Commit merge support**

```bash
git add custom-plugins/worktrees.nvim/lua/worktrees/git.lua \
  custom-plugins/worktrees.nvim/lua/worktrees/init.lua \
  custom-plugins/worktrees.nvim/tests/merge_spec.lua
git commit -m "feat(worktrees): merge clean worktree branches"
```

---

### Task 6: lazy.nvim Integration and End-to-End Verification

**Files:**
- Create: `lua/plugins/worktrees.lua`
- Modify only if required by an observed conflict: `lua/keymaps.lua`
- Modify: `custom-plugins/worktrees.nvim/tests/run.lua`

**Interfaces:**
- Consumes: `require("worktrees").create`, `.list`, and `.merge` from Task 4-5.
- Produces: lazy.nvim local plugin loading, separately declared fzf-lua dependency, command triggers, and accepted mappings.

- [ ] **Step 1: Verify mapping and command names are currently free**

Run:

```bash
grep -RniE 'Worktree(Create|List|Merge)|<leader>w[clm]' lua custom-plugins 2>/dev/null || true
```

Expected before integration: only plugin command registration and tests appear; no existing mapping in `lua/keymaps.lua` conflicts. If a conflict appears, stop and report it rather than silently replacing an existing mapping.

- [ ] **Step 2: Create the local lazy.nvim specification**

Create `lua/plugins/worktrees.lua`:

```lua
return {
  {
    dir = vim.fn.stdpath("config") .. "/custom-plugins/worktrees.nvim",
    name = "worktrees.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    cmd = { "WorktreeCreate", "WorktreeList", "WorktreeMerge" },
    keys = {
      { "<leader>wc", function() require("worktrees").create() end, desc = "Create worktree" },
      { "<leader>wl", function() require("worktrees").list() end, desc = "List worktrees" },
      { "<leader>wm", function() require("worktrees").merge() end, desc = "Merge worktree" },
    },
  },
}
```

Do not duplicate these mappings in `lua/keymaps.lua`. Do not copy fzf-lua under `custom-plugins/`.

- [ ] **Step 3: Make the test runner require every completed suite**

Replace the optional-suite behavior in `tests/run.lua` with an explicit suite list and unconditional `require`:

```lua
for _, suite in ipairs({ "git_spec", "session_spec", "picker_spec", "merge_spec" }) do
  for name, test in pairs(require(suite)) do
    io.write(string.format("%s.%s ... ", suite, name))
    test()
    io.write("ok\n")
  end
end
```

This prevents a deleted or misspelled suite from producing a false green run.

- [ ] **Step 4: Run complete automated verification**

Run:

```bash
nvim --headless --clean \
  -u custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  -l custom-plugins/worktrees.nvim/tests/run.lua

nvim --headless '+Lazy! sync' +qa
nvim --headless \
  '+lua assert(vim.fn.exists(":WorktreeCreate") == 2)' \
  '+lua assert(vim.fn.maparg("<leader>wc", "n") ~= "")' \
  '+lua assert(vim.fn.maparg("<leader>wl", "n") ~= "")' \
  '+lua assert(vim.fn.maparg("<leader>wm", "n") ~= "")' \
  +qa

git diff --check
```

Expected: all test cases print `ok`, lazy.nvim exits zero, all three commands/mappings exist in the real config, and `git diff --check` emits no errors.

- [ ] **Step 5: Perform the manual fzf-lua smoke test in a disposable repository**

Start Neovim in a temporary Git repository, then verify this exact sequence:

1. `<leader>wc`, enter `A`, and confirm cwd becomes `<repo>/.worktrees/A`.
2. Open two files in splits and another file in a second tab.
3. `<leader>wl` and confirm main plus A rows show branch, status counts, upstream placeholders, and paths.
4. Move selection and confirm preview shows `git status --short --branch` and recent commits.
5. Switch to main and confirm relative files map into main while all non-file windows close.
6. Change main's tab layout, switch to A, and confirm A's prior tabs/splits return.
7. Create and save a commit in A, invoke `<leader>wm`, select A, cancel once, then confirm once.
8. Confirm the commit appears on main while A and branch A remain.
9. Create a conflicting pair of commits, invoke merge again, and confirm main returns to its pre-merge `HEAD` with no active `MERGE_HEAD`.
10. Exit Neovim and confirm no session/cache file was created beneath the repository or plugin directory.

Record the commands and observations in the implementation session's final report; do not add a README or permanent smoke-test document.

- [ ] **Step 6: Run focused extraction checks**

Run:

```bash
# Plugin must not import this config's private modules.
grep -RniE 'require\("(icons|utils|autogroups|plugins\.)' custom-plugins/worktrees.nvim && exit 1 || true

# Dependency must remain external.
test ! -d custom-plugins/worktrees.nvim/fzf-lua

git diff --check
git status --short
```

Expected: no parent-private imports, no vendored fzf-lua, no whitespace errors, and only intended integration/plugin files are modified before commit.

- [ ] **Step 7: Commit integration**

```bash
git add lua/plugins/worktrees.lua \
  custom-plugins/worktrees.nvim/tests/run.lua
git commit -m "feat: install local worktree plugin"
```

- [ ] **Step 8: Run final verification from the committed tree**

Repeat Step 4 after the commit, then run:

```bash
git status --short
git log --oneline -6
```

Expected: every automated check passes, the working tree is clean, and the task commits appear in order: Git model, creation, sessions, picker/commands, merge, integration.
