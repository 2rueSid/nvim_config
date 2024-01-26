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

-- cmp
vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
vim.opt.shortmess = vim.opt.shortmess + { c = true }
vim.api.nvim_set_option("updatetime", 300)

-- Fixed column for diagnostics to appear
-- Show autodiagnostic popup on cursor hover_range
-- Goto previous / next diagnostic warning / error
-- Show inlay_hints more frequently
vim.cmd([[
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])
