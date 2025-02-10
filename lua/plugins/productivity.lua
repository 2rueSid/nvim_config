return {
	-- CMP
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"xzbdmw/colorful-menu.nvim",
			"mikavilpas/blink-ripgrep.nvim",
			{ "L3MON4D3/LuaSnip", version = "v2.*" },
			{ "echasnovski/mini.nvim", version = "*" },
		},

		signature = { enabled = true },

		version = "*",
		opts = {
			keymap = {

				-- 'default' for mappings similar to built-in completion
				-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
				-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
				-- See the full "keymap" documentation for information on defining your own keymap.
				preset = "default",

				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<Esc>"] = {
					"cancel",
					function()
						vim.cmd("stopinsert")
					end,
					"fallback",
				},
				["<CR>"] = {
					"select_and_accept",
					function() end,
					"fallback",
				},

				["<C-j>"] = { "scroll_documentation_up", "fallback" },
				["<C-k>"] = { "scroll_documentation_down", "fallback" },

				["<C-h>"] = { "snippet_forward", "fallback" },
				["<C-l>"] = { "snippet_backward", "fallback" },

				cmdline = {
					preset = "enter",
				},
			},

			completion = {
				keyword = { range = "full" },
				accept = {
					create_undo_point = true,
					resolve_timeout_ms = 100,
					auto_brackets = {
						enabled = true,
						default_brackets = { "(", ")" },
						override_brackets_for_filetypes = {},
						kind_resolution = {
							enabled = true,
							blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
						},
						semantic_token_resolution = {
							enabled = true,
							blocked_filetypes = { "java" },
							timeout_ms = 400,
						},
					},
				},

				documentation = {
					auto_show = true,
					auto_show_delay_ms = 500,
					window = { border = "single" },
				},

				ghost_text = {
					enabled = true,
				},
				menu = {
					enabled = true,
					min_width = 30,
					max_height = 15,
					border = "single",
					winblend = 0,
					winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
					-- Keep the cursor X lines away from the top/bottom of the window
					scrolloff = 2,
					-- Note that the gutter will be disabled when border ~= 'none'
					scrollbar = true,
					-- Which directions to show the window,
					-- falling back to the next direction when there's not enough space
					direction_priority = { "s", "n" },

					-- Whether to automatically show the window when new completion items are available
					auto_show = true,

					-- Screen coordinates of the command line
					cmdline_position = function()
						if vim.g.ui_cmdline_pos ~= nil then
							local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
							return { pos[1] - 1, pos[2] }
						end
						local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
						return { vim.o.lines - height, 0 }
					end,

					draw = {
						treesitter = { "lsp" },

						columns = {
							{ "label", gap = 1 },
							{ "source_name", gap = 0.5 },
							{ "kind_icon", gap = 0.2 },
							{ "kind" },
						},
						components = {
							label = {
								text = function(ctx)
									return require("colorful-menu").blink_components_text(ctx)
								end,
								highlight = function(ctx)
									return require("colorful-menu").blink_components_highlight(ctx)
								end,
							},
						},
					},
				},

				list = {
					selection = {
						auto_insert = true,

						preselect = function(ctx)
							return ctx.mode ~= "cmdline" and not require("blink.cmp").snippet_active({ direction = 1 })
						end,
					},
				},
			},

			signature = { enabled = true, window = { border = "single" } },

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				-- "ripgrep"
				-- providers = {
				-- 	ripgrep = {
				-- 		module = "blink-ripgrep",
				-- 		name = "Ripgrep",
				-- 		opts = {
				-- 			prefix_min_len = 3,
				-- 			context_size = 5,
				-- 			max_filesize = "1M",
				-- 			project_root_marker = ".git",
				-- 			project_root_fallback = true,
				-- 			search_casing = "--ignore-case",
				-- 			additional_rg_options = {},
				-- 			fallback_to_regex_highlighting = true,
				-- 			ignore_paths = {},
				-- 			additional_paths = {},
				-- 			debug = false,
				-- 		},
				-- 		transform_items = function(_, items)
				-- 			for _, item in ipairs(items) do
				-- 				-- example: append a description to easily distinguish rg results
				-- 				item.labelDetails = {
				-- 					description = "(rg)",
				-- 				}
				-- 			end
				-- 			return items
				-- 		end,
				-- 	},
				-- },
			},

			appearance = {
				highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),

				nerd_font_variant = "mono",
				kind_icons = {
					Text = "󰉿",
					Method = "󰊕",
					Function = "󰊕",
					Constructor = "󰒓",

					Field = "󰜢",
					Variable = "󰆦",
					Property = "󰖷",

					Class = "󱡠",
					Interface = "󱡠",
					Struct = "󱡠",
					Module = "󰅩",

					Unit = "󰪚",
					Value = "󰦨",
					Enum = "󰦨",
					EnumMember = "󰦨",

					Keyword = "󰻾",
					Constant = "󰏿",

					Snippet = "󱄽",
					Color = "󰏘",
					File = "󰈔",
					Reference = "󰬲",
					Folder = "󰉋",
					Event = "󱐋",
					Operator = "󰪚",
					TypeParameter = "󰬛",
				},
			},
			snippets = { preset = "luasnip" },
		},
	},
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
		lazy = false,
	},
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
