local handlers = require("debug_logger.handlers")

local M = {}

function M.log_variable()
	local filetype = vim.bo.filetype
	local handler = handlers[filetype]

	if handler then
		handler()
	else
		vim.notify("No debug handler for filetype: " .. filetype, vim.log.levels.WARN)
	end
end

return M
