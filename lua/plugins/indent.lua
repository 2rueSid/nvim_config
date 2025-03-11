-- This plugin adds indentation guides to Neovim. It uses Neovim's virtual text feature and no conceal
--
return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	opts = {},
	init = function()
		require("ibl").setup()
	end,
}
