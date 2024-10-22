local M = {}

function M.setup(on_attach, cp)
	require("lspconfig").tflint.setup({
		on_attach = on_attach,
		capabilities = cp,
		cmd = {
			"tflint",
			"--langserver",
			"-c",
			"~/.tflint.hcl",
		},
	})
end

return M
