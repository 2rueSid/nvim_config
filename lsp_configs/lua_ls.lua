---@type vim.lsp.Config
return vim.lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylua.toml",
		"stylua.toml",
		"selene.toml",
		"selene.yml",
		".git",
	},

	on_init = function(client)
		-- Only extend once Neovim config is the workspace
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if path ~= vim.fn.stdpath("config") then
				return
			end
		end

		local settings = {
			runtime = {
				version = "LuaJIT",
				path = { "lua/?.lua", "lua/?/init.lua", "init.lua" },
			},
			diagnostics = { globals = { "vim" } },
			hint = { enable = true, setType = true, paramType = true },
			workspace = {
				checkThirdParty = false,
				maxPreload = 100000,
				preloadFileSize = 10000,
				useGitIgnore = true,
				library = {
					vim.env.VIMRUNTIME,
					"${3rd}/luv/library",
					vim.fn.expand("$VIMRUNTIME/lua"),
					vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
					vim.fn.stdpath("config") .. "/lib/plugins",
					vim.fn.stdpath("data") .. "/lazy",
				},
			},
			format = { enable = false },
		}

		client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, { Lua = settings })
	end,

	settings = { Lua = {} },
})

-- -- Install with
-- -- mac: brew install lua-language-server
--
-- ---@type vim.lsp.Config
-- return {
-- 	cmd = { "lua-language-server" },
-- 	filetypes = { "lua" },
-- 	root_markers = {
-- 		".luarc.json",
-- 		".luarc.jsonc",
-- 		".luacheckrc",
-- 		".stylua.toml",
-- 		"stylua.toml",
-- 		"selene.toml",
-- 		"selene.yml",
-- 		".git",
-- 	},
-- 	on_init = function(client)
-- 		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
-- 			format = { enable = false },
-- 			hint = {
-- 				enable = true,
-- 				setType = true,
-- 				paramType = true,
-- 			},
-- 			diagnostics = {
-- 				globals = { "vim" },
-- 			},
--
-- 			runtime = {
-- 				version = "LuaJIT",
-- 				path = {
-- 					"lua/?.lua",
-- 					"lua/?/init.lua",
-- 					"init.lua",
-- 				},
-- 			},
-- 			-- Make the server aware of Neovim runtime files
-- 			workspace = {
-- 				checkThirdParty = false,
-- 				maxPreload = 100000,
-- 				preloadFileSize = 10000,
-- 				useGitIgnore = true,
-- 				library = {
-- 					vim.env.VIMRUNTIME,
-- 					"${3rd}/luv/library",
-- 					vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
-- 					vim.fn.expand("$VIMRUNTIME/lua"),
-- 					vim.fn.stdpath("config") .. "/lib/plugins/",
-- 					vim.fn.stdpath("data") .. "/lazy",
-- 					-- [vim.fn.expand("$VIMRUNTIME/lua")] = true,
-- 					-- [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
-- 					-- [vim.fn.stdpath("config") .. "/lib/plugins/"] = true,
-- 					-- [vim.fn.stdpath("data") .. "/lazy"] = true,
--
-- 					-- Depending on the usage, you might want to add additional paths
-- 					-- here.
-- 					-- '${3rd}/luv/library'
-- 					-- '${3rd}/busted/library'
-- 				},
-- 			},
-- 		})
-- 	end,
-- 	settings = {
-- 		Lua = {},
-- 	},
-- }
