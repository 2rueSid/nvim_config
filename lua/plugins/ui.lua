return {
	-- Bottom line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
		config = function()
			local opts = require("plugins.configs.lualine")
			require("lualine").setup(opts)
		end,
	},
	-- Theme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		opts = {
			transparent_background = false,
			show_end_of_buffer = false,
			term_colors = false,
			no_italic = false,
			no_bold = false,
			no_underline = false,
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
				loops = { "italic" },
				keywords = { "italic" },
				strings = { "italic" },
				numbers = { "bold" },
				booleans = { "bold" },
				operators = { "bold" },
				functions = {},
				variables = {},
				properties = {},
				types = {},
			},
			integrations = {
				blink_cmp = true,
				gitsigns = true,
				nvimtree = true,
				treesitter = true,
				illuminate = {
					enabled = true,
					lsp = true,
				},
				mason = true,
				barbecue = {
					dim_dirname = true,
					bold_basename = true,
					dim_context = false,
					alt_background = false,
				},
				lsp_trouble = true,
			},
		},
		config = function(_, opts)
			require("catppuccin").setup()
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	-- nvim-tree
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			local options = require("plugins.configs.nvimtree")
			require("nvim-tree").setup(options)
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
	},
	-- Autofocus and autoresizing windows
	{
		"nvim-focus/focus.nvim",
		version = "*",
		config = function()
			require("focus").setup()
		end,
	},

	{
		"Bekaboo/dropbar.nvim",
		-- optional, but required for fuzzy finder support
		dependencies = {
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			local dropbar_api = require("dropbar.api")
			vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
			vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
			vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
		end,
	},
}
