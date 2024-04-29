return {
	go = { "golangcilint", "revive" },
	-- python = { "flake8", "mypy", "trivy" },
	python = { "ruff", "mypy", "trivy" },
	javascript = { "eslint", "trivy" },
	typescript = { "eslint", "trivy" },
	javascriptreact = { "eslint", "trivy" },
	typescriptreact = { "eslint", "trivy" },
	terraform = { "trivy", "tflint" },
	yaml = { "yamllint", "trivy" },
	shell = { "shellcheck" },
}
