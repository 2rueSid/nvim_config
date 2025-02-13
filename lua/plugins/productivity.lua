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

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, "nvim-lua/plenary.nvim" },
		tag = "0.1.8",
		cmd = "Telescope",
		opts = {
			defaults = {
				vimgrep_arguments = {
					"rg",
					"-L",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				prompt_prefix = " \u{f022e}  ",
				selection_caret = "  ",
				entry_prefix = "  ",
				initial_mode = "insert",
				selection_strategy = "reset",
				sorting_strategy = "ascending",
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.55,
						results_width = 0.8,
					},
					vertical = {
						mirror = false,
					},
					width = 0.87,
					height = 0.80,
					preview_cutoff = 120,
				},
				file_sorter = require("telescope.sorters").get_fuzzy_file,
				generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
				path_display = { "truncate" },
				winblend = 0,
				border = {},
				borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				color_devicons = true,
				set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
				file_previewer = require("telescope.previewers").vim_buffer_cat.new,
				grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
				qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
				-- Developer configurations: Not meant for general override
				buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
				mappings = {
					n = { ["q"] = require("telescope.actions").close },
				},
			},

			extensions_list = { "fzf" },
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				ast_grep = {
					command = {
						"sg",
						"--json=stream",
					},
					grep_open_files = false,
					lang = nil,
				},
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)

			-- load extensions
			for _, ext in ipairs(opts.extensions_list) do
				telescope.load_extension(ext)
			end
		end,
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
