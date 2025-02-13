return {
	-- Mason
	{
		"williamboman/mason.nvim",
		config = function()
			local config = require("plugins.configs.mason")
			require("mason").setup(config)
		end,
		lazy = false,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			local config = require("plugins.configs.mason_lsp")
			require("mason-lspconfig").setup(config)
		end,
		lazy = false,
	},
	-- Linter
	{
		"mfussenegger/nvim-lint",
		lazy = true,
		config = function()
			local opts = require("plugins.configs.linters")
			require("lint").linters_by_ft = opts
		end,
	},
}
