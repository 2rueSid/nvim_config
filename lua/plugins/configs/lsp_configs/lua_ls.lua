local M = {}

function M.setup(on_attach, cp)
	require("lspconfig").lua_ls.setup({
		on_attach = on_attach,

		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim" },
				},
				hint = {
					enable = true,
					setType = true,
				},

				workspace = {
					library = {
						[vim.fn.expand("$VIMRUNTIME/lua")] = true,
						[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
						[vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
					},
					maxPreload = 100000,
					preloadFileSize = 10000,
				},
			},
		},
		capabilities = cp,
	})
end

return M
