local default = {
  {
    "lalitmee/cobalt2.nvim",
    event = { "ColorSchemePre" },
    dependencies = { "tjdevries/colorbuddy.nvim" },
    init = function()
        require("colorbuddy").colorscheme("cobalt2")
    end,
  },
}

local lazy = require("boot.lazy")

lazy.setup(default)