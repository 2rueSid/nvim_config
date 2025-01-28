local M = {}

function M.setup(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").bashls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

return M
