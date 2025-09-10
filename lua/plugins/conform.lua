return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		opts = {
			notify_on_error = false,
			formatters_by_ft = {
				-- nix = { name = "nixfmt", timeout_ms = 500, lsp_format = "prefer" },

				javascript = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				javascriptreact = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				json = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				jsonc = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				typescript = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				markdown = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				typescriptreact = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				yaml = { "prettier" },

				terraform = { "terraform_fmt" },

				lua = { "stylua" },

				rust = { name = "rust_analyzer", timeout_ms = 500, lsp_format = "prefer" },

				go = { "gofumpt", "goimports" },

				sh = { "shfmt" },

				python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },

				["_"] = { "trim_whitespace", "trim_newlines" },
			},
			format_on_save = function()
				if vim.g.minifiles_active then
					return nil
				end

				if not vim.g.autoformat then
					return nil
				end

				return {}
			end,
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

			vim.g.autoformat = true
		end,
	},
}
