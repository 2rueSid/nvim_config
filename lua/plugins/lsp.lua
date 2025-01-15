return {
	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			{ "antosha417/nvim-lsp-file-operations", config = true },
			"RRethy/vim-illuminate",
		},
		config = function()
			require("plugins.configs.lsp_config")
		end,
		opts = {
			inlay_hints = { enabled = true },
		},
	},

	-- LSP Diagnostics
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
		opts = {},
	},
}
