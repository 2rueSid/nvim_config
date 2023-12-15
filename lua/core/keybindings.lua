local builtin = require("telescope.builtin")
local harpoon = require("harpoon")
local nvim_tree = require("nvim-tree.api")

local keymap = vim.keymap

local function setup_keybinding(key, mode, cb, opts)
	assert(type(key) == "string", "Key should be set")

	mode = mode or "n"
	cb = cb or function() end
	opts = opts or {}

	keymap.set(mode, key, cb, opts)
end

local Keybindings = {
	Buildin = {
		next_file_buffer = {
			key = "<C-n>",
			cb = function()
				vim.cmd("bnext")
			end,
			opts = {},
			desc = "Get Next file in a buffer",
		},
		prev_file_buffer = {
			key = "<C-p>",
			cb = function()
				vim.cmd("bprev")
			end,
			desc = "Get previous file in a buffer",
		},
		go_down = {
			key = "<C-d>",
			cb = function()
				vim.api.nvim_exec("execute 'normal! \\<C-d>zz'", false)
			end,
			opts = { noremap = true, silent = true },
			desc = "Go donw and center cursor on the screen",
		},
		go_up = {
			key = "<C-u>",
			cb = function()
				vim.api.nvim_exec("execute 'normal! \\<C-u>zz'", false)
			end,
			opts = { noremap = true, silent = true },
			desc = "Go up and center cursor on the screen",
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
			desc = " Search for a string in your current working directory and get results live as you type, respects .gitignore. (Requires ripgrep)",
		},
		search_str_cursor = {
			key = "<leader>fs",
			cb = builtin.grep_string,
			desc = " Searches for the string under your cursor or selection in your current working directory",
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
