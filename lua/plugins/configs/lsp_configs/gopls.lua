local M = {}

function M.setup(on_attach, cp)
	cp.textDocument.completion.completionItem.snippetSupport = true

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
				analyses = {
					unusedparams = true,
				},
				staticcheck = true,
				gofumpt = true,
			},
		},
	})
end

return M
