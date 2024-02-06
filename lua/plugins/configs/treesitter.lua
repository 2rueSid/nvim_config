return {
	ensure_installed = {
		"c",
		"lua",
		"vim",
		"vimdoc",
		"query",
		"rust",
		"tsx",
		"typescript",
		"python",
		"yaml",
		"go",
		"javascript",
		"toml",
		"terraform",
		"json",
		"bash",
	},

	auto_install = true,

	highlight = {
		enable = true,
		use_languagetree = true,
		additional_vim_regex_highlighting = false,
	},
	indent = { enable = true },
	rainbow = {
		enable = true,
		extended_mode = true,
		max_file_lines = nil,
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
			goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" },
		},
		lsp_interop = {
			enable = true,
			border = "none",
			peek_definition_code = {
				["gnf"] = "@function.outer",
				["gnc"] = "@class.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = { ["]a"] = "@parameter.inner" },
			swap_previous = { ["[a"] = "@parameter.inner" },
		},
	},
}
