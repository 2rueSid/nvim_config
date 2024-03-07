local builtin = require("telescope.builtin")
local harpoon = require("harpoon")
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

local Keybindings = {
	Buildin = {
		next_file_buffer = {
			key = "<C-nb>",
			cb = function()
				vim.cmd("bnext")
			end,
			opts = {},
			desc = "Get Next file in a buffer",
		},
		prev_file_buffer = {
			key = "<C-pb>",
			cb = function()
				vim.cmd("bprev")
			end,
			desc = "Get previous file in a buffer",
		},
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
	},
	Harpoon = {
		append = {
			key = "<leader>a",
			cb = function()
				harpoon.ui.toggle_quick_menu(harpoon:list())
			end,
			desc = "Append file to the harpoon list",
		},
		list = {
			key = "<C-e>",
			cb = function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end,
			desc = "Toggle harppon list",
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
	SessionManager = {
		restore = {
			key = "<leader>wr",
			cb = function()
				vim.cmd("SessionRestore")
			end,
			desc = "Restore session for cwd",
		},
		save_session = {
			key = "<leader>ws",
			cb = function()
				vim.cmd("SessionSave")
			end,
			desc = "Save session for auto session root dir",
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
	Sessions = {
		restore = {
			key = "<C-sr>",
			cb = "<cmd>SessionRestore<CR>",
			desc = "Restore session for cwd",
		},
		save = {
			key = "<C-sa>",
			cb = "<cmd>SessionSave<CR>",
			desc = "Save session for cwd",
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
			cb = function()
				require("trouble").toggle("workspace_diagnostics")
			end,
		},
		document_diagnostics = {
			key = "<leader>dd",
			desc = "show lsp diagnostic for the document",
			cb = function()
				require("trouble").toggle("document_diagnostics")
			end,
		},
	},
	Refactor = {
		print_var = {
			key = "<C-P>",
			desc = "print var",
			cb = function()
				require("refactoring").debug.print_var()
			end,
		},

		clear_print = {
			key = "<C-C>",
			desc = "clear pritns",
			cb = function()
				require("refactoring").debug.cleanup({})
			end,
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
