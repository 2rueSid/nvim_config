return {
	-- Bottom line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
		config = function()
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "catppuccin",
					component_separators = { left = "\u{ea9b}", right = "\u{ea9c}" },
					section_separators = { left = "\u{e0bb}", right = "\u{e0bb}" },
					ignore_focus = {},
					always_divide_middle = true,
					globalstatus = false,
					refresh = {
						statusline = 1000,
						tabline = 1000,
						winbar = 1000,
					},
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = {
						{
							"branch",
							icons_enabled = true,
							icon = "\u{e725}",
						},
						"diff",
						"diagnostics",
					},
					lualine_c = { "filename" },
					lualine_x = { "buffers", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
				tabline = {},
				winbar = {},
				inactive_winbar = {},
				extensions = {},
			})
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

	{
		"Bekaboo/dropbar.nvim",
		-- optional, but required for fuzzy finder support
		config = function()
			local dropbar_api = require("dropbar.api")
			vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
			vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
			vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
		end,
	},
}
