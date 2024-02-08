local M = {}

function M.setup(on_attach)
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true

	require("lspconfig").gopls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

return M
