local M = {}

function M.ts_ls(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").ts_ls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.eslint(on_attach)
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	require("lspconfig").eslint.setup({
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				command = "EslintFixAll",
			})

			on_attach(client, bufnr)
		end,
	})
end

return M
