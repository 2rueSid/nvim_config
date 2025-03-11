return {
	"zbirenbaum/copilot.lua",
	init = function()
		require("copilot").setup({
			suggestion = {
				enabled = true,
				auto_trigger = true,
				hide_during_completion = false,
				debounce = 40,
				keymap = {
					accept = "<C-w>a",
					next = "<C-w>n",
				},
			},
			filetypes = {
				yaml = true,
				markdown = true,
			},
			panel = {
				enabled = true,
				auto_refresh = false,
				keymap = {
					open = "<C-w>e",
				},
			},
		})
	end,
}
