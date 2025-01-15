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

-- Telescope
setup_keybinding(
	"<leader>ff",
	"n",
	"<cmd>lua require('telescope.builtin').find_files()<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding(
	"<leader>fg",
	"n",
	"<cmd>lua require('telescope.builtin').live_grep()<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding(
	"<leader>fs",
	"n",
	"<cmd>lua require('telescope.builtin').grep_string()<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding(
	"<leader>fb",
	"n",
	"<cmd>lua require('telescope.builtin').buffers()<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding(
	"<leader>ft",
	"n",
	"<cmd>lua require('telescope.builtin').treesitter()<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding(
	"<leader>ld",
	"n",
	"<cmd>lua require('telescope.builtin').lsp_definitions()<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding(
	"<leader>fq",
	"n",
	"<cmd>lua require('telescope.builtin').quickfix()<cr>",
	{ noremap = true, silent = true }
)
-- search current buffer
setup_keybinding(
	"<leader>bf",
	"n",
	"<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>",
	{ noremap = true, silent = true }
)

-- nvim_tree
setup_keybinding("<leader>tt", "n", "<cmd>NvimTreeToggle<CR>", { noremap = true, silent = true })
setup_keybinding("<leader>tc", "n", "<cmd>NvimTreeClose<CR>", { noremap = true, silent = true })

-- nvim-tmux-navigation
setup_keybinding("<C-h>", "n", "<cmd>NvimTmuxNavigateLeft<CR>", { noremap = true, silent = true })
setup_keybinding("<C-j>", "n", "<cmd>NvimTmuxNavigateDown<CR>", { noremap = true, silent = true })
setup_keybinding("<C-k>", "n", "<cmd>NvimTmuxNavigateUp<CR>", { noremap = true, silent = true })
setup_keybinding("<C-l>", "n", "<cmd>NvimTmuxNavigateRight<CR>", { noremap = true, silent = true })

-- CMP
setup_keybinding("<ESC>", "i", "<cmd>lua require('cmp').abort()<CR><ESC>", { noremap = true, silent = true })

-- Trouble
setup_keybinding("<leader>dw", "n", "<cmd>Trouble diagnostics toggle<CR>", { noremap = true, silent = true })
setup_keybinding(
	"<leader>dd",
	"n",
	"<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
	{ noremap = true, silent = true }
)
setup_keybinding("<leader>dc", "n", "<cmd>Trouble symbols toggle focus=false<cr>", { noremap = true, silent = true })
setup_keybinding(
	"<leader>dl",
	"n",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	{ noremap = true, silent = true }
)
setup_keybinding("<leader>dx", "n", "<cmd>Trouble loclist toggle<cr>", { noremap = true, silent = true })
setup_keybinding("<leader>dQ", "n", "<cmd>Trouble qflist toggle<cr>", { noremap = true, silent = true })

-- Copilot
setup_keybinding("<C-w>a", "i", 'copilot#Accept("\\<CR>")', { expr = true, silent = true, replace_keycodes = false })
