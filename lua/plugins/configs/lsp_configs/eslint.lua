local M = {}

-- function M.setup(on_attach, cp)
-- 	require("lspconfig").eslint.setup({
-- 		on_attach = function(client, bufnr)
-- 			vim.api.nvim_create_autocmd("BufWritePre", {
-- 				buffer = bufnr,
-- 				command = "EslintFixAll",
-- 			})
-- 		end,
-- 	})
-- end

return M
