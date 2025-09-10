-- check if lazyvim is installed
local lazy = require("boot.lazy")
function _G.reload(mod)
	package.loaded[mod] = nil
	return require(mod)
end

function _G.P(val)
	print(vim.inspect(val))
	return val
end

function _G.reload_debug_logger()
	for _, mod in ipairs({
		"debug_logger.utils",
		"debug_logger.handlers",
		"debug_logger",
	}) do
		package.loaded[mod] = nil
	end
	return require("debug_logger")
end
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
