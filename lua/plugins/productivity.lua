return {
	-- This plugin adds indentation guides to Neovim. It uses Neovim's virtual text feature and no conceal
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {},
		init = function()
			require("ibl").setup()
		end,
	},

	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			local tree_sitter = require("plugins.configs.treesitter")
			require("nvim-treesitter.configs").setup(tree_sitter)
		end,
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter-textobjects",
			},
		},
	},

	-- Neovim plugin for automatically highlighting other uses of the word under the cursor using either LSP, Tree-sitter, or regex matching.
	{
		"RRethy/vim-illuminate",
		config = function()
			require("illuminate").configure({
				providers = {
					"lsp",
					"treesitter",
					"regex",
				},
				delay = 100,
				filetypes_denylist = {
					"dirbuf",
					"dirvish",
					"fugitive",
				},
				under_cursor = true,
				min_count_to_highlight = 1,
				should_enable = function(bufnr)
					return true
				end,
				case_insensitive_regex = false,
			})
		end,
		lazy = false,
	},

	-- TS/JS auto close tags
	{
		"windwp/nvim-ts-autotag",
		init = function()
			require("nvim-ts-autotag").setup()
		end,
	},

	-- Colorizer
	{
		"norcalli/nvim-colorizer.lua",
		setup = function()
			require("colorizer").setup()
		end,
	},

	-- Copilot
	{
		"github/copilot.vim",
	},

	-- Render Markdown
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
}
