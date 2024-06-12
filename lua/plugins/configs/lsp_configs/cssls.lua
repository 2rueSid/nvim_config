local M = {}

function M.cssls(on_attach, cp)
	require("lspconfig").cssls.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

function M.css_variables(on_attach, cp)
	require("lspconfig").css_variables.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

function M.cssmodules_ls(on_attach, cp)
	require("lspconfig").css_variables.setup({
		on_attach = on_attach,
		capabilities = cp,
	})
end

return M
