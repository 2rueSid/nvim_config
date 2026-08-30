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

  rejects_records_without_label_or_path_without_rewriting = function()
    local root = h.temp_dir()
    local file = root .. "/registry.json"
    local contents = '[{"label":"x"}]\n'
    contents = contents:gsub("\n$", "")
    vim.fn.writefile({ contents }, file)
    local before = table.concat(vim.fn.readfile(file), "\n")
    local rows, err = registry.load(file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    h.eq(before, table.concat(vim.fn.readfile(file), "\n"))
    h.cleanup(root)
  end,

  rejects_duplicate_stored_paths_without_rewriting = function()
    local root = h.temp_dir()
    local workspace = root .. "/workspace"
    vim.fn.mkdir(workspace, "p")
    local file = root .. "/registry.json"
    local contents = string.format(
      '[{"label":"one","path":%q},{"label":"two","path":%q}]',
      workspace,
      workspace .. "/."
    )
    vim.fn.writefile({ contents }, file)
    local before = table.concat(vim.fn.readfile(file), "\n")
    local rows, err = registry.add("new", root, file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    h.eq(before, table.concat(vim.fn.readfile(file), "\n"))
    h.cleanup(root)
  end,

  rejects_existing_symlink_stored_paths_without_rewriting = function()
    local root = h.temp_dir()
    local target, alias = root .. "/target", root .. "/alias"
    vim.fn.mkdir(target, "p")
    assert(vim.uv.fs_symlink(target, alias))
    local file = root .. "/registry.json"
    local contents = string.format('[{"label":"alias","path":%q}]\n', alias)
    contents = contents:gsub("\n$", "")
    vim.fn.writefile({ contents }, file)
    local before = table.concat(vim.fn.readfile(file), "\n")
    vim.fn.mkdir(root .. "/new", "p")

    local rows, err = registry.load(file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    rows, err = registry.add("new", root .. "/new", file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    rows, err = registry.remove(alias, file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    h.eq(before, table.concat(vim.fn.readfile(file), "\n"))
    h.cleanup(root)
  end,

  rejects_duplicate_resolved_paths_without_rewriting = function()
    local root = h.temp_dir()
    local target, alias = root .. "/target", root .. "/alias"
    vim.fn.mkdir(target, "p")
    assert(vim.uv.fs_symlink(target, alias))
    local file = root .. "/registry.json"
    local contents = string.format(
      '[{"label":"alias","path":%q},{"label":"target","path":%q}]\n',
      alias,
      target
    )
    contents = contents:gsub("\n$", "")
    vim.fn.writefile({ contents }, file)
    local before = table.concat(vim.fn.readfile(file), "\n")
    local rows, err = registry.load(file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    rows, err = registry.remove(target, file)
    assert(rows == nil and err:find("invalid registry", 1, true))
    h.eq(before, table.concat(vim.fn.readfile(file), "\n"))
    h.cleanup(root)
  end,

  keeps_missing_paths_valid_and_removable = function()
    local root = h.temp_dir()
    local missing = root .. "/missing"
    local file = root .. "/registry.json"
    vim.fn.writefile({ string.format('[{"label":"gone","path":%q}]', missing) }, file)
    h.eq({ { label = "gone", path = missing } }, assert(registry.load(file)))
    h.eq({}, assert(registry.remove(missing, file)))
    h.cleanup(root)
  end,

  loads_missing_registry_as_empty = function()
    local root = h.temp_dir()
    h.eq({}, assert(registry.load(root .. "/missing/registry.json")))
    h.cleanup(root)
  end,
}
