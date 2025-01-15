return {
	ensure_installed = {
		-- Python
		"pyright",
		"ruff",

		-- Rust
		"rust_analyzer",

		-- bash
		"bashls",
		"shellcheck",
		"shfmt",

		-- css
		"cssls",
		"css_variables",
		"cssmodules_ls",

		-- Docker
		"dockerls",
		"docker_compose_language_service",

		-- js/ts
		"ts_ls",
		"eslint",
		"eslint_d",
		"prettier",

		-- go
		"gopls",
		"golangci_lint_ls",
		"goimports",
		"gofumpt",

		-- lua
		"lua_ls",
		"stylua",

		-- yaml
		"yamlls",
		"yamlfmt",
		"yamllint",
		"yamlfix",

		-- spellcheck
		"cspell",
		"typos_lsp",
		"typos",

		-- terraform
		"tflint",
		"terraformls",

		-- other
		"ast_grep",
		"marksman",
		"trivy",
		"nil_ls",
		"nixpkgs-fmt",
		"sqls",
	},

	install_root_dir = vim.fn.stdpath("config") .. "/lib/mason",

	-- PATH = "append",

	ui = {
		icons = {
			package_pending = " ",
			package_installed = "󰄳 ",
			package_uninstalled = " 󰚌",
		},

		keymaps = {
			toggle_server_expand = "<CR>",
			install_server = "i",
			update_server = "u",
			check_server_version = "c",
			update_all_servers = "U",
			check_outdated_servers = "C",
			uninstall_server = "X",
			cancel_installation = "<C-c>",
		},
	},

	max_concurrent_installers = 10,
}
