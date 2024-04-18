local M = {}

function M.setup(on_attach, cp)
	require("lspconfig").terraformls.setup({
		on_attach = on_attach,
		flags = { debounce_text_changes = 150 },
		capabilities = cp,
	})
end

return M
