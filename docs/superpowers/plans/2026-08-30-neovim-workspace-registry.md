# Neovim Workspace Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a persistent labeled workspace registry with an fzf-lua picker and safe in-process workspace switching while preserving existing worktree behavior through a shared session engine.

**Architecture:** Extract the mechanical session code from `worktrees.nvim` into an internal `workspace-session.nvim` runtime module whose state remains consumer-owned. Build `workspaces.nvim` around an atomic JSON registry, live asynchronous Git metadata, and fzf-lua orchestration; retain `worktrees.session` as a compatibility adapter with its current policies.

**Tech Stack:** Neovim 0.11.6 Lua API, LuaJIT, `vim.system`, native `:mksession`, native `vim.json`, libuv filesystem APIs, Git 2.39+, lazy.nvim, fzf-lua, headless Neovim assertions

**Spec:** `docs/superpowers/specs/2026-08-30-neovim-workspace-registry-design.md`

## Global Constraints

- Store registrations at `vim.fn.stdpath("data") .. "/workspaces.nvim/registry.json"`.
- Store only `{ label, path }` records; add no IDs, timestamps, status cache, SQLite, or migration framework.
- Register Neovim's exact canonical cwd, not its Git root.
- Canonical paths are unique; labels may repeat.
- Support Git, non-Git, and missing registered directories.
- Keep buffer/layout sessions only in memory for the current Neovim process.
- Preserve modified workspace buffers without saving or discarding them.
- Keep current `worktrees.nvim` behavior: modified buffers block switching and first visits map relative paths.
- Execute Git with argument arrays through `vim.system`; never interpolate paths into shell strings.
- Use fzf-lua as the only picker.
- Do not reload lazy.nvim plugins; emit `User WorkspaceChanged` after successful workspace switches.
- Deregistration removes metadata only and never deletes a directory or buffer.
- Simultaneous writes from multiple Neovim processes remain unsupported.
- Add no third-party dependency beyond the already installed fzf-lua.
- Any delegated implementation or review must use only models from the `openai-codex/*` provider; never use `openai/*`, OpenRouter, or any other provider.

## File Structure

```text
custom-plugins/
├── workspace-session.nvim/
│   └── lua/workspace_session/init.lua       Shared capture/restore/switch engine
├── workspaces.nvim/
│   ├── plugin/workspaces.lua                Register three user commands
│   ├── lua/workspaces/init.lua              Public API, picker, switching orchestration
│   ├── lua/workspaces/registry.lua          JSON validation and atomic mutations
│   ├── lua/workspaces/git.lua               Git execution, parsing, live metadata
│   └── tests/
│       ├── minimal_init.lua                 Isolated runtime paths
│       ├── helpers.lua                      Assertions and editor/filesystem reset
│       ├── run.lua                          Explicit headless suite runner
│       ├── registry_spec.lua                Persistence tests
│       ├── git_spec.lua                     Metadata tests
│       ├── session_spec.lua                 Workspace policy tests
│       └── picker_spec.lua                  Commands and orchestration tests
└── worktrees.nvim/
    ├── lua/worktrees/session.lua            Compatibility adapter
    └── tests/minimal_init.lua               Add shared runtime path

lua/plugins/workspaces.lua                   Local plugin, mappings, dependencies
lua/plugins/worktrees.lua                    Add shared session dependency
```

---

### Task 1: Extract the Shared Session Engine Without Changing Worktree Behavior

**Files:**
- Create: `custom-plugins/workspace-session.nvim/lua/workspace_session/init.lua`
- Modify: `custom-plugins/worktrees.nvim/lua/worktrees/session.lua:1-254`
- Modify: `custom-plugins/worktrees.nvim/tests/minimal_init.lua:1-5`
- Modify: `custom-plugins/worktrees.nvim/tests/session_spec.lua`

**Interfaces:**
- Produces: `workspace_session.owner(path, roots) -> Root|nil`.
- Produces: `workspace_session.has_modified_file_buffers() -> boolean, string[]`.
- Produces: `workspace_session.capture(root) -> string|nil, error`.
- Produces: `workspace_session.restore(script) -> boolean, error`.
- Produces: `workspace_session.switch(sessions, destination, roots, opts) -> boolean, error`, where `sessions` is a consumer-owned `path -> session-script` table.
- Preserves: `worktrees.session.owner`, `.has_modified_file_buffers`, `.capture`, `.restore`, `.switch`, and `.reset` signatures.

- [ ] **Step 1: Make the worktree test harness load the future shared runtime**

Replace `custom-plugins/worktrees.nvim/tests/minimal_init.lua` with:

```lua
local source = debug.getinfo(1, "S").source:sub(2)
local tests = vim.fs.dirname(source)
local plugin = vim.fs.dirname(tests)
local shared = vim.fs.joinpath(vim.fs.dirname(plugin), "workspace-session.nvim")
vim.opt.runtimepath:prepend(shared)
vim.opt.runtimepath:prepend(plugin)
package.path = tests .. "/?.lua;" .. package.path
```

Append this case to `session_spec.lua`:

```lua
shared_engine_is_available = function()
  local engine = require("workspace_session")
  assert(type(engine.owner) == "function")
  assert(type(engine.capture) == "function")
  assert(type(engine.restore) == "function")
  assert(type(engine.switch) == "function")
end,
```

- [ ] **Step 2: Run the worktree suite to verify RED**

Run:

```bash
nvim --headless --clean \
  -u custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  -l custom-plugins/worktrees.nvim/tests/run.lua
```

Expected: the new case fails with `module 'workspace_session' not found`; all earlier cases reached before it remain green.

- [ ] **Step 3: Move mechanical session logic into `workspace_session`**

Start `custom-plugins/workspace-session.nvim/lua/workspace_session/init.lua` from the existing `worktrees.session` implementation. Keep these helpers in the shared module: path normalization and containment, normal-file detection, non-file-window closure, session capture/restore, view capture/clamping, source-buffer discovery, relative first-visit mapping, source LSP shutdown, and obsolete-buffer deletion.

Change switching to receive state and policy explicitly:

```lua
function M.switch(sessions, destination, roots, opts)
  opts = opts or {}
  local require_source = opts.require_source ~= false
  local allow_modified = opts.allow_modified == true
  local first_visit = opts.first_visit or "map"
  local capture = opts.capture or M.capture
  local restore = opts.restore or M.restore

  -- Existing worktree flow uses:
  -- require_source = true
  -- allow_modified = false
  -- first_visit = "map"
end
```

For this task, implement the existing `map` path only. Preserve the exact operation order and rollback behavior currently exercised by `worktrees/tests/session_spec.lua`. Store captured scripts in the passed table:

```lua
sessions[normalize(source.path)] = source_script
local destination_script = sessions[normalize(selected.path)]
```

Do not create module-global session state in `workspace_session`.

- [ ] **Step 4: Replace `worktrees.session` with a compatibility adapter**

Use a private table and pass adapter functions so the existing rollback test can still replace `session.restore`:

```lua
local engine = require("workspace_session")
local M = {}
local sessions = {}

M.owner = engine.owner
M.has_modified_file_buffers = engine.has_modified_file_buffers
M.capture = engine.capture
M.restore = engine.restore

function M.switch(destination, worktrees)
  return engine.switch(sessions, destination, worktrees, {
    require_source = true,
    allow_modified = false,
    first_visit = "map",
    capture = M.capture,
    restore = M.restore,
  })
end

function M.reset()
  sessions = {}
end

return M
```

- [ ] **Step 5: Run the full existing worktree suite**

Run the Step 2 command.

Expected: every Git, session, picker, and merge test prints `ok`, including modified-buffer rejection, relative-path mapping, LSP filtering, and injected rollback.

- [ ] **Step 6: Commit the behavior-preserving extraction**

```bash
git add custom-plugins/workspace-session.nvim/lua/workspace_session/init.lua \
  custom-plugins/worktrees.nvim/lua/worktrees/session.lua \
  custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  custom-plugins/worktrees.nvim/tests/session_spec.lua
git commit -m "refactor(worktrees): extract workspace session engine"
```

---

### Task 2: Implement the Durable JSON Registry

**Files:**
- Create: `custom-plugins/workspaces.nvim/lua/workspaces/registry.lua`
- Create: `custom-plugins/workspaces.nvim/tests/minimal_init.lua`
- Create: `custom-plugins/workspaces.nvim/tests/helpers.lua`
- Create: `custom-plugins/workspaces.nvim/tests/run.lua`
- Create: `custom-plugins/workspaces.nvim/tests/registry_spec.lua`

**Interfaces:**
- Produces: `registry.path() -> string`.
- Produces: `registry.canonical(path) -> string|nil, error`.
- Produces: `registry.load(file?) -> Workspace[]|nil, error`.
- Produces: `registry.add(label, path, file?) -> Workspace[]|nil, error`.
- Produces: `registry.remove(path, file?) -> Workspace[]|nil, error`.
- `Workspace` is exactly `{ label: string, path: canonical-string }`.

- [ ] **Step 1: Create the isolated workspace-plugin test harness**

`tests/minimal_init.lua`:

```lua
local source = debug.getinfo(1, "S").source:sub(2)
local tests = vim.fs.dirname(source)
local plugin = vim.fs.dirname(tests)
local shared = vim.fs.joinpath(vim.fs.dirname(plugin), "workspace-session.nvim")
vim.opt.runtimepath:prepend(shared)
vim.opt.runtimepath:prepend(plugin)
package.path = tests .. "/?.lua;" .. package.path
```

`tests/helpers.lua`:

```lua
local M = {}

function M.eq(expected, actual, message)
  assert(vim.deep_equal(expected, actual), message or vim.inspect({ expected = expected, actual = actual }))
end

function M.temp_dir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, "p")
  return vim.fs.normalize(path)
end

function M.cleanup(path)
  vim.fn.delete(path, "rf")
end

return M
```

`tests/run.lua` initially contains:

```lua
for _, suite in ipairs({ "registry_spec" }) do
  for name, test in pairs(require(suite)) do
    io.write(string.format("%s.%s ... ", suite, name))
    test()
    io.write("ok\n")
  end
end
```

- [ ] **Step 2: Write failing registry tests**

Create `tests/registry_spec.lua` with independent temporary-directory cases:

```lua
local h = require("helpers")
local registry = require("workspaces.registry")

return {
  round_trips_and_allows_duplicate_labels = function()
    local root = h.temp_dir()
    local one, two = root .. "/one", root .. "/two"
    vim.fn.mkdir(one, "p")
    vim.fn.mkdir(two, "p")
    local file = root .. "/data/registry.json"
    assert(registry.add("same", one, file))
    local rows = assert(registry.add("same", two, file))
    h.eq({
      { label = "same", path = assert(vim.uv.fs_realpath(one)) },
      { label = "same", path = assert(vim.uv.fs_realpath(two)) },
    }, rows)
    h.eq(rows, assert(registry.load(file)))
    h.cleanup(root)
  end,

  rejects_duplicate_canonical_paths = function()
    local root = h.temp_dir()
    local workspace = root .. "/workspace"
    vim.fn.mkdir(workspace, "p")
    local file = root .. "/registry.json"
    assert(registry.add("first", workspace, file))
    local rows, err = registry.add("second", workspace .. "/.", file)
    assert(rows == nil)
    assert(err:find("already registered", 1, true))
    h.eq("first", assert(registry.load(file))[1].label)
    h.cleanup(root)
  end,

  rejects_empty_labels_and_missing_new_paths = function()
    local root = h.temp_dir()
    local rows, label_err = registry.add("   ", root, root .. "/registry.json")
    assert(rows == nil and label_err:find("label", 1, true))
    local missing, path_err = registry.add("missing", root .. "/gone", root .. "/registry.json")
    assert(missing == nil and path_err:find("does not exist", 1, true))
    h.cleanup(root)
  end,

  preserves_malformed_registry_files = function()
    local root = h.temp_dir()
    local file = root .. "/registry.json"
    vim.fn.writefile({ "{broken" }, file)
    local before = table.concat(vim.fn.readfile(file), "\n")
    local rows, err = registry.add("x", root, file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    h.eq(before, table.concat(vim.fn.readfile(file), "\n"))
    h.cleanup(root)
  end,

  removes_only_the_exact_canonical_path = function()
    local root = h.temp_dir()
    local one, two = root .. "/one", root .. "/two"
    vim.fn.mkdir(one, "p")
    vim.fn.mkdir(two, "p")
    local file = root .. "/registry.json"
    assert(registry.add("one", one, file))
    assert(registry.add("two", two, file))
    local rows = assert(registry.remove(one .. "/.", file))
    h.eq({ { label = "two", path = assert(vim.uv.fs_realpath(two)) } }, rows)
    local unchanged, err = registry.remove(one, file)
    assert(unchanged == nil and err:find("not registered", 1, true))
    h.cleanup(root)
  end,
}
```

Also add two structural cases: loading `[ {"label":"x"} ]` fails without rewriting it, and a nonexistent registry file loads as `{}`.

- [ ] **Step 3: Run registry tests to verify RED**

Run:

```bash
nvim --headless --clean \
  -u custom-plugins/workspaces.nvim/tests/minimal_init.lua \
  -l custom-plugins/workspaces.nvim/tests/run.lua
```

Expected: failure loading `workspaces.registry`.

- [ ] **Step 4: Implement validation, canonicalization, and atomic writes**

Use the default file only when the optional test path is absent:

```lua
function M.path()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "workspaces.nvim", "registry.json")
end
```

`canonical(path)` must require an existing directory for registration:

```lua
function M.canonical(path)
  local real = vim.uv.fs_realpath(path)
  if not real then return nil, "workspace directory does not exist: " .. path end
  local stat = vim.uv.fs_stat(real)
  if not stat or stat.type ~= "directory" then return nil, "workspace path is not a directory: " .. path end
  return vim.fs.normalize(real)
end
```

`load(file)` must return `{}` on `ENOENT`, decode with `pcall(vim.json.decode, text)`, require an array, and require every record to have exactly usable string `label` and absolute string `path` values. Normalize stored paths but do not require them to exist, because missing registrations remain valid picker entries.

Atomic write shape:

```lua
local function save(rows, file)
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  local temporary = file .. ".tmp." .. tostring(vim.uv.hrtime())
  local ok, err = pcall(vim.fn.writefile, { vim.json.encode(rows) }, temporary)
  if not ok then return nil, "failed to write registry " .. file .. ": " .. tostring(err) end
  local renamed, rename_err = vim.uv.fs_rename(temporary, file)
  if not renamed then
    vim.fn.delete(temporary)
    return nil, "failed to replace registry " .. file .. ": " .. tostring(rename_err)
  end
  return rows
end
```

`add` trims the label, canonicalizes the new path, loads and validates existing rows, checks canonical equality, appends one record, and saves. `remove` canonicalizes with `fs_realpath` when possible and otherwise normalizes the supplied absolute path so missing picker records can be removed.

- [ ] **Step 5: Run registry tests and inspect the written JSON**

Run the Step 3 command.

Expected: all registry cases print `ok`. Confirm the tests leave no `*.tmp.*` files under their temporary directories and no test record under the real `stdpath("data")`.

- [ ] **Step 6: Commit the registry**

```bash
git add custom-plugins/workspaces.nvim/lua/workspaces/registry.lua \
  custom-plugins/workspaces.nvim/tests/minimal_init.lua \
  custom-plugins/workspaces.nvim/tests/helpers.lua \
  custom-plugins/workspaces.nvim/tests/run.lua \
  custom-plugins/workspaces.nvim/tests/registry_spec.lua
git commit -m "feat(workspaces): persist workspace registry"
```

---

### Task 3: Gather Live Git Metadata

**Files:**
- Create: `custom-plugins/workspaces.nvim/lua/workspaces/git.lua`
- Create: `custom-plugins/workspaces.nvim/tests/git_spec.lua`
- Modify: `custom-plugins/workspaces.nvim/tests/helpers.lua`
- Modify: `custom-plugins/workspaces.nvim/tests/run.lua`

**Interfaces:**
- Produces: `git.run(args, opts?) -> { ok, code, stdout, stderr }`.
- Produces: `git.run_async(args, opts, callback)`.
- Produces: `git.parse_status(stdout) -> { branch, detached, staged, unstaged, untracked, conflicted, ahead, behind }`.
- Produces: `git.inspect_async(path, callback)`, where callback receives `{ kind = "git", status = Status }`, `{ kind = "non_git" }`, `{ kind = "missing" }`, or `{ kind = "error", error = string }`.
- Produces: `git.preview(path) -> string[]`.

- [ ] **Step 1: Add deterministic Git fixture support**

Append to `tests/helpers.lua`:

```lua
function M.git(cwd, args)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout or "")
end

function M.temp_repo()
  local root = M.temp_dir()
  local init = vim.system({ "git", "init", "-b", "main", root }, { text = true }):wait()
  assert(init.code == 0, init.stderr)
  M.git(root, { "config", "user.email", "workspace-tests@example.com" })
  M.git(root, { "config", "user.name", "Workspace Tests" })
  vim.fn.writefile({ "base" }, root .. "/base.txt")
  M.git(root, { "add", "base.txt" })
  M.git(root, { "commit", "-m", "base" })
  return root
end
```

Add `"git_spec"` to the explicit suite list in `tests/run.lua`.

- [ ] **Step 2: Write failing parser and classification tests**

Create `tests/git_spec.lua` with:

```lua
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
```

Add a detached-HEAD parser case expecting `detached == true`, `branch == nil`, and a missing-upstream case expecting `ahead == nil`, `behind == nil`.

- [ ] **Step 3: Run Git tests to verify RED**

Run the workspace headless command from Task 2.

Expected: failure loading `workspaces.git`.

- [ ] **Step 4: Implement shell-free Git execution and parsing**

Use the existing worktree runner pattern, but keep this plugin independent:

```lua
local function command(args, opts)
  local cmd = { "git" }
  if opts and opts.cwd then vim.list_extend(cmd, { "-C", opts.cwd }) end
  vim.list_extend(cmd, args)
  return cmd
end
```

Inspect with one asynchronous command:

```lua
local status_args = { "status", "--porcelain=v2", "--branch", "--untracked-files=all" }

function M.inspect_async(path, callback)
  if not vim.uv.fs_stat(path) then
    vim.schedule(function() callback({ kind = "missing" }) end)
    return
  end
  M.run_async(status_args, { cwd = path }, function(result)
    if result.ok then
      callback({ kind = "git", status = M.parse_status(result.stdout) })
    elseif result.stderr:find("not a git repository", 1, true) then
      callback({ kind = "non_git" })
    else
      callback({ kind = "error", error = result.stderr ~= "" and result.stderr or "git status failed" })
    end
  end)
end
```

Parse `# branch.head (detached)` as detached. Count porcelain-v2 `1`, `2`, `?`, and `u` records with the same staged/unstaged semantics already tested in `worktrees.git`.

`preview(path)` returns `{ path, "", ...status lines, "", ...log lines }`; skip Git commands for a missing path and tolerate a non-Git directory by returning its path plus `"Not a Git repository"`.

- [ ] **Step 5: Run registry and Git suites**

Run the Task 2 headless command.

Expected: every `registry_spec` and `git_spec` case prints `ok`.

- [ ] **Step 6: Commit live metadata support**

```bash
git add custom-plugins/workspaces.nvim/lua/workspaces/git.lua \
  custom-plugins/workspaces.nvim/tests/git_spec.lua \
  custom-plugins/workspaces.nvim/tests/helpers.lua \
  custom-plugins/workspaces.nvim/tests/run.lua
git commit -m "feat(workspaces): inspect live Git status"
```

---

### Task 4: Add Workspace-Specific Session Policies

**Files:**
- Modify: `custom-plugins/workspace-session.nvim/lua/workspace_session/init.lua`
- Create: `custom-plugins/workspaces.nvim/tests/session_spec.lua`
- Modify: `custom-plugins/workspaces.nvim/tests/helpers.lua`
- Modify: `custom-plugins/workspaces.nvim/tests/run.lua`

**Interfaces:**
- Extends: `workspace_session.switch` with `allow_modified = true`, `require_source = false`, and `first_visit = "clean"`.
- Consumes: a workspace-owned in-memory `sessions` table and registry records shaped as `{ label, path }`.
- Preserves: all Task 1 worktree policy behavior.

- [ ] **Step 1: Add editor reset and workspace fixtures**

Append to `tests/helpers.lua`:

```lua
local original_cwd = vim.uv.cwd()

function M.reset_editor()
  pcall(vim.cmd, "silent! tabonly")
  pcall(vim.cmd, "silent! only")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  vim.cmd("enew")
  vim.cmd.cd(vim.fn.fnameescape(original_cwd))
end
```

Add `"session_spec"` to `tests/run.lua`.

- [ ] **Step 2: Write failing clean-visit and modified-buffer tests**

Create `tests/session_spec.lua`. Use a private `sessions = {}` for every case and call:

```lua
engine.switch(sessions, destination, roots, {
  require_source = false,
  allow_modified = true,
  first_visit = "clean",
})
```

Required cases:

```lua
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
  local roots = { { label = "source", path = source }, { label = "destination", path = destination } }

  assert(engine.switch(sessions, roots[2], roots, {
    require_source = false, allow_modified = true, first_visit = "clean",
  }))
  h.eq(vim.fs.normalize(destination), vim.uv.cwd())
  h.eq("", vim.api.nvim_buf_get_name(0))
  assert(vim.api.nvim_buf_is_valid(source_buf))
  assert(vim.bo[source_buf].modified)
  h.eq({ "unsaved" }, vim.api.nvim_buf_get_lines(source_buf, 0, -1, false))

  h.reset_editor()
  h.cleanup(source)
  h.cleanup(destination)
end,
```

Add these independent cases with explicit assertions:

- switching back to `source` restores two source tabs, their split layout, cursor positions, and the unsaved source buffer contents;
- switching from an unregistered cwd succeeds, opens a clean destination, leaves its modified buffer valid, and does not add a key for the unregistered path to `sessions`;
- only an LSP client rooted under the source receives `stop()`;
- injected first destination `restore` failure invokes source rollback and restores source cwd;
- `allow_modified = false` still returns the existing `modified file buffers block switching` error.

Restore `vim.lsp.get_clients` and any replaced `engine.restore` function under `xpcall` cleanup.

- [ ] **Step 3: Run workspace session tests to verify RED**

Run the workspace headless command.

Expected: at least the clean-first-visit case fails because Task 1 supports only `first_visit = "map"` and requires a registered source.

- [ ] **Step 4: Implement transient sources and clean first visits**

When `require_source == false` and no root owns cwd, create a transient source record without inserting it into `roots`:

```lua
local source = M.owner(vim.uv.cwd(), roots)
local source_registered = source ~= nil
if not source and not require_source then
  source = { path = normalize(vim.uv.cwd()) }
end
if not source then return false, "current directory is not owned by a registered root" end
```

Always capture the source for rollback. Store it only when registered:

```lua
if source_registered then sessions[normalize(source.path)] = source_script end
```

Skip modified-buffer rejection only when `allow_modified` is true. `delete_obsolete_buffers` must continue deleting only unmodified undisplayed buffers.

For `first_visit == "clean"`, replace visible source layouts with one unnamed listed normal buffer while leaving modified file buffers loaded:

```lua
local function clean_first_visit()
  local clean = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(0, clean)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
end
```

Do not call `buf_delete` on modified buffers. Keep `map` as the only other accepted first-visit policy and return a clear programming error for unknown values.

- [ ] **Step 5: Run both consumer suites**

Run:

```bash
nvim --headless --clean \
  -u custom-plugins/workspaces.nvim/tests/minimal_init.lua \
  -l custom-plugins/workspaces.nvim/tests/run.lua

nvim --headless --clean \
  -u custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  -l custom-plugins/worktrees.nvim/tests/run.lua
```

Expected: all workspace registry/Git/session tests and all pre-existing worktree tests print `ok`.

- [ ] **Step 6: Commit workspace switching policies**

```bash
git add custom-plugins/workspace-session.nvim/lua/workspace_session/init.lua \
  custom-plugins/workspaces.nvim/tests/session_spec.lua \
  custom-plugins/workspaces.nvim/tests/helpers.lua \
  custom-plugins/workspaces.nvim/tests/run.lua
git commit -m "feat(workspaces): preserve in-memory workspace sessions"
```

---

### Task 5: Add Commands, fzf-lua Picker, and Switch Orchestration

**Files:**
- Create: `custom-plugins/workspaces.nvim/lua/workspaces/init.lua`
- Create: `custom-plugins/workspaces.nvim/plugin/workspaces.lua`
- Create: `custom-plugins/workspaces.nvim/tests/picker_spec.lua`
- Modify: `custom-plugins/workspaces.nvim/tests/run.lua`

**Interfaces:**
- Consumes: `registry.load/add/remove`, `git.inspect_async/preview`, and `workspace_session.switch/owner`.
- Produces: `workspaces.format_row(workspace, metadata, active_path) -> string`.
- Produces: `workspaces.add()`, `workspaces.list()`, and `workspaces.delete()`.
- Produces commands: `:WorkspaceAdd`, `:WorkspaceList`, and `:WorkspaceDelete`.
- Emits: `User WorkspaceChanged` with `data = { from, to }` only after a changed successful switch.

- [ ] **Step 1: Add the picker suite and write failing formatting/command tests**

Add `"picker_spec"` to `tests/run.lua`, then create `tests/picker_spec.lua` with a `with_stubs` helper that saves and restores these package entries and functions under `xpcall`:

```lua
local names = {
  "workspaces", "workspaces.registry", "workspaces.git",
  "workspace_session", "fzf-lua",
}
```

Restore `vim.ui.input`, `vim.notify`, and `vim.api.nvim_exec_autocmds` after every stubbed case.

Formatting cases must assert:

```lua
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
```

Separate cases assert `—` for `kind = "non_git"`, `[missing]` for `kind = "missing"`, and `ERR` for `kind = "error"`.

Source `plugin/workspaces.lua` and assert all three commands exist.

- [ ] **Step 2: Write failing add/delete orchestration tests**

Stub `registry.add` and `vim.ui.input`; assert `add()` prompts with `Workspace label: `, trims the label, and passes exact `vim.uv.cwd()` to `registry.add`.

Stub `registry.remove`; assert `delete()` passes exact cwd. Add failure cases proving duplicate-add and nonregistered-delete errors reach `vim.notify` and do not raise.

The command file must eventually be exactly:

```lua
for command, method in pairs({
  WorkspaceAdd = "add",
  WorkspaceList = "list",
  WorkspaceDelete = "delete",
}) do
  vim.api.nvim_create_user_command(command, function()
    require("workspaces")[method]()
  end, {})
end
```

- [ ] **Step 3: Write failing picker and switch-event tests**

Use three records—Git, non-Git, and missing—and capture `git.inspect_async` callbacks. Assert:

- all three inspections start before fzf opens;
- fzf opens only after every callback finishes;
- all three rows remain present;
- `opts.previewer` is a native Lua previewer and `opts.preview == nil`;
- selecting `[missing]` notifies and never calls `engine.switch`;
- default action re-loads the registry and switches using the refreshed canonical record;
- `ctrl-d` calls `registry.remove(selected_path)` for a missing record;
- successful changed selection emits exactly one event:

```lua
{
  pattern = "WorkspaceChanged",
  data = { from = "/source", to = "/destination" },
}
```

- failed switch emits no event;
- selecting the current workspace is a no-op and emits no event.

- [ ] **Step 4: Run picker tests to verify RED**

Run the workspace headless command.

Expected: failure loading `workspaces.init`.

- [ ] **Step 5: Implement row formatting and the native previewer**

Keep a `row_lookup[row] = canonical_path` table per invocation. Format deterministic columns with `string.format`; use `-` for missing ahead/behind values. Resolve the active marker with longest path ownership rather than string-prefix matching.

Build the previewer from fzf-lua's builtin base:

```lua
local function create_previewer(row_lookup)
  return {
    _ctor = function()
      local preview = require("fzf-lua.previewer.builtin").base:extend()
      function preview:populate_preview_buf(entry)
        local path = row_lookup[entry]
        local buf = self:get_tmp_buffer()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, git.preview(path))
        self:set_preview_buf(buf)
        self.win:update_preview_title(path)
      end
      return preview
    end,
  }
end
```

- [ ] **Step 6: Implement add, delete, list, and switching**

Keep process-local state in `workspaces.init`:

```lua
local sessions = {}
```

`list()` loads records, notifies on an empty registry, invokes `git.inspect_async` for every record, and opens fzf only when `pending == 0`. Default action must:

1. map the exact selected row to a path;
2. re-run `registry.load()`;
3. find the refreshed record by normalized canonical path;
4. reject missing/stale destinations;
5. compute `from` as the longest registered owner of cwd or normalized cwd;
6. return without switching when `from == destination.path`;
7. call the engine with workspace policies; and
8. emit the event only after success.

Engine call:

```lua
local ok, err = session.switch(sessions, destination, fresh, {
  require_source = false,
  allow_modified = true,
  first_visit = "clean",
})
```

Event call:

```lua
vim.api.nvim_exec_autocmds("User", {
  pattern = "WorkspaceChanged",
  data = { from = from, to = destination.path },
})
```

The `ctrl-d` action removes the selected path even when missing and closes naturally after the action. It does not delete files or clear `sessions`.

- [ ] **Step 7: Run all workspace and worktree tests**

Run both commands from Task 4 Step 5.

Expected: all suites print `ok`; no test leaves commands, package stubs, cwd, LSP stubs, or UI stubs that alter later cases.

- [ ] **Step 8: Commit the public plugin behavior**

```bash
git add custom-plugins/workspaces.nvim/lua/workspaces/init.lua \
  custom-plugins/workspaces.nvim/plugin/workspaces.lua \
  custom-plugins/workspaces.nvim/tests/picker_spec.lua \
  custom-plugins/workspaces.nvim/tests/run.lua
git commit -m "feat(workspaces): add fzf workspace commands"
```

---

### Task 6: Integrate with lazy.nvim and Verify End to End

**Files:**
- Create: `lua/plugins/workspaces.lua`
- Modify: `lua/plugins/worktrees.lua:1-13`

**Interfaces:**
- Consumes: `require("workspaces").add/list/delete` and the shared runtime module.
- Produces mappings: `<leader>wa`, `<leader>ww`, and `<leader>wd`.
- Preserves mappings: `<leader>wc`, `<leader>wl`, and `<leader>wm`.

- [ ] **Step 1: Confirm commands and mappings are free before integration**

Run:

```bash
rg -n 'Workspace(Add|List|Delete)|<leader>w[awd]' lua custom-plugins
```

Expected: only the new workspace plugin commands/tests appear; no existing mapping owns `<leader>wa`, `<leader>ww`, or `<leader>wd`. Stop and report instead of replacing a conflicting mapping.

- [ ] **Step 2: Add the local workspace lazy.nvim specification**

Create `lua/plugins/workspaces.lua`:

```lua
local shared = {
  dir = vim.fn.stdpath("config") .. "/custom-plugins/workspace-session.nvim",
  name = "workspace-session.nvim",
}

return {
  {
    dir = vim.fn.stdpath("config") .. "/custom-plugins/workspaces.nvim",
    name = "workspaces.nvim",
    dependencies = { "ibhagwan/fzf-lua", shared },
    cmd = { "WorkspaceAdd", "WorkspaceList", "WorkspaceDelete" },
    keys = {
      { "<leader>wa", function() require("workspaces").add() end, desc = "Add workspace" },
      { "<leader>ww", function() require("workspaces").list() end, desc = "List workspaces" },
      { "<leader>wd", function() require("workspaces").delete() end, desc = "Delete workspace" },
    },
  },
}
```

- [ ] **Step 3: Add the shared dependency to the existing worktree spec**

Change only `dependencies` in `lua/plugins/worktrees.lua`:

```lua
dependencies = {
  "ibhagwan/fzf-lua",
  {
    dir = vim.fn.stdpath("config") .. "/custom-plugins/workspace-session.nvim",
    name = "workspace-session.nvim",
  },
},
```

Do not alter existing worktree commands or mappings.

- [ ] **Step 4: Run complete automated verification**

Run:

```bash
nvim --headless --clean \
  -u custom-plugins/workspaces.nvim/tests/minimal_init.lua \
  -l custom-plugins/workspaces.nvim/tests/run.lua

nvim --headless --clean \
  -u custom-plugins/worktrees.nvim/tests/minimal_init.lua \
  -l custom-plugins/worktrees.nvim/tests/run.lua

nvim --headless '+Lazy! sync' +qa

nvim --headless \
  '+lua assert(vim.fn.exists(":WorkspaceAdd") == 2)' \
  '+lua assert(vim.fn.exists(":WorkspaceList") == 2)' \
  '+lua assert(vim.fn.exists(":WorkspaceDelete") == 2)' \
  '+lua assert(vim.fn.maparg("<leader>wa", "n") ~= "")' \
  '+lua assert(vim.fn.maparg("<leader>ww", "n") ~= "")' \
  '+lua assert(vim.fn.maparg("<leader>wd", "n") ~= "")' \
  '+lua assert(vim.fn.exists(":WorktreeList") == 2)' \
  +qa

git diff --check
```

Expected: both plugin suites pass, lazy.nvim exits zero, all commands/mappings exist in the real config, the worktree plugin still loads, and `git diff --check` prints nothing.

- [ ] **Step 5: Perform a disposable manual smoke test**

Use two temporary directories, one Git repository and one plain directory:

```bash
root=$(mktemp -d)
git_dir="$root/git-project"
plain_dir="$root/notes"
git init -b main "$git_dir"
mkdir -p "$plain_dir"
printf 'base\n' > "$git_dir/base.txt"
git -C "$git_dir" add base.txt
git -C "$git_dir" -c user.name=Test -c user.email=test@example.com commit -m base
nvim "$git_dir/base.txt"
```

Inside Neovim verify this sequence:

1. `<leader>wa`, enter `Git project`, and confirm registration.
2. `:cd <plain_dir>`, `<leader>wa`, enter `Notes`, and confirm registration.
3. `<leader>ww`; confirm Git branch/status, non-Git dashes, labels, and absolute paths.
4. Move selection; confirm preview shows path and Git status/log only for the Git project.
5. Select the Git project; confirm cwd changes and the first visit is one clean unnamed window.
6. Open two files in splits and another tab, modify one without saving, then switch to Notes.
7. Switch back; confirm tabs/splits/views and unsaved text return.
8. Confirm source LSP clients stop and destination buffers start their normal configured clients.
9. Register a temporary third directory, delete it on disk, reopen the picker, confirm `[missing]`, and remove it with `Ctrl-d`.
10. In Notes, run `<leader>wd`; confirm only its registry entry disappears and its directory/buffers remain.
11. Restart Neovim and confirm Git project remains registered while layouts do not persist.

Remove the temporary smoke-test registry entries through the picker before deleting `$root`.

- [ ] **Step 6: Run extraction and scope checks**

```bash
# Feature plugins must not import parent-config private modules.
rg -n 'require\("(icons|utils|autogroups|plugins\.)' \
  custom-plugins/workspaces.nvim custom-plugins/workspace-session.nvim && exit 1 || true

# No SQLite, temp registry, or vendored picker.
rg -ni 'sqlite|/tmp' custom-plugins/workspaces.nvim custom-plugins/workspace-session.nvim && exit 1 || true
test ! -d custom-plugins/workspaces.nvim/fzf-lua

git diff --check
git status --short
```

Expected: no private imports, no SQLite or `/tmp` implementation, no vendored fzf-lua, no whitespace errors, and only intended files are uncommitted.

- [ ] **Step 7: Commit integration**

```bash
git add lua/plugins/workspaces.lua lua/plugins/worktrees.lua
git commit -m "feat: install local workspace registry plugin"
```

- [ ] **Step 8: Verify the committed tree**

Repeat Step 4, then run:

```bash
git status --short
git log --oneline -7
```

Expected: all checks pass, the working tree is clean, and commits appear in this order: shared session extraction, registry, Git metadata, workspace sessions, picker/commands, integration.
