local M = {}

function M.setup(on_attach, cp)
	cp.textDocument.completion.completionItem.snippetSupport = true

	require("lspconfig").golangci_lint_ls.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

return M
