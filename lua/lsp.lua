local diagnostic_icons = require("icons").diagnostic
local utils = require("utils")
local autogroups = require("autogroups")

local methods = vim.lsp.protocol.Methods

--[[ Inlay hints ]]

-- Toggle off by default
vim.lsp.inlay_hint.enable(false)

local function enable_inlay_hints(client)
	if not client.server_capabilities.inlayHintProvider then
		return
	end

	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

--[[ END Inlay hints ]]

--[[ Hover ]]

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "rounded",
	max_height = math.floor(vim.o.lines * 0.5),
	max_width = math.floor(vim.o.columns * 0.4),
})

-- Display LSP reference
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "LspReferenceTarget", {})
	end,
})

-- Display documentation when cursor is hold in the position for ~3 seconds and there is symbol under cursor
vim.api.nvim_create_autocmd("CursorHold", {
	group = autogroups.hover_group,
	pattern = "*",
	callback = function()
		local params = vim.lsp.util.make_position_params()
		local results = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 500)
		if results and next(results) ~= nil then
			vim.lsp.buf.hover()
		end
	end,
})

--[[ END Hover ]]

for severity, icon in pairs(diagnostic_icons) do
	local hl = "DiagnosticSign" .. severity:sub(1, 1) .. severity:sub(2):lower()
	vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = "rounded",
	max_height = math.floor(vim.o.lines * 0.5),
	max_width = math.floor(vim.o.columns * 0.4),
})

vim.diagnostic.config({
	virtual_text = {
		prefix = "",
		spacing = 2,
		format = function(diagnostic)
			local message = diagnostic.message
			local severity = diagnostic.severity
			local source = diagnostic.source
			local code = diagnostic.code

			if diagnostic_icons[severity] then
				message = string.format("%s %s", diagnostic_icons[severity], message)
			end

			if source then
				message = string.format("%s [%s #%s]", message, source, code or "nil")
			end

			return message
		end,
	},
	float = {
		border = "rounded",
		source = "if_many",
		-- Show severity icons as prefixes.
		prefix = function(diag)
			local level = vim.diagnostic.severity[diag.severity]
			local prefix = string.format(" %s ", diagnostic_icons[level])
			return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
		end,
	},
	signs = {
		enable = true,
		[vim.diagnostic.severity.ERROR] = diagnostic_icons[vim.diagnostic.severity.ERROR],
		[vim.diagnostic.severity.WARN] = diagnostic_icons[vim.diagnostic.severity.WARN],
		[vim.diagnostic.severity.INFO] = diagnostic_icons[vim.diagnostic.severity.INFO],
		[vim.diagnostic.severity.HINT] = diagnostic_icons[vim.diagnostic.severity.HINT],
	},
	underline = true,
	update_in_insert = true,
	severity_sort = true,
})

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
assert(show_handler)
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
	show = function(ns, bufnr, diagnostics, opts)
		table.sort(diagnostics, function(diag1, diag2)
			return diag1.severity > diag2.severity
		end)
		return show_handler(ns, bufnr, diagnostics, opts)
	end,
	hide = hide_handler,
}

local function on_attach(client, bufnr)
	require("illuminate").on_attach(client)

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	buf_set_keymap("n", "<leader>rn", "<CMD>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>i", "<CMD>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>gd", function()
		utils.open_definition_smart_split()
	end, { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>ih", function()
		enable_inlay_hints(client)
	end, { silent = true, noremap = true })
end

local register_capability = vim.lsp.handlers[methods.client_registerCapability]
vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if not client then
		return
	end

	on_attach(client, vim.api.nvim_get_current_buf())

	return register_capability(err, res, ctx)
end

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "Configure LSP keymaps",
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		-- I don't think this can happen but it's a wild world out there.
		if not client then
			return
		end

		on_attach(client, args.buf)
	end,
})

local M = {}

function M.configure_server(server, settings)
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = vim.tbl_extend("force", capabilities, require("lsp-file-operations").default_capabilities())

	capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

	require("lspconfig")[server].setup(
		vim.tbl_deep_extend(
			"error",
			{ capabilities = capabilities, silent = true, on_attach = on_attach },
			settings or {}
		)
	)
end

return M
