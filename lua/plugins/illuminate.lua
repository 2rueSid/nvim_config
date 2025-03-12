-- Neovim plugin for automatically highlighting other uses of the word under the cursor using either LSP, Tree-sitter, or regex matching.
return {
	"RRethy/vim-illuminate",
	config = function()
		require("illuminate").configure({
			providers = {
				"lsp",
				"treesitter",
				"regex",
			},
			delay = 100,
			filetypes_denylist = {
				"dirbuf",
				"dirvish",
				"fugitive",
			},
			under_cursor = true,
			min_count_to_highlight = 1,
			should_enable = function(bufnr)
				return true
			end,
			case_insensitive_regex = false,
		})
	end,
	lazy = false,
}
