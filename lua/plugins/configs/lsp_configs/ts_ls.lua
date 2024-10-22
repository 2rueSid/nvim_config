local M = {}

function M.setup(on_attach, capabilities)
	require("lspconfig").ts_ls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

return M
