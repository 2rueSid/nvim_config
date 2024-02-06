local cmp = require("cmp")
local C = require("constants")

local formatting_style = {
	fields = { "menu", "abbr", "kind" },

	format = function(_, item)
		local icons = C.icons.lsp
		local icon = icons[item.kind] or ""

		icon = " " .. icon .. " "
		item.menu = "   (" .. item.kind .. ")"
		item.kind = icon

		return item
	end,
}

local options = {
	completion = {
		completeopt = "menu,menuone",
	},

	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},

	formatting = formatting_style,

	mapping = {
		["<Tab>"] = cmp.mapping.select_next_item(),
		["<S-Tab>"] = cmp.mapping.select_prev_item(),
		["<C-]>"] = cmp.mapping.scroll_docs(-4),
		["<C-[>"] = cmp.mapping.scroll_docs(4),
		["<C-e>"] = cmp.mapping.close(),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Insert,
			select = false,
		}),
	},

	sources = cmp.config.sources({
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "nvim_lsp_signature_help" },
		{ name = "nvim_lua", keyword_length = 2 },
		{ name = "buffer" },
		{ name = "luasnip" },
	}),
}

return options
