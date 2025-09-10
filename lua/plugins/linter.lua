return {
	{
		"mfussenegger/nvim-lint",
		lazy = true,
		config = function()
			require("lint").linters_by_ft = {

				go = { "golangcilint", "cspell" },
				gitcommit = { "cspell" },
				-- python = { "mypy", "trivy", "cspell", "autoflake" },

				-- python = { "pylint", "mypy", "trivy", "cspell", "autoflake", "sonarlint-language-server" },
				python = { "ruff", "trivy", "cspell" },
				rust = { "clippy", "cspell" },
				javascript = { "eslint", "trivy", "cspell" },
				typescript = { "eslint", "trivy", "cspell" },
				javascriptreact = { "eslint", "trivy", "cspell" },
				typescriptreact = { "eslint", "trivy", "cspell" },
				terraform = { "trivy", "tflint", "cspell" },
				yaml = { "yamllint", "trivy", "cspell" },
				shell = { "shellcheck", "trivy", "cspell" },
			}
		end,
	},
}
