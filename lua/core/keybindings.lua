local builtin = require("telescope.builtin")
local nvim_tree = require("nvim-tree.api")
local nvim_tmux_nav = require("nvim-tmux-navigation")
local keymap = vim.keymap

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

-- TODO:: Cleanup
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

local Keybindings = {
	Buildin = {
		go_down = {
			key = "<C-d>",
			cb = function()
				vim.api.nvim_exec('execute "normal! \\<C-d>zz"', false)
			end,
			opts = { noremap = true, silent = true },
			desc = "Go donw and center cursor on the screen",
		},
		go_up = {
			key = "<C-u>",
			cb = function()
				vim.api.nvim_exec('execute "normal! \\<C-u>zz"', false)
			end,
			opts = { noremap = true, silent = true },
			desc = "Go up and center cursor on the screen",
		},
		lsp_code_actions = {
			key = "<leader>fa",
			cb = "<cmd>lua vim.lsp.buf.code_action()<CR>",
		},
		goto_next_diagnostic = {
			key = "<leader>ne",
			cb = "<cmd>lua goto_error_then_hint()<CR>",
		},
	},
	Codeium = {
		accept = {
			key = "<C-A>",
			cb = function()
				return vim.fn["codeium#Accept"]()
			end,
			mode = "i",
			opts = { expr = true, silent = true },
			desc = "Accept suggestion",
		},
		reject = {
			key = "<C-R>",
			cb = function()
				return vim.fn["codeium#Clear"]()
			end,
			mode = "i",
			opts = { expr = true, silent = true },
			desc = "Reject suggestion",
		},
	},
	Telescope = {
		list_files = {
			key = "<leader>ff",
			cb = builtin.find_files,
			desc = "List files in your current woring directory, respects .gitignore",
		},
		search_str = {
			key = "<leader>fg",
			cb = builtin.live_grep,
			desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore. (Requires ripgrep)",
		},
		search_str_cursor = {
			key = "<leader>fs",
			cb = builtin.grep_string,
			desc = "Searches for the string under your cursor or selection in your current working directory",
		},
		open_buffers = {
			key = "<leader>fb",
			cb = builtin.buffers,
			desc = "Lists open buffers in current neovim instance",
		},
		show_signatures = {
			key = "<leader>ft",
			cb = builtin.treesitter,
			desc = "Lists Function names, variables, from Treesitter!",
		},
		lsp_word_def = {
			key = "<leader>ld",
			cb = builtin.lsp_definitions,
			desc = "Goto definition of the word under the cursor",
		},
		quick_fix = {
			key = "<leader>fq",
			cb = builtin.quickfix,
			desc = "List quickfix list",
		},
	},
	NTree = {
		tree_open = {
			key = "<leader>tt",
			cb = function()
				nvim_tree.tree.open()
			end,
			desc = "Open file explore",
		},
		close_tree = {
			key = "<leader>tc",
			cb = function()
				nvim_tree.tree.close()
			end,
			desc = "Close file explore",
		},
	},
	CheatSheet = {
		open = {
			key = "<leader>ch",
			cb = ":lua show_cheatsheet()<CR>",
			opts = { noremap = true, silent = true },
			desc = "Open Cheat Sheet",
		},
	},
	Tmux = {
		left = {
			key = "<C-h>",
			cb = nvim_tmux_nav.NvimTmuxNavigateLeft,
			desc = "Switch to pane to the left",
		},
		down = {
			key = "<C-j>",
			cb = nvim_tmux_nav.NvimTmuxNavigateDown,
			desc = "Swtich to the bottom pane",
		},
		up = {
			key = "<C-k>",
			cb = nvim_tmux_nav.NvimTmuxNavigateUp,
			desc = "Switch to the upper pane",
		},
		right = {
			key = "<C-l>",
			cb = nvim_tmux_nav.NvimTmuxNavigateRight,
			desc = "Switch to the right pane",
		},
	},
	CMP = {
		confirm = {
			key = "<CR>",
			desc = "select current cmp item",
			mode = "i",
		},
		abort = {
			key = "<C-e>",
			desc = "Exit cmp window",
			mode = "i",
		},
		next_item = {
			key = "<Tab>",
			desc = "Next cmp item",
			mode = "i",
		},
		prev_item = {
			key = "<S-Tab>",
			desc = "Prev cmp item",
			mode = "i",
		},
		hard_abort = {
			key = "<ESC>",
			mode = "i",
			cb = "<cmd>lua require('cmp').abort()<CR><ESC>",
			desc = "Close cmp on ESC",
			opts = {
				noremap = true,
				silent = true,
			},
		},
	},
	Treesitter = {
		next_br = {
			key = "]m",
			decs = "go to next bracket",
		},
		next_end_br = {
			key = "]M",
			desc = "go to next end bracket",
		},
		prev_br = {
			key = "[m",
			desc = "go to prev bracket",
		},
		prev_env_br = {
			key = "[[",
			desc = "go to prev end bracket",
		},
	},
	Trouble = {
		workspace_diagnostic = {
			key = "<leader>dw",
			desc = "show lsp diagnostic for the workspace",
			cb = "<cmd>Trouble diagnostics toggle<cr>",
		},
		document_diagnostics = {
			key = "<leader>dd",
			desc = "show lsp diagnostic for the document",
			cb = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		},
	},
	Copilot = {
		apply = {
			key = "<C-w>a",
			cb = 'copilot#Accept("\\<CR>")',
			desc = "Copilot accepts sggestion",
			mode = "i",
			opts = { expr = true, silent = true, replace_keycodes = false },
		},
	},
}

function Setup()
	local C = require("constants")
	-- LEADER KEY
	vim.g.mapleader = C.keys.LEADER_KEY
	for _, value in pairs(Keybindings) do
		for _, table in pairs(value) do
			setup_keybinding(table.key, table.mode or "n", table.cb, table.opts or {})
		end
	end
end

return { keybindings = Keybindings, setup = Setup }
