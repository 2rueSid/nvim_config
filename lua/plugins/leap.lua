return {
	-- jump to a character in the viewport
	{
		"ggandor/leap.nvim",
		dependencies = { "tpope/vim-repeat" },
		config = function(_, opts)
			require("leap").add_default_mappings()
		end,
	},
}
