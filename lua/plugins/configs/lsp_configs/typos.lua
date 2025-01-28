local M = {}

function M.setup(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").typos_lsp.setup({
		on_attach = function(client, bufnr)
			on_attach(client, bufnr)
		end,
		capabilities = capabilities,
	})
end

return M
