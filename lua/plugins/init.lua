local plugins = {
	"nvim-lua/plenary.nvim",
	-- mason
	{
		"williamboman/mason.nvim",
		config = function()
			local config = require("plugins.configs.mason")
			require("mason").setup(config)
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			local config = require("plugins.configs.mason_lsp")
			require("mason-lspconfig").setup(config)
		end,
	},
	{
		"alexghergh/nvim-tmux-navigation",
		config = function()
			require("nvim-tmux-navigation").setup({})
		end,
	},
	-- LSP
	{
		"simrat39/rust-tools.nvim",
		lazy = false,
		ft = ".rs",
		config = function()
			local rt = require("rust-tools")

			rt.setup({
				server = {
					on_attach = function(_, bufnr)
						-- Hover actions
						vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
						-- Code action groups
						vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
					end,
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			{ "antosha417/nvim-lsp-file-operations", config = true },
			"ray-x/lsp_signature.nvim",
			"jose-elias-alvarez/null-ls.nvim",
			"RRethy/vim-illuminate",
		},
		config = function()
			require("plugins.configs.lsp_config")
		end,
	},
	-- Formatter
	{
		"mhartington/formatter.nvim",
		config = function()
			local opts = require("plugins.configs.formatter")
			require("formatter").setup(opts)
		end,
		lazy = false,
	},
	-- Linter
	{
		"mfussenegger/nvim-lint",
		lazy = false,
		-- event = { "BufReadPre", "BufNewFile" },
		config = function()
			local opts = require("plugins.configs.linters")
			require("lint").linters_by_ft = opts
		end,
	},
	-- Trouble
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
	},
	-- CMP
	{
		"hrsh7th/nvim-cmp",
		-- for insert mode enable cmp
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				version = "v2.*",
				build = "make install_jsregexp",
				dependencies = "rafamadriz/friendly-snippets",
				opts = { history = true, updateevents = "TextChanged,TextChangedI" },
				config = function(_, opts)
					require("plugins.configs.luasnip").setup(opts)
				end,
			},
			{
				"windwp/nvim-autopairs",
				opts = {
					fast_wrap = {},
					disable_filetype = { "TelescopePrompt", "vim" },
				},
				config = function(_, opts)
					require("nvim-autopairs").setup(opts)
					local cmp_autopairs = require("nvim-autopairs.completion.cmp")
					require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
				end,
			},
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
		},

		opts = function()
			return require("plugins.configs.cmp")
		end,
		config = function(_, opts)
			require("cmp").setup(opts)
		end,
		lazy = false,
	},

	-- Auto Session
	{
		"rmagatti/auto-session",
		config = function()
			local auto_session = require("auto-session")

			auto_session.setup({
				auto_restore_enabled = true,
			})
		end,
		lazy = false,
	},
	-- Multiline
	{
		"mg979/vim-visual-multi",
		lazy = false,
	},
	-- comments
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
		lazy = false,
	},
	-- ui
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
		config = function()
			local opts = require("plugins.configs.lualine")
			require("lualine").setup(opts)
		end,
	},
	{
		"utilyre/barbecue.nvim",
		name = "barbecue",
		version = "*",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons",
		},
		opts = require("plugins.configs.barbecue"),
		config = function(_, opts)
			require("barbecue").setup(opts)
		end,
		lazy = false,
	},
	-- Theme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		opts = require("plugins.configs.catpuccin"),
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
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
				init = function()
					-- PERF: no need to load the plugin, if we only need its queries for mini.ai
					local plugin = require("lazy.core.config").spec.plugins["nvim-treesitter"]
					local opts = require("lazy.core.plugin").values(plugin, "opts", false)
					local enabled = false
					if opts.textobjects then
						for _, mod in ipairs({ "move", "select", "swap", "lsp_interop" }) do
							if opts.textobjects[mod] and opts.textobjects[mod].enable then
								enabled = true
								break
							end
						end
					end
					if not enabled then
						require("lazy.core.loader").disable_rtp_plugin("nvim-treesitter-textobjects")
					end
				end,
			},
		},
	},
	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
		cmd = "Telescope",
		opts = function()
			return require("plugins.configs.telescope")
		end,
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)

			-- load extensions
			for _, ext in ipairs(opts.extensions_list) do
				telescope.load_extension(ext)
			end
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
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup()
		end,
	},
	{
		"zeioth/garbage-day.nvim",
		dependencies = "neovim/nvim-lspconfig",
		event = "VeryLazy",
		opts = {},
	},
	{
		"max397574/better-escape.nvim",
		config = function()
			require("better_escape").setup({
				mapping = { "jk", "jj" },
				timeout = vim.o.timeoutlen,
				clear_empty_lines = false,
				keys = "<Esc>",
			})
		end,
	},
	{
		"Exafunction/codeium.vim",
		event = "BufEnter",
	},
}

-- check if lazyvim installed
local lazy = require("boot.lazy")
local lazy_opts = require("plugins.configs.lazyvim")
lazy.setup(plugins, lazy_opts)

require("harpoon").setup()
