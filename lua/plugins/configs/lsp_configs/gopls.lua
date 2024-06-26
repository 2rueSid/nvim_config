local M = {}

function M.setup(on_attach, cp)
	require("lspconfig").gopls.setup({
		on_attach = on_attach,
		capabilities = cp,
		settings = {
			gopls = {
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
				staticcheck = true,
				gofumpt = true,
			},
		},
	})
end

return M
