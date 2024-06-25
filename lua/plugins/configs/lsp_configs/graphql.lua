local M = {}

function M.setup(on_attach, cp)
	require("lspconfig").graphql.setup({
		on_attach = function(client, bufnr)
			on_attach(client, bufnr)
		end,
		capabilities = cp,
	})
end

return M
