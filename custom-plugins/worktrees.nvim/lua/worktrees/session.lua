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
