local function open_file_by_path(path)
	if path ~= "" then
		vim.cmd("edit " .. path)
	end
end

function show_documentation()
	if vim.bo.filetype == "help" then
		vim.cmd([[h ]] .. vim.fn.expand("<cword>"))
	else
		vim.lsp.buf.hover()
	end
end

function format_async(err, result, ctx)
	if err ~= nil or result == nil then
		return
	end

	if not vim.api.nvim_buf_get_option(ctx.bufnr, "modified") then
		local view = vim.fn.winsaveview()
		local client = vim.lsp.get_client_by_id(ctx.client_id)
		vim.lsp.util.apply_text_edits(result, ctx.bufnr, client.offset_encoding)
		vim.fn.winrestview(view)

		if ctx.bufnr == vim.api.nvim_get_current_buf() then
			vim.cmd([[noautocmd :update]])
		end
	end
end

return {
	open_file = open_file_by_path,
	format_async = format_async,
	show_documentation = show_documentation,
}
