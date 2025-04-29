local utils = require("debug_logger.utils")

local handlers = {}

local js = function()
	local text, node_type, node = utils.get_node_text()
	if not text then
		return
	end

	local call_stack = utils.get_call_stack(node)
	local line_number = vim.api.nvim_win_get_cursor(0)[1] + 1
	local file_name = vim.fn.expand("%:t")

	local log_line
	if node_type == "identifier" then
		-- Assume variable
		log_line = string.format(
			'console.debug("[DEBUG]: %s:%d: %s: ", %s)',
			file_name,
			line_number,
			call_stack .. (call_stack ~= "" and ": " or "") .. text,
			text
		)
	elseif node_type == "call_expression" then
		-- Function call
		log_line = string.format(
			'console.debug("[DEBUG]: %s:%d: %s: ", %s)',
			file_name,
			line_number,
			call_stack .. (call_stack ~= "" and ": " or "") .. text,
			text .. "()"
		)
	else
		-- Default to identifier style
		log_line = string.format(
			'console.debug("[DEBUG]: %s:%d: %s: ", %s)',
			file_name,
			line_number,
			call_stack .. (call_stack ~= "" and ": " or "") .. text,
			text
		)
	end

	utils.insert_log_line(log_line, node)
end

handlers.javascript = js
handlers.typescript = js
handlers.lua = function()
	local text, node_type, node = utils.get_node_text()
	if not text then
		vim.notify("No node text found", vim.log.levels.WARN)
		return
	end

	vim.notify("Lua Handler: node type: " .. node_type .. ", text: " .. text, vim.log.levels.INFO)
end

handlers.python = function()
	vim.notify("Python handler not yet implemented.", vim.log.levels.INFO)
end

return handlers
