local plugins = {
  "nvim-lua/plenary.nvim",
  -- mason
  {
    "williamboman/mason.nvim",
    config = function ()
      local config = require("plugins.configs.mason")
      require "mason".setup(config)
    end,
    lazy=false
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function ()
      local config = require("plugins.configs.mason_lsp")
      require "mason-lspconfig".setup(config)
    end,
    lazy=false
  },
  -- Formatter
  {
    "mhartington/formatter.nvim",
    config = function ()
      local opts = require("plugins.configs.formatter")
      require "formatter".setup(opts)
    end,
    lazy=false
  },
  -- Linter
  {
    "mfussenegger/nvim-lint",
    lazy=false,
    event = { "BufReadPre", "BufNewFile" },
    config = function ()
      local opts = require("plugins.configs.linters")
      require("lint").linters_by_ft = opts
    end
  },
   -- CMP
  {
	  "L3MON4D3/LuaSnip",
	  version = "v2.*",
    build = "make install_jsregexp",
    lazy=false,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy=false,
  },
  {
    "hrsh7th/cmp-buffer",
    lazy=false,
  },
  {
    "hrsh7th/cmp-path",
    lazy=false,
  },
  {
    "hrsh7th/cmp-cmdline",
    lazy=false,
  },
  {
    "hrsh7th/nvim-cmp",
    lazy=false,
    config = function ()
      require "plugins.configs.cmp".setup()
    end
  },
  {
    "onsails/lspkind.nvim",
    lazy=false
  },
  {
    "saadparwaiz1/cmp_luasnip",
    lazy=false
  },
  -- LSP
  {
    "neovim/nvim-lspconfig",
    lazy=false,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "antosha417/nvim-lsp-file-operations", config = true },
    },
    config = function ()
      require "plugins.configs.lsp_config".setup()
    end
  },
  "alexaandru/nvim-lspupdate",
  -- Auto Session
  {
    "rmagatti/auto-session",
    config = function ()
      local auto_session = require("auto-session")

    auto_session.setup({
      auto_restore_enabled = true,
      auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

    local keymap = vim.keymap

    keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
    keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
    end,
    lazy=false
  },
  -- comments
  {
    'numToStr/Comment.nvim',
    config = function ()
      require "Comment".setup()
    end,
    lazy=false
  },
  -- ui
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy=false,
    config = function ()
      local opts = require("plugins.configs.lualine")
      require 'lualine'.setup(opts)
    end
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
    config = function (_, opts)
      require("barbecue").setup(opts)
    end,
    lazy=false,
  },
  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = require("plugins.configs.catpuccin"),
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme "catppuccin"
    end
  },
  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
        local tree_sitter = require("plugins.configs.treesitter")
        require("nvim-treesitter.configs").setup(tree_sitter)
    end
  },
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
    cmd = "Telescope",
    opts = function()
      return require "plugins.configs.telescope"
    end,
    config = function(_, opts)
      local telescope = require "telescope"
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
    lazy=false
  },
  {
    "RRethy/vim-illuminate",
    config = function()
      require('illuminate').configure({
      providers = {
          'lsp',
          'treesitter',
          'regex',
      },
      delay = 100,
      filetypes_denylist = {
          'dirbuf',
          'dirvish',
          'fugitive',
      },
      under_cursor = true,
      min_count_to_highlight = 1,
      should_enable = function(bufnr) return true end,
      case_insensitive_regex = false,
      })
    end,
    lazy=false
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
    lazy=false
  }
}

-- check if lazyvim installed
local lazy = require("boot.lazy")
local lazy_opts = require("plugins.configs.lazyvim")
lazy.setup(plugins, lazy_opts)

require("harpoon").setup()
-- require("plugins.configs.cmp").setup()
