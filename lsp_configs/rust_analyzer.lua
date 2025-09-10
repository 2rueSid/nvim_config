-- Install with: rustup component add rust-analyzer

---@type vim.lsp.Config
return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "rust-project.json" },
	settings = {
		["rust-analyzer"] = {
			settings = {
				["rust-analyzer"] = {
					diagnostics = {
						enable = true,
					},
					cargo = {
						features = "all",
					},
					completion = {
						fullFunctionSignatures = {
							enable = true,
						},
					},
					imports = {
						granularity = {
							enforce = true,
						},
					},
				},
			},
		},
	},
}
