local au = require("config.au")

local function lspSymbol(name, icon)
	local hl = "DiagnosticSign" .. name
	vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
end

lspSymbol("Error", "󰅙")
lspSymbol("Info", "󰋼")
lspSymbol("Hint", "󰌵")
lspSymbol("Warn", "")

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	virtual_text = true,
	underline = true,
	update_in_insert = true,
	severity_sort = true,
	signs = {
		enable = true,
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

au.augroup("ShowDiagnostics", {
	{
		event = "CursorHold,CursorHoldI",
		pattern = "*",
		callback = function()
			vim.diagnostic.open_float(nil, {
				focusable = false,
				border = vim.g.floating_window_border,
				source = "if_many",
			})
		end,
	},
})

function open_definition_in_vertical_split()
	vim.cmd("vsplit") -- Create a vertical split
	vim.cmd("wincmd l") -- Move to the new vertical split
	vim.lsp.buf.definition() -- Call the LSP definition function
end

local on_attach = function(client, bufnr)
	require("illuminate").on_attach(client)

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	buf_set_keymap("n", "<leader>rn", "<CMD>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>i", "<CMD>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true })
	buf_set_keymap(
		"n",
		"<leader>gd",
		"<CMD>lua open_definition_in_vertical_split()<CR>",
		{ silent = true, noremap = true }
	)
	buf_set_keymap("n", "<leader>lc", "<CMD>lua vim.lsp.buf.incoming_calls()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>ca", "<CMD>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true })

	-- if client.server_capabilities.inlayHintProvider then
	-- 	vim.lsp.inlay_hint.enable(true)
	-- end

	-- vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
end

require("plugins.configs.lsp_configs.python").pyright(on_attach)
require("plugins.configs.lsp_configs.python").ruff(on_attach)

require("plugins.configs.lsp_configs.docker").dockerls(on_attach)
require("plugins.configs.lsp_configs.docker").docker_compose_language_service(on_attach)

require("plugins.configs.lsp_configs.js").ts_ls(on_attach)
require("plugins.configs.lsp_configs.js").eslint(on_attach)

require("plugins.configs.lsp_configs.lua_ls").setup(on_attach)

require("plugins.configs.lsp_configs.terraform").tflint(on_attach)
require("plugins.configs.lsp_configs.terraform").tfls(on_attach)

require("plugins.configs.lsp_configs.gopls").setup(on_attach)

require("plugins.configs.lsp_configs.yamlls").setup(on_attach)
require("plugins.configs.lsp_configs.bashls").setup(on_attach)
require("plugins.configs.lsp_configs.nix").setup(on_attach)

require("plugins.configs.lsp_configs.typos").setup(on_attach)

-- local css = require("plugins.configs.lsp_configs.cssls")
-- css.cssls(on_attach, capabilities)
-- css.css_variables(on_attach, capabilities)
-- css.cssmodules_ls(on_attach, capabilities)
