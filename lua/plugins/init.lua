local plugins = {
	"nvim-lua/plenary.nvim",
	-- mason
	{
		"williamboman/mason.nvim",
		config = function()
			local config = require("plugins.configs.mason")
			require("mason").setup(config)
		end,
		lazy = false,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			local config = require("plugins.configs.mason_lsp")
			require("mason-lspconfig").setup(config)
		end,
		lazy = false,
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
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-signature-help",
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
				auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
			})

			local keymap = vim.keymap

			keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
			keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
		end,
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
  	"zeioth/garbage-day.nvim",
  	dependencies = "neovim/nvim-lspconfig",
  	event = "VeryLazy",
  	opts = {}
	},
	-- {
	--   "folke/which-key.nvim",
	--   event = "VeryLazy",
	--   init = function()
	--     vim.o.timeout = true
	--     vim.o.timeoutlen = 300
	--   end,
	--   opts = {},
	--   lazy=false
	-- }
}

-- check if lazyvim installed
local lazy = require("boot.lazy")
local lazy_opts = require("plugins.configs.lazyvim")
lazy.setup(plugins, lazy_opts)

require("harpoon").setup()
-- require("plugins.configs.cmp").setup()
