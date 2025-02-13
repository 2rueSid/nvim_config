return {
	{
		"mfussenegger/nvim-lint",
		lazy = true,
		config = function()
			local opts = require("plugins.configs.linters")
			require("lint").linters_by_ft = opts
		end,
	},
}
