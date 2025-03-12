local M = {}

M.get_python_path = function(workspace, path)
	-- Use activated virtualenv.
	if vim.env.VIRTUAL_ENV then
		return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
	end

	-- Prioritieze .venv folder if it exists in the workspace.
	local match = vim.fn.glob(path.join(workspace, ".venv"))
	if match ~= "" then
		return path.join(workspace, ".venv", "bin", "python")
	end

	-- Find and use virtualenv via poetry in workspace directory.
	local match = vim.fn.glob(path.join(workspace, "poetry.lock"))
	if match ~= "" then
		local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
		return path.join(venv, "bin", "python")
	end

	-- Fallback to system Python.
	return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

M.open_definition_smart_split = function()
	local num_splits = vim.fn.winnr("$")

	if num_splits == 1 then
		-- If only one split, open a vertical split and jump to it
		vim.cmd("vsplit")
		vim.cmd("wincmd l")
	elseif num_splits == 2 then
		-- If two splits, open a horizontal split and jump to it
		vim.cmd("split")
		vim.cmd("wincmd j")
	elseif num_splits == 3 then
		-- If three splits, move to the third split and replace it
		vim.cmd("wincmd l")
		vim.cmd("wincmd j")
		vim.cmd("edit")
	end

	-- Open the definition in the focused window
	vim.lsp.buf.definition()
end

return M
