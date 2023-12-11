local plugins = {
  {
    "neovim/nvim-lspconfig"
  },
  "alexaandru/nvim-lspupdate",
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}
  },
}

local lazy = require("boot.lazy")

lazy.setup(plugins)
