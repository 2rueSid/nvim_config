

local plugins = {
  "neovim/nvim-lspconfig",
  "nvim-lua/plenary.nvim",
  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
        local tree_sitter = require("plugins.configs.treesitter")
        require("nvim-treesitter.configs").setup(tree_sitter)
    end
  },
  "alexaandru/nvim-lspupdate",
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
      require("nvim-tree").setup()
    end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  -- status line
    {
        "sontungexpt/sttusline",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = { "BufEnter" },
        config = function(_, opts)
            require("sttusline").setup {
                statusline_color = "#FFC0CB",

                laststatus = 3,
                disabled = {
                    filetypes = {
                    },
                    buftypes = {
                    },
                },
                components = {
                    "mode",
                    "filename",
                    "git-branch",
                    "git-diff",
                    "%=",
                    "diagnostics",
                    "lsps-formatters",
                    "indent",
                    "pos-cursor",
                    "pos-cursor-progress",
                },
            }
        end,
  },
  -- tabline
  {
  'akinsho/bufferline.nvim',
   version = "*",
   dependencies = 'nvim-tree/nvim-web-devicons'
  },
   {
    'Bekaboo/dropbar.nvim',
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim'
    }
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
}

-- check if lazyvim installed
local lazy = require("boot.lazy")
lazy.setup(plugins)

require("harpoon").setup()