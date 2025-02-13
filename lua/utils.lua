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

return M
