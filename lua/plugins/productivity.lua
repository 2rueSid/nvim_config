return {

	-- TS/JS auto close tags
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		opts = {},
	},

	-- Colorizer
	{
		"norcalli/nvim-colorizer.lua",
		setup = function()
			require("colorizer").setup()
		end,
	},

	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		opts = {
			keymaps = {
				insert = false,
				insert_line = false,
				visual_line = false,
				normal = "yz",
				normal_cur = "yzz",
				normal_line = "yZ",
				normal_cur_line = "yZZ",
				visual = "Z",
			},
		},
	},
	-- Render Markdown
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
}
