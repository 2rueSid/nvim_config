local icons = require("icons").lsp_icons

-- Picker, finder, etc.
return {
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		keys = {
			{
				"<leader>fG",
				function()
					require("fzf-lua").lgrep_curbuf({
						winopts = {
							height = 0.6,
							width = 0.5,
							preview = { vertical = "up:70%" },
						},
					})
				end,
				desc = "Grep current buffer",
			},
			{ "<leader>fc", "<cmd>FzfLua highlights<cr>", desc = "Highlights" },
			{ "<leader>fd", "<cmd>FzfLua lsp_document_diagnostics<cr>", desc = "Document diagnostics" },
			{ "<leader>fD", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace diagnostics" },
			{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
			{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
			{ "<leader>fg", "<cmd>FzfLua grep_visual<cr>", desc = "Grep", mode = "x" },
			{ "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help" },
			{ "<leader>fi", "<cmd>FzfLua lsp_implementations<cr>", desc = "Implementations" },
			{ "<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", desc = "Code actions" },
			{ "<leader>fp", "<cmd>FzfLua lsp_incoming_calls<cr>", desc = "Incomming calls" },
			{ "<leader>fo", "<cmd>FzfLua lsp_outgoing_calls<cr>", desc = "Outgoing calls" },
			{ "<leader>fr", "<cmd>FzfLua lsp_references<cr>", desc = "References" },
			{ "z=", "<cmd>FzfLua spell_suggest<cr>", desc = "Spelling suggestions" },
		},
		opts = function()
			local actions = require("fzf-lua.actions")

			return {
				-- Make stuff better combine with the editor.
				fzf_colors = {
					bg = { "bg", "Normal" },
					gutter = { "bg", "Normal" },
					info = { "fg", "Conditional" },
					scrollbar = { "bg", "Normal" },
					separator = { "fg", "Comment" },
				},
				fzf_opts = {
					["--info"] = "default",
					["--layout"] = "reverse-list",
				},
				keymap = {
					builtin = {
						["<C-/>"] = "toggle-help",
						["<C-a>"] = "toggle-fullscreen",
						["<C-i>"] = "toggle-preview",
						["<C-f>"] = "preview-page-down",
						["<C-b>"] = "preview-page-up",
					},
					fzf = {
						["alt-s"] = "toggle",
						["alt-a"] = "toggle-all",
					},
				},
				winopts = {
					height = 0.7,
					width = 0.55,
					preview = {
						scrollbar = false,
						layout = "vertical",
						vertical = "up:40%",
					},
				},
				defaults = { git_icons = true },
				-- Configuration for specific commands.
				files = {
					winopts = {
						preview = { hidden = true },
					},
				},
				grep = {
					header_prefix = "",
				},
				helptags = {
					actions = {
						-- Open help pages in a vertical split.
						["enter"] = actions.help_vert,
					},
				},
				lsp = {
					symbols = {
						symbol_icons = icons,
					},
				},
				oldfiles = {
					include_current_session = true,
					winopts = {
						preview = { hidden = true },
					},
				},
			}
		end,
	},
}
