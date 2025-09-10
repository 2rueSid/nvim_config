local keymap = vim.keymap

vim.g.mapleader = " "

-- UTILS
local function setup_keybinding(key, mode, cb, opts)
	assert(type(key) == "string", "Key should be set")

	if not cb then
		return
	end

	mode = mode or "n"
	cb = cb or function() end
	opts = opts or {}

	keymap.set(mode, key, cb, opts)
end

local function pos_equal(p1, p2)
	local r1, c1 = unpack(p1)
	local r2, c2 = unpack(p2)
	return r1 == r2 and c1 == c2
end

function goto_error_then_hint()
	local pos = vim.api.nvim_win_get_cursor(0)
	vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR, wrap = true })
	local pos2 = vim.api.nvim_win_get_cursor(0)
	if pos_equal(pos, pos2) then
		vim.diagnostic.goto_next({ wrap = true })
	end
end

-- Motions
setup_keybinding("<C-d>", "n", function()
	vim.api.nvim_exec('execute "normal! \\<C-d>zz"', false)
end, { noremap = true, silent = true })

setup_keybinding("<C-u>", "n", function()
	vim.api.nvim_exec('execute "normal! \\<C-u>zz"', false)
end, { noremap = true, silent = true })

-- LSP
setup_keybinding("<leader>fa", "n", "<cmd>lua vim.lsp.buf.code_action()<CR>", { noremap = true, silent = true })
setup_keybinding("<leader>ne", "n", "<cmd>lua goto_error_then_hint()<CR>", { noremap = true, silent = true })

-- nvim_tree
setup_keybinding("<leader>tt", "n", "<cmd>NvimTreeToggle<CR>", { noremap = true, silent = true })
setup_keybinding("<leader>tc", "n", "<cmd>NvimTreeClose<CR>", { noremap = true, silent = true })

-- nvim-tmux-navigation
setup_keybinding("<C-h>", "n", "<cmd>NvimTmuxNavigateLeft<CR>", { noremap = true, silent = true })
setup_keybinding("<C-j>", "n", "<cmd>NvimTmuxNavigateDown<CR>", { noremap = true, silent = true })
setup_keybinding("<C-k>", "n", "<cmd>NvimTmuxNavigateUp<CR>", { noremap = true, silent = true })
setup_keybinding("<C-l>", "n", "<cmd>NvimTmuxNavigateRight<CR>", { noremap = true, silent = true })
setup_keybinding(
	"<leader>dg",
	"n",
	"<cmd>lua require('debug_logger').log_variable()<CR>",
	{ noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>dd", function()
	reload_debug_logger().log_variable()
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>rn", function()
	return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true })
