local plugins = {
  {
    "neovim/nvim-lspconfig"
  },

  {
    "github/copilot.vim"
  },
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/nvim-cmp",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp_luasnip",
  "petertriho/cmp-git",
  "simrat39/rust-tools.nvim",
  "hinell/lsp-timeout.nvim",
  "kosayoda/nvim-lightbulb",
  "lukas-reineke/cmp-under-comparator",
  "alexaandru/nvim-lspupdate",
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}
  },
  -- {
  --   "lalitmee/cobalt2.nvim",
  --   event = { "ColorSchemePre" },
  --   dependencies = { "tjdevries/colorbuddy.nvim" },
  --   init = function()
  --       require("colorbuddy").colorscheme("cobalt2")
  --   end,
  -- },

  {
    'nvimdev/lspsaga.nvim',
    config = function()
        require('lspsaga').setup({})
    end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons'
    }
  }
}

local lazy = require("boot.lazy")

lazy.setup(plugins)

require("plugins.configs.lsp")(require("plugins.configs.cmp"))
require("nvim-lightbulb").setup({
  autocmd = { enabled = true }
})