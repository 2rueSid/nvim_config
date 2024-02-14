return {
	go = { "golangcilint" },
	python = { "flake8", "mypy", "trivy" },
	-- python = { "ruff", "mypy" },
	javascript = { "eslint", "trivy" },
	typescript = { "eslint", "trivy" },
	javascriptreact = { "eslint", "trivy" },
	typescriptreact = { "eslint", "trivy" },
	terraform = { "trivy", "tflint" },
	yaml = { "yamllint", "trivy" },
}
