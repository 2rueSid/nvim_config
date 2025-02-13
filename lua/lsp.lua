local diagnostic_icons = require("icons").diagnostic

local methods = vim.lsp.protocol.Methods

-- Disable inlay hints
vim.g.inlay_hints = false

for severity, icon in pairs(diagnostic_icons) do
	local hl = "DiagnosticSign" .. severity:sub(1, 1) .. severity:sub(2):lower()
	vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "rounded",
	max_height = math.floor(vim.o.lines * 0.5),
	max_width = math.floor(vim.o.columns * 0.4),
})

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
			-- Use shorter, nicer names for some sources:
			local special_sources = {
				["Lua Diagnostics."] = "lua",
				["Lua Syntax Check."] = "lua",
			}

			local message = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
			if diagnostic.source then
				message = string.format("%s %s", message, special_sources[diagnostic.source] or diagnostic.source)
			end
			if diagnostic.code then
				message = string.format("%s[%s]", message, diagnostic.code)
			end

			return message .. " "
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

	function open_definition_smart_split()
		local num_splits = vim.fn.winnr("$")

		if num_splits == 1 then
			-- If only one split, open a vertical split and jump to it
			vim.cmd("vsplit")
			vim.cmd("wincmd l")
		elseif num_splits == 2 then
			-- If two splits, open a horizontal split and jump to it
			vim.cmd("split")
			vim.cmd("wincmd j")
		elseif num_splits == 3 then
			-- If three splits, move to the third split and replace it
			vim.cmd("wincmd l")
			vim.cmd("wincmd j")
			vim.cmd("edit")
		end

		-- Open the definition in the focused window
		vim.lsp.buf.definition()
	end

	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	buf_set_keymap("n", "<leader>rn", "<CMD>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>i", "<CMD>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true })
	buf_set_keymap(
		"n",
		"<leader>gd",
		"<CMD>lua open_definition_smart_split()<CR>",
		{ silent = true, noremap = true }
	)
	buf_set_keymap("n", "<leader>lc", "<CMD>lua vim.lsp.buf.incoming_calls()<CR>", { silent = true, noremap = true })
	buf_set_keymap("n", "<leader>ca", "<CMD>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true })


	if client:supports_method(methods.textDocument_documentHighlight) then
		local under_cursor_highlights_group = vim.api.nvim_create_augroup("test/cursor_highlights", { clear = false })
		vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave" }, {
			group = under_cursor_highlights_group,
			desc = "Highlight references under the cursor",
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
			group = under_cursor_highlights_group,
			desc = "Clear highlight references",
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end

	if client:supports_method(methods.textDocument_inlayHint) and vim.g.inlay_hints then
		local inlay_hints_group = vim.api.nvim_create_augroup("mariasolos/toggle_inlay_hints", { clear = false })

		-- Initial inlay hint display.
		-- Idk why but without the delay inlay hints aren't displayed at the very start.
		vim.defer_fn(function()
			local mode = vim.api.nvim_get_mode().mode
			vim.lsp.inlay_hint.enable(mode == "n" or mode == "v", { bufnr = bufnr })
		end, 500)

		vim.api.nvim_create_autocmd("InsertEnter", {
			group = inlay_hints_group,
			desc = "Enable inlay hints",
			buffer = bufnr,
			callback = function()
				if vim.g.inlay_hints then
					vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
				end
			end,
		})

		vim.api.nvim_create_autocmd("InsertLeave", {
			group = inlay_hints_group,
			desc = "Disable inlay hints",
			buffer = bufnr,
			callback = function()
				if vim.g.inlay_hints then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end
			end,
		})
	end
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

    
		vim.tbl_deep_extend("error", { capabilities = capabilities, silent = true, on_attach=on_attach }, settings or {})
	)
end

return M
