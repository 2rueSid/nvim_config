local M = {}

function M.tflint(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").tflint.setup({
		on_attach = on_attach,
		capabilities = capabilities,
		cmd = {
			"tflint",
			"--langserver",
		},
	})
end

function M.tfls(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").terraformls.setup({
		capabilities = capabilities,
	})
end

return M
