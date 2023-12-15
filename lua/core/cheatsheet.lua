local keybindings = require("core.keybindings").keybindings

function show_cheatsheet()
	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {}

	-- Format and add keybindings to lines
	for category, bindings in pairs(keybindings) do
		table.insert(lines, category .. ":")
		for _, binding in pairs(bindings) do
			local line = string.format("  %s - %s", binding.key, binding.desc)
			table.insert(lines, line)
		end
		table.insert(lines, "")
	end

	-- Set lines in buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Calculate window size
	local screen_width = vim.o.columns
	local screen_height = vim.o.lines

	-- Set the window to half the width of the screen and adjust height as needed
	local win_width = math.floor(screen_width / 2)
	local win_height = math.min(#lines, math.floor(screen_height / 2)) -- Adjust height to lines count or half screen height

	-- Calculate center position
	local col = math.floor((screen_width - win_width) / 2)
	local row = math.floor((screen_height - win_height) / 2)

	-- Window options
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

	-- Define a highlight group for CheatsheetGroupTitle
	vim.api.nvim_set_hl(0, "CheatsheetGroupTitle", { bold = true })

	-- Define a highlight group for CheatsheetKey
	vim.api.nvim_set_hl(0, "CheatsheetKey", { bold = true })

	local line_num = 0
	for _, line in ipairs(lines) do
		if line:match("^[^ ]+:$") then -- Group titles end with ':'
			vim.api.nvim_buf_add_highlight(buf, -1, "CheatsheetGroupTitle", line_num, 0, -1)
		elseif line:match("^  [^ ]+") then -- Keys are indented with two spaces
			vim.api.nvim_buf_add_highlight(buf, -1, "CheatsheetKey", line_num, 2, line:find(" -") or -1)
		end
		line_num = line_num + 1
	end

	-- Make the buffer non-modifiable and set other buffer-local options
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
end

vim.api.nvim_set_keymap("n", "<leader>ch", ":lua show_cheatsheet()<CR>", { noremap = true, silent = true })
