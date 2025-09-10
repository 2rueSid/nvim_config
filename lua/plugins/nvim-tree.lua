return {
	-- nvim-tree
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("nvim-tree").setup({
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")

					local function opts(desc)
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end

					api.config.mappings.default_on_attach(bufnr)

					vim.keymap.set("n", "d", api.fs.trash, opts("Move to trash"))
					vim.keymap.set("n", "D", api.fs.remove, opts("Remove completely"))
				end,
				disable_netrw = false,
				hijack_netrw = true,
				hijack_cursor = true,
				hijack_unnamed_buffer_when_opening = false,
				sync_root_with_cwd = true,
				update_focused_file = {
					enable = true,
					update_root = false,
				},
				view = {
					adaptive_size = true,
					side = "left",
					width = {
						min = 30,
						max = 50,
					},
					preserve_window_proportions = true,
				},
				git = {
					enable = true,
					ignore = false,
				},
				filesystem_watchers = {
					enable = true,
				},
				modified = {
					enable = true,
				},
				diagnostics = {
					enable = true,
					show_on_dirs = true,
					icons = {
						hint = "",
						info = "",
						warning = "",
						error = "",
					},
				},
				actions = {
					open_file = {
						quit_on_open = true,
						resize_window = true,
					},
				},
				renderer = {
					root_folder_label = true,
					highlight_git = "all",
					highlight_diagnostics = "all",
					highlight_modified = "icon",
					highlight_opened_files = "name",

					indent_markers = {
						enable = true,
					},

					icons = {
						show = {
							file = true,
							folder = true,
							folder_arrow = true,
							git = true,
						},

						glyphs = {
							default = "󰈚",
							symlink = "",
							folder = {
								default = "",
								empty = "",
								empty_open = "",
								open = "",
								symlink = "",
								symlink_open = "",
								arrow_open = "",
								arrow_closed = "",
							},
							git = {
								unstaged = "✗",
								staged = "✓",
								unmerged = "",
								renamed = "➜",
								untracked = "★",
								deleted = "",
								ignored = "◌",
							},
						},
					},
				},
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false,
	},
}
