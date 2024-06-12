return {
	ensure_installed = {
		"c",
		"proto",
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
		"hcl",
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
				["ap"] = "@parameter.outer",
				["ip"] = "@parameter.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["ai"] = "@conditional.outer",
				["ii"] = "@conditional.inner",
			},
		},
		swap = {
			enable = true,
			swap_next = { ["]a"] = "@parameter.inner" },
			swap_previous = { ["[a"] = "@parameter.inner" },
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = {
				["zp"] = "@parameter.outer",
				["zb"] = "@block.outer",
			},
			goto_previous_start = {
				["zP"] = "@parameter.outer",
				["zB"] = "@block.outer",
			},
			goto_previous_end = {},
			goto_next_end = {},
			goto_next = {},
			goto_previous = {},
		},
	},
}
