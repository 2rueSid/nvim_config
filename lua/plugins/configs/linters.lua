return {
	go = { "golangcilint" },
	-- python = { "flake8", "mypy", "trivy" },
	python = { "ruff", "mypy", "trivy" },
	javascript = { "eslint", "trivy", "cspell" },
	typescript = { "eslint", "trivy", "cspell" },
	javascriptreact = { "eslint", "trivy", "cspell" },
	typescriptreact = { "eslint", "trivy", "cspell" },
	terraform = { "trivy", "tflint", "cspell" },
	yaml = { "yamllint", "trivy", "cspell" },
	shell = { "shellcheck" },

	["*"] = { "cspell" },
}
