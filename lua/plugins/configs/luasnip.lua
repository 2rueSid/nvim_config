return {
	setup = function(opts)
		require("luasnip").config.set_config(opts)

		require("luasnip.loaders.from_vscode").lazy_load()
		require("luasnip.loaders.from_vscode").lazy_load({ paths = vim.g.vscode_snippets_path or "" })

		require("luasnip.loaders.from_snipmate").load()
		require("luasnip.loaders.from_snipmate").lazy_load({ paths = vim.g.snipmate_snippets_path or "" })

		require("luasnip.loaders.from_lua").load()
		require("luasnip.loaders.from_lua").lazy_load({ paths = vim.g.lua_snippets_path or "" })
	end,
}
