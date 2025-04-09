local diagnostic_icons = require("icons").diagnostic
local utils = require("utils")
local autogroups = require("autogroups")

local methods = vim.lsp.protocol.Methods

--[[ Inlay hints ]]

-- Toggle off by default
vim.lsp.inlay_hint.enable(false)

local function enable_inlay_hints(client)
	if not client.server_capabilities.inlayHintProvider then
		print("Inlay hints not supported for this server ", client.name)
		return
	end

	local is_enabled = vim.lsp.inlay_hint.is_enabled() and "disabled" or "enabled"

	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	print("Inlay hints  ", is_enabled, " for server - ", client.name)
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
local hover_autocmd_enabled = false

local function toggle_hover_autocmd()
	hover_autocmd_enabled = not hover_autocmd_enabled

	if hover_autocmd_enabled then
		-- Autocmd is being enabled:
		vim.api.nvim_create_autocmd("CursorHold", {
			group = autogroups.hover_group,
			pattern = { "*.lua", "*.py", "*.go", "*.js", "*.ts", "*.tsx" },
			callback = function()
				local params = vim.lsp.util.make_position_params()
				local results = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 500)
				if results and next(results) ~= nil then
					vim.lsp.buf.hover()
				end
			end,
			desc = "Auto-trigger hover when cursor is held in place.",
		})
		print("Hover autocmd ENABLED.")
	else
		-- Autocmd is being disabled:
		vim.api.nvim_clear_autocmds({ group = autogroups.hover_group })
		print("Hover autocmd DISABLED.")
	end
end

--[[ END Hover ]]

--[[ Signature ]]

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = "rounded",
	max_height = math.floor(vim.o.lines * 0.5),
	max_width = math.floor(vim.o.columns * 0.4),
})
--[[ END Signature ]]

--[[  diagnostic ]]

-- Left bar signs
for severity, icon in pairs(diagnostic_icons) do
	local hl = "DiagnosticSign" .. severity:sub(1, 1) .. severity:sub(2):lower()
	vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = {
		spacing = 4,
		only_current_line = false,
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

local show_diagnostics = false

function toggle_diagnostics()
	show_diagnostics = not show_diagnostics

	if show_diagnostics then
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = autogroups.diagnostic_group,
			callback = function()
				local bufnr = vim.api.nvim_get_current_buf()

				-- Check if this buffer has an LSP client attached
				local clients = vim.lsp.get_clients({ bufnr = bufnr })
				if not clients or #clients == 0 then
					return
				end

				local has_diagnostic = false
				for _, client in ipairs(clients) do
					if client.server_capabilities.diagnosticProvider then
						has_diagnostic = true
						break
					end
				end

				if not has_diagnostic then
					return
				end

				-- Check if there's a diagnostic on the current line
				local line = vim.api.nvim_win_get_cursor(0)[1] - 1
				local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

				if #diagnostics > 0 then
					vim.diagnostic.open_float(nil, { focus = false, scope = "line" })
				end
			end,
			desc = "Show diagnostics in floating window only if available on current line",
		})
		print("Diagnostics enabled")
	else
		vim.api.nvim_clear_autocmds({ group = autogroups.diagnostic_group })
		print("Diagnostics disabled")
	end
end

local function copy_diagnostics(bufnr)
	-- Check if there's a diagnostic on the current line
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

	if #diagnostics > 0 then
		local messages = {}
		for _, diagnostic in ipairs(diagnostics) do
			local message =
				string.format("%s [%s #%s]", diagnostic.message, diagnostic.source, diagnostic.code or "nil")
			table.insert(messages, message)
		end

		-- Join the messages with newlines and copy to clipboard
		local joined_messages = table.concat(messages, "\n")
		vim.fn.setreg("+", joined_messages)
		print("Copied diagnostics to clipboard")
	else
		print("No diagnostics found on the current line.")
	end
end

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

--[[  END diagnostic ]]
local function on_attach(client, bufnr)
	require("illuminate").on_attach(client)

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	buf_set_keymap("n", "<leader>rn", "<CMD>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>i", "<CMD>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>dc", copy_diagnostics, { buffer = bufnr, desc = "Copy diagnostics to clipboard" })
	vim.keymap.set("n", "<leader>gd", function()
		utils.open_definition_smart_split()
	end, { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>ih", function()
		enable_inlay_hints(client)
	end, { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>hh", toggle_hover_autocmd, { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>sd", toggle_diagnostics, { silent = true, noremap = true })
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
