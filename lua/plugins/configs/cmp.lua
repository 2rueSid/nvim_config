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
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-c>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping({
			i = function(fallback)
				if cmp.visible() and cmp.get_active_entry() then
					cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
				else
					fallback()
				end
			end,
			s = cmp.mapping.confirm({ select = true }),
			c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
		}),
	},

	sources = cmp.config.sources({
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "nvim_lsp_signature_help" },
		{ name = "nvim_lua", keyword_length = 2 },
		-- { name = "cmdline" },
		{ name = "luasnip" },
	}, { { name = "buffer" } }),
}

return options
