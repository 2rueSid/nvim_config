return {
	-- CMP
	{
		"saghen/blink.cmp",
		event = "InsertEnter",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"xzbdmw/colorful-menu.nvim",
			{ "L3MON4D3/LuaSnip", version = "v2.*" },
		},
		lazy = true,
		version = "*",
		opts = {
			keymap = {
				preset = "default",

				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<Esc>"] = {
					function(cmp)
						cmp.cancel()
						vim.cmd("stopinsert")
					end,
					"fallback",
				},
				["<CR>"] = {
					"select_and_accept",
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

				documentation = {
					auto_show = true,
					auto_show_delay_ms = 600,
					window = { border = "single" },
				},

				ghost_text = {
					enabled = true,
					show_with_selection = true,
				},

				menu = {
					enabled = true,
					min_width = 30,
					max_height = 15,
					border = "single",
					winblend = 10,

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
						preselect = false,
						auto_insert = true,
					},
					max_items = 25,
				},
			},

			signature = { enabled = true, window = { border = "single" } },

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				cmdline = {},
			},

			appearance = {
				kind_icons = require("icons").lsp_icons,
			},
			snippets = { preset = "luasnip" },
		},
	},
}
