local autocmd = vim.api.nvim_create_autocmd

autocmd("InsertLeave", {
	pattern = "*",
	callback = function()
		vim.diagnostic.open_float(nil, {
			focusable = false,
			border = vim.g.floating_window_border,
			source = "if_many",
		})
	end,
})

-- Linter when on switching to normal mode;
autocmd({ "InsertLeave", "BufWritePost" }, {
	callback = function()
		local lint_status, lint = pcall(require, "lint")
		if lint_status then
			lint.try_lint()
		end
	end,
})

-- LuaSnip
autocmd("InsertLeave", {
	callback = function()
		if
			require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
			and not require("luasnip").session.jump_active
		then
			require("luasnip").unlink_current()
		end
	end,
})
