local utils = require("utils")
return {
	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("lspconfig.ui.windows").default_options.border = "rounded"

			local configure_server = require("lsp").configure_server

			servers = {
				"bashls",
				"cssls",
				"css_variables",
				"dockerls",
				"docker_compose_language_service",
				gopls = {
					settings = {
						gopls = {
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								compositeLiteralTypes = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
							staticcheck = true,
							gofumpt = true,
						},
					},
				},
				"ts_ls",
				"eslint",
				-- "oxlint",
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
							hint = {
								enable = true,
								setType = true,
							},
							workspace = {
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
									[vim.fn.stdpath("config") .. "/lib/plugins/"] = true,
								},
								maxPreload = 100000,
								preloadFileSize = 10000,
							},
							inlayHints = {
								enable = true,
								showParameterNames = true,
								parameterHintsPrefix = "<- ",
								otherHintsPrefix = "=> ",
							},
						},
					},
				},
				pyright = {
					on_init = function(client)
						local lsp_util = require("lspconfig/util")
						client.config.settings.python.pythonPath =
							utils.get_python_path(client.config.root_dir, lsp_util.path)
					end,
					settings = {
						python = {
							-- analysis = {
							-- 	typeCheckingMode = "",
							-- 	autoSearchPaths = true,
							-- 	useLibraryCodeForTypes = true,
							-- 	diagnosticMode = "openFilesOnly",
							-- 	autoImportCompletions = true,
							-- },
							-- disableOrganizeImports = true,
							analysis = {
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								autoImportCompletions = true,
							},
						},
					},
				},
				"ruff",
				-- pylyzer = {
				-- 	on_init = function(client)
				-- 		local lsp_util = require("lspconfig/util")
				-- 		client.config.settings.python.pythonPath =
				-- 			utils.get_python_path(client.config.root_dir, lsp_util.path)
				-- 	end,
				-- },
				"terraformls",
				tflint = {
					cmd = {
						"tflint",
						"--langserver",
					},
				},
				"typos_lsp",
				rust_analyzer = {
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
				yamlls = {
					settings = {
						yaml = {
							schemastore = {
								enable = false,
								url = "",
							},
						},
					},
					on_new_config = function(config)
						config.settings.yaml.schemas = config.settings.yaml.schemas or {}
						vim.list_extend(config.settings.yaml.schemas, require("schemastore").yaml.schemas())
					end,
				},
			}

			for key, value in pairs(servers) do
				if type(value) == "string" then
					configure_server(value, {})
				elseif type(value) == "table" then
					configure_server(key, value)
				end
			end
		end,
		opts = {
			inlay_hints = { enabled = true },
		},
	},
}
