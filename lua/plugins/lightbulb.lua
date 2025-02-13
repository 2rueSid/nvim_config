return {
	{
		"kosayoda/nvim-lightbulb",
		setup = function()
			require("nvim-lightbulb").setup({
				autocmd = { enabled = true },
			})
		end,
	},
}
