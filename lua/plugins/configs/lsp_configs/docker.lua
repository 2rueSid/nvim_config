local M = {}

function M.dockerls(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").dockerls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.docker_compose_language_service(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").docker_compose_language_service.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

return M
