return {
	logging = true,
	log_level = vim.log.levels.WARN,
	try_node_modules = true,
	filetype = {
		nix = {
			require("formatter.filetypes.nix").nixfmt,
		},
		lua = {
			require("formatter.filetypes.lua").stylua,
		},
		python = {
			require("formatter.filetypes.python").ruff,
			require("formatter.filetypes.python").autoflake,
			-- require("formatter.filetypes.python").black,
			-- require("formatter.filetypes.python").isort,
		},
		rust = {
			require("formatter.filetypes.rust").rustfmt,
		},
		cpp = {
			require("formatter.filetypes.cpp").clangformat,
		},
		go = {
			require("formatter.filetypes.go").gofumpt,
			require("formatter.filetypes.go").goimports,
		},
		javascript = {
			require("formatter.filetypes.javascript").prettier,
		},
		javascriptreact = {
			require("formatter.filetypes.javascriptreact").prettier,
		},
		json = {
			require("formatter.filetypes.json").prettier,
		},
		markdown = {
			require("formatter.filetypes.markdown").prettier,
		},
		typescript = {
			require("formatter.filetypes.typescript").prettier,
		},
		typescriptreact = {
			require("formatter.filetypes.typescriptreact").prettier,
		},
		terraform = {
			require("formatter.filetypes.terraform").terraformfmt,
		},
		yaml = {
			require("formatter.filetypes.yaml").yamlfmt,
		},
		proto = {
			require("formatter.filetypes.proto").buf_format,
		},
		sh = {
			require("formatter.filetypes.sh").shfmt,
		},
		css = {
			require("formatter.filetypes.css").prettier,
		},
		["*"] = {
			require("formatter.filetypes.any").remove_trailing_whitespace,
		},
	},
}
