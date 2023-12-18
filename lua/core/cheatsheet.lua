local keybindings = require("core.keybindings").keybindings

function show_cheatsheet()
	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {}

	for category, bindings in pairs(keybindings) do
		table.insert(lines, category .. ":")
		for _, binding in pairs(bindings) do
			local line = string.format("  %s - %s", binding.key, binding.desc)
			table.insert(lines, line)
		end
		table.insert(lines, "")
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local screen_width = vim.o.columns
	local screen_height = vim.o.lines

	local win_width = math.floor(screen_width / 1.5)
	local win_height = math.min(#lines, math.floor(screen_height / 1.5))

	local col = math.floor((screen_width - win_width) / 2)
	local row = math.floor((screen_height - win_height) / 2)

	local win_opts = {
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}

	vim.api.nvim_open_win(buf, true, win_opts)

	vim.api.nvim_set_hl(0, "CheatsheetGroupTitle", { bold = true })

	local line_num = 0
	for _, line in ipairs(lines) do
		if line:match("^[^ ]+:$") then
			vim.api.nvim_buf_add_highlight(buf, -1, "CheatsheetGroupTitle", line_num, 0, -1)
    end
		line_num = line_num + 1
	end

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
end


