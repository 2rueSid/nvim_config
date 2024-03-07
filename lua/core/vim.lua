vim.o.termguicolors = true
-- show relative numbers, and current col as a absolute
vim.wo.relativenumber = true
vim.opt.number = true

-- Set tab width to 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Formatter on Save
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })
autocmd("BufWritePost", {
	group = "__formatter__",
	command = ":FormatWrite",
})

-- Linter when on swithing to normal mode;
vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
	callback = function()
		local lint_status, lint = pcall(require, "lint")
		if lint_status then
			lint.try_lint()
		end
	end,
})

-- use sys clipboard
vim.opt.clipboard:append("unnamedplus")

vim.g.floating_window_border = {
	"╭",
	"─",
	"╮",
	"│",
	"╯",
	"─",
	"╰",
	"│",
}

local disabled_built_ins = {
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	"logipat",
	"rrhelper",
	"spellfile_plugin",
	"matchit",
}

for _, plugin in pairs(disabled_built_ins) do
	vim.g["loaded_" .. plugin] = 1
end

function NvimTreeTrash()
	local lib = require("nvim-tree.lib")
	local node = lib.get_node_at_cursor()
	local trash_cmd = "trash "

	local function get_user_input_char()
		local c = vim.fn.getchar()
		return vim.fn.nr2char(c)
	end

	print("Trash " .. node.name .. " ? y/n")

	if get_user_input_char():match("^y") and node then
		vim.fn.jobstart(trash_cmd .. node.absolute_path, {
			detach = true,
			on_exit = function(job_id, data, event)
				lib.refresh_tree()
			end,
		})
	end

	vim.api.nvim_command("normal :esc<CR>")
end

vim.g.nvim_tree_bindings = {
	{ key = "d", cb = ":lua NvimTreeTrash()<CR>" },
}
vim.g.codeium_disable_bindings = 1
