local M = {}

function M.path()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "workspaces.nvim", "registry.json")
end

local function file_path(file)
  return file or M.path()
end

local function is_absolute(path)
  return type(path) == "string" and path:sub(1, 1) == "/"
end

function M.canonical(path)
  if type(path) ~= "string" then return nil, "workspace path must be a string" end
  local real = vim.uv.fs_realpath(path)
  if not real then return nil, "workspace directory does not exist: " .. path end
  local stat = vim.uv.fs_stat(real)
  if not stat or stat.type ~= "directory" then return nil, "workspace path is not a directory: " .. path end
  return vim.fs.normalize(real)
end

local function invalid(message)
  return nil, "invalid registry: " .. message
end

local function is_array(value)
  if type(value) ~= "table" then return false end
  local length = 0
  for key in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
    length = math.max(length, key)
  end
  for index = 1, length do
    if value[index] == nil then return false end
  end
  return true
end

local function validate_rows(value, text)
  local trimmed = vim.trim(text)
  if trimmed:sub(1, 1) ~= "[" or trimmed:sub(-1) ~= "]" or not is_array(value) then
    return invalid("expected an array")
  end

  local rows = {}
  local paths = {}
  for index, row in ipairs(value) do
    if type(row) ~= "table" or row.label == nil or row.path == nil then
      return invalid("entry " .. index .. " must have label and path")
    end
    local fields = 0
    for key in pairs(row) do
      fields = fields + 1
      if key ~= "label" and key ~= "path" then
        return invalid("entry " .. index .. " has unexpected fields")
      end
    end
    if fields ~= 2 or type(row.label) ~= "string" or vim.trim(row.label) == "" then
      return invalid("entry " .. index .. " has an unusable label")
    end
    if type(row.path) ~= "string" or not is_absolute(row.path) then
      return invalid("entry " .. index .. " must have an absolute path")
    end
    local normalized_path = vim.fs.normalize(row.path)
    if paths[normalized_path] then return invalid("duplicate workspace path: " .. normalized_path) end
    paths[normalized_path] = true
    rows[index] = { label = row.label, path = normalized_path }
  end
  return rows
end

function M.load(file)
  file = file_path(file)
  local stat, stat_err = vim.uv.fs_stat(file)
  if not stat then
    if stat_err and stat_err:find("ENOENT", 1, true) then return {} end
    return nil, "failed to read registry " .. file .. ": " .. tostring(stat_err)
  end
  if stat.type ~= "file" then return invalid("registry is not a file") end

  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then return nil, "failed to read registry " .. file .. ": " .. tostring(lines) end
  local text = table.concat(lines, "\n")
  local decoded_ok, value = pcall(vim.json.decode, text)
  if not decoded_ok then return invalid("invalid JSON") end
  return validate_rows(value, text)
end

local function save(rows, file)
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  local temporary = file .. ".tmp." .. tostring(vim.uv.hrtime())
  local ok, err = pcall(vim.fn.writefile, { vim.json.encode(rows) }, temporary)
  if not ok then
    vim.fn.delete(temporary)
    return nil, "failed to write registry " .. file .. ": " .. tostring(err)
  end
  local renamed, rename_err = vim.uv.fs_rename(temporary, file)
  if not renamed then
    vim.fn.delete(temporary)
    return nil, "failed to replace registry " .. file .. ": " .. tostring(rename_err)
  end
  return rows
end

function M.add(label, path, file)
  if type(label) ~= "string" or vim.trim(label) == "" then return nil, "label must not be empty" end
  local canonical, canonical_err = M.canonical(path)
  if not canonical then return nil, canonical_err end
  local rows, load_err = M.load(file)
  if not rows then return nil, load_err end
  for _, row in ipairs(rows) do
    if row.path == canonical then return nil, "workspace path is already registered: " .. canonical end
  end
  table.insert(rows, { label = vim.trim(label), path = canonical })
  return save(rows, file_path(file))
end

function M.remove(path, file)
  if not is_absolute(path) then return nil, "workspace path must be absolute: " .. tostring(path) end
  local target = vim.uv.fs_realpath(path)
  target = vim.fs.normalize(target or path)
  local rows, load_err = M.load(file)
  if not rows then return nil, load_err end
  local removed = false
  local remaining = {}
  for _, row in ipairs(rows) do
    if row.path == target then
      removed = true
    else
      table.insert(remaining, row)
    end
  end
  if not removed then return nil, "workspace path is not registered: " .. target end
  return save(remaining, file_path(file))
end

return M
