local M = {}

function M.dockerls(on_attach, cp)
	require("lspconfig").dockerls.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

function M.docker_compose_language_service(on_attach, cp)
	require("lspconfig").docker_compose_language_service.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

return M
