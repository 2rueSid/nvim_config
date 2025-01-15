local lsp_util = require("lspconfig/util")
local path = lsp_util.path

local function get_python_path(workspace)
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

local M = {}

function M.setup(on_attach, capabilities)
	require("lspconfig").pyright.setup({
		on_attach = on_attach,
		capabilities = capabilities,
		on_init = function(client)
			client.config.settings.python.pythonPath = get_python_path(client.config.root_dir)
		end,
		settings = {
			python = {
				analysis = {
					typeCheckingMode = "off",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "openFilesOnly",
					autoImportCompletions = true,
				},
				disableOrganizeImports = true,
				-- analysis = {
				-- 	autoSearchPaths = true,
				-- 	useLibraryCodeForTypes = true,
				-- 	autoImportCompletions = true,
				-- },
			},
		},
	})
end

return M
