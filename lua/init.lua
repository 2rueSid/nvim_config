-- check if lazyvim is installed
local lazy = require("boot.lazy")

require("autogroups")
require("autocmds")
require("options")
require("utils")
require("keymaps")
require("lsp")


lazy.setup({
	root = vim.fn.stdpath("config") .. "/lib/plugins",
	lockfile = vim.fn.stdpath("config") .. "/lib/plugins/lazy-lock.json",

	defaults = { lazy = false },

	ui = {
		icons = {
			ft = "",
			lazy = "󰂠 ",
			loaded = "",
			not_loaded = "",
		},
	},

	spec = {
		import = "plugins",
	},
})

