local M = {}

function M.setup(on_attach, cp)
	require("lspconfig").nil_ls.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

return M
