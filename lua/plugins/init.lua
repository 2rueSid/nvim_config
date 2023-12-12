local plugins = {
  "neovim/nvim-lspconfig",
  "nvim-lua/plenary.nvim",
  "alexaandru/nvim-lspupdate",
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
  {
    'NvChad/nvim-colorizer.lua',
    lazy=false,
    config = function ()
      require 'colorizer'.setup()
    end
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
    end
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
  opts = {}
}
}

-- check if lazyvim installed
local lazy = require("boot.lazy")
local lazy_opts = require("plugins.configs.lazyvim")
lazy.setup(plugins, lazy_opts)

require("harpoon").setup()
