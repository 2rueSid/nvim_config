-- source https://github.com/kazhala/dotfiles/blob/master/.config/nvim/lua/kaz/plugins/lspconfig/init.lua
local utils = require("core.utils")
local au = require("core.au")

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
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = vim.g.floating_window_border })
vim.lsp.handlers["textDocument/formatting"] = utils.format_async

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

local disabled_signature_lsp = {
	terraformls = true,
	efm = true,
	tflint = true,
	["null-ls"] = true,
}

local on_attach = function(client, bufnr)
	require("illuminate").on_attach(client)

	if disabled_signature_lsp[client.name] == nil then
		require("lsp_signature").on_attach({
			bind = true,
			hint_enable = true,
			hi_parameter = "CursorLine",
			handler_opts = { border = "single" },
		})
	end

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	buf_set_keymap("n", "<leader>rn", "<CMD>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>i", "<CMD>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>gd", "<CMD>lua vim.lsp.buf.definition()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>lc", "<CMD>lua vim.lsp.buf.incoming_calls()<CR>", { silent = true, noremap = true })
end

local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()

require("plugins.configs.lsp_configs.pyright").setup(on_attach, capabilities)
-- require("plugins.configs.lsp_configs.ruff").setup(on_attach, capabilities)
require("plugins.configs.lsp_configs.tsserver").setup(on_attach, capabilities)
require("plugins.configs.lsp_configs.eslint").setup(on_attach, capabilities)
require("plugins.configs.lsp_configs.lua_ls").setup(on_attach, capabilities)
require("plugins.configs.lsp_configs.tflint").setup(on_attach, capabilities)
require("plugins.configs.lsp_configs.terraformls").setup(on_attach)
require("plugins.configs.lsp_configs.gopls").setup(on_attach)
require("plugins.configs.lsp_configs.golangci").setup(on_attach)
require("plugins.configs.lsp_configs.yamlls").setup(on_attach)
require("plugins.configs.lsp_configs.bufls").setup(on_attach, capabilities)
require("plugins.configs.lsp_configs.bashls").setup(on_attach, capabilities)
