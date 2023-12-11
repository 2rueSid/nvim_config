

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