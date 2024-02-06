local M = {}

function M.setup(on_attach, capabilities)
	require("lspconfig").ruff_lsp.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

return M
