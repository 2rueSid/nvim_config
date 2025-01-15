return {
	-- Tmux motions
	{
		"alexghergh/nvim-tmux-navigation",
		config = function()
			require("nvim-tmux-navigation").setup({})
		end,
	},
  -- jj to escape
	{
		"max397574/better-escape.nvim",
		config = function()
			require("better_escape").setup()
		end,
	},
  -- jump to a character in the viewport
	{
		"ggandor/leap.nvim",
		dependencies = { "tpope/vim-repeat" },
		config = function(_, opts)
			require("leap").add_default_mappings()
		end,
	},
}

