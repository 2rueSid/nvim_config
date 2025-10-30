---@module "codecompanion"
---@type CodeCompanion.Config
M = {}

M.extensions = {
	mcphub = {},
}

return {
	"olimorris/codecompanion.nvim",
	opts = {},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local codecompanion = require("codecompanion")

		codecompanion.setup({})
	end,
}

-- 	-- strategies = {
-- 	-- 	chat = {
-- 	-- 		adapter = "openrouter",
-- 	-- 	},
-- 	-- 	inline = {
-- 	-- 		adapter = "openrouter",
-- 	-- 	},
-- 	-- 	cmd = {
-- 	-- 		adapter = "openrouter",
-- 	-- 	},
-- 	-- },
-- 	-- adapters = {
-- 	-- 	http = {
-- 	-- 		openrouter = openrouter_adapter,
-- 	-- 	},
-- 	-- },
-- 	-- vectorcode = {
-- 	-- 	opts = {
-- 	-- 		tool_group = {
-- 	-- 			-- this will register a tool group called `@vectorcode_toolbox` that contains all 3 tools
-- 	-- 			enabled = true,
-- 	-- 			-- a list of extra tools that you want to include in `@vectorcode_toolbox`.
-- 	-- 			-- if you use @vectorcode_vectorise, it'll be very handy to include
-- 	-- 			-- `file_search` here.
-- 	-- 			extras = {},
-- 	-- 			collapse = false, -- whether the individual tools should be shown in the chat
-- 	-- 		},
-- 	-- 		prompt_library = {
-- 	-- 			{
-- 	-- 				["Test Prompt"] = {
-- 	-- 					-- this is for demonstration only.
-- 	-- 					-- "Neovim Tutor" is shipped with this plugin already,
-- 	-- 					-- and you don't need to add it in the config
-- 	-- 					-- unless you're not happy with the defaults.
-- 	-- 					project_root = vim.env.VIMRUNTIME,
-- 	-- 					file_patterns = { "lua/**/*.lua", "doc/**/*.txt" },
-- 	-- 					-- system_prompt = ...,
-- 	-- 					-- user_prompt = ...,
-- 	-- 				},
-- 	-- 			},
-- 	-- 		},
-- 	-- 		tool_opts = {
-- 	-- 			["*"] = {},
-- 	-- 			ls = {},
-- 	-- 			vectorise = {},
-- 	-- 			query = {
-- 	-- 				max_num = { chunk = -1, document = -1 },
-- 	-- 				default_num = { chunk = 50, document = 10 },
-- 	-- 				include_stderr = false,
-- 	-- 				use_lsp = true,
-- 	-- 				no_duplicate = true,
-- 	-- 				chunk_mode = false,
-- 	-- 				summarise = {
-- 	-- 					enabled = false,
-- 	-- 					adapter = nil,
-- 	-- 					query_augmented = true,
-- 	-- 				},
-- 	-- 			},
-- 	-- 			files_ls = {},
-- 	-- 			files_rm = {},
-- 	-- 		},
-- 	-- 	},
-- 	-- },
-- 	extensions = {
-- 		mcphub = {
-- 			callback = "mcphub.extensions.codecompanion",
-- 			opts = {
-- 				make_vars = true,
-- 				make_slash_commands = true,
-- 				show_result_in_chat = true,
-- 			},
-- 		},
-- 	},
-- 	display = {
-- 		action_palette = {
-- 			width = 95,
-- 			height = 10,
-- 			prompt = "Prompt ", -- Prompt used for interactive LLM calls
-- 			provider = "snacks", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
-- 			opts = {
-- 				show_default_actions = true, -- Show the default actions in the action palette?
-- 				show_default_prompt_library = true, -- Show the default prompt library in the action palette?
-- 				title = "CodeCompanion actions", -- The title of the action palette
-- 			},
-- 		},
-- 	},
-- })
