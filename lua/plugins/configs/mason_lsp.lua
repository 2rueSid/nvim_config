return {
	ensure_installed = {
		-- python
		"pyright",
		"ruff",

		-- rust
		"rust_analyzer",

		-- TS/JS
		"ts_ls",
		"eslint",

		-- lua
		"lua_ls",

		-- terraform
		"tflint",
		"terraformls",

		-- bash
		"bashls",

		-- css
		"cssls",
		"css_variables",
		"cssmodules_ls",

		-- go
		"gopls",
		"golangci_lint_ls",

		-- nix
		"nil_ls",

		-- yaml
		"yamlls",

		-- sql
		"sqls",

		-- Docker
		"dockerls",
		"docker_compose_language_service",

		-- other
		"typos_lsp",
		"ast_grep",
		"marksman",
	},

	automatic_installation = true,
}
