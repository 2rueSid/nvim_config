return {
	"mrjones2014/smart-splits.nvim",
	lazy = false,
	config = function()
		local smart_splits = require("smart-splits")
		smart_splits.setup({
			at_edge = "stop",
		})
		vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left, { silent = true })
		vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down, { silent = true })
		vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up, { silent = true })
		vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right, { silent = true })
		vim.keymap.set("n", "<A-h>", smart_splits.resize_left, { silent = true })
		vim.keymap.set("n", "<A-j>", smart_splits.resize_down, { silent = true })
		vim.keymap.set("n", "<A-k>", smart_splits.resize_up, { silent = true })
		vim.keymap.set("n", "<A-l>", smart_splits.resize_right, { silent = true })
	end,
}
