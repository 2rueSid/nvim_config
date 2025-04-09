local M = {}

local function get_full_expression_node(node)
	while node do
		if node:type() == "member_expression" or node:type() == "subscript_expression" then
			return node
		end
		node = node:parent()
	end
	return nil
end

function M.get_node_text()
	local ts_utils = require("nvim-treesitter.ts_utils")

	local node = ts_utils.get_node_at_cursor()
	if not node then
		return nil
	end

	local expr_node = get_full_expression_node(node)
	if expr_node then
		return vim.treesitter.get_node_text(expr_node, 0), expr_node:type(), expr_node
	end

	return vim.treesitter.get_node_text(node, 0), node:type(), node
end

function M.get_call_stack(node)
	local stack = {}
	local parent = node:parent()

	while parent do
		if
			parent:type() == "function_declaration"
			or parent:type() == "function"
			or parent:type() == "method_definition"
		then
			local id_node = parent:field("name")[1]
			if id_node then
				table.insert(stack, 1, vim.treesitter.get_node_text(id_node, 0))
			end
		end
		parent = parent:parent()
	end

	return table.concat(stack, "/")
end

local function find_next_free_space(node)
	while
		node
		and not (node:type():match("statement") or node:type():match("declaration") or node:type():match("expression"))
	do
		node = node:parent()
	end

	if not node then
		local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
		return row
	end

	local _, _, end_row, _ = node:range()
	return end_row + 1
end

local function is_parameter_node(node)
	while node do
		if node:type() == "formal_parameters" or node:type() == "required_parameter" then
			return true
		end
		node = node:parent()
	end
	return false
end

local function find_function_body_start(node)
	while node and not node:type():match("function") and not node:type():match("method_definition") do
		node = node:parent()
	end
	if not node then
		return nil
	end

	local body_node = node:field("body")[1]
	if not body_node then
		return nil
	end

	local start_row, _, _, _ = body_node:range()
	return start_row + 1 -- insert after opening brace
end

function M.insert_log_line(log_str, node)
	local target_row

	if is_parameter_node(node) then
		target_row = find_function_body_start(node)
	end

	if not target_row then
		target_row = find_next_free_space(node)
	end

	local indent = ""
	for i = target_row - 1, 0, -1 do
		local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
		if line and line:match("%S") then
			indent = line:match("^%s*") or ""
			break
		end
	end

	vim.api.nvim_buf_set_lines(0, target_row, target_row, false, { indent .. log_str })
end

return M
