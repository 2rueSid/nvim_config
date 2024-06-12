local grep_string = require("telescope.builtin").grep_string
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- function RenameAll()
-- 	local current_word = vim.fn.expand("<cword>") -- Get the word under the cursor
-- 	last_searched_word = current_word
--
-- 	grep_string({
-- 		search = current_word,
-- 		word_match = "-w",
-- 		additional_args = function(opts)
-- 			return { "--hidden" } -- Search hidden files as well
-- 		end,
-- 		default_text = current_word,
-- 		attach_mappings = function(prompt_bufnr, map)
-- 			actions.select_default:replace(function()
-- 				local selection = action_state.get_selected_entry()
-- 				actions.close(prompt_bufnr)
-- 				if selection then
-- 					vim.cmd("e " .. selection.path)
-- 				end
-- 			end)
-- 			return true
-- 		end,
-- 	})
-- end

-- function ReplaceAllOccurrences(new_word)
-- 	if not last_searched_word or not new_word then
-- 		print("No word to replace")
-- 		return
-- 	end
-- 	-- Command to replace all occurrences in all files found by ripgrep
-- 	vim.cmd(
-- 		'silent !rg -l --hidden "'
-- 			.. last_searched_word
-- 			.. '" | xargs sed -i "s/\\b'
-- 			.. last_searched_word
-- 			.. "\\b/"
-- 			.. new_word
-- 			.. '/g"'
-- 	)
-- 	print("Replaced all occurrences of " .. last_searched_word .. " with " .. new_word)
-- end

-- Maps the function to <leader>rl and <leader>rr for replace
-- vim.api.nvim_set_keymap("n", "<leader>rl", "<cmd>lua RenameAll()<cr>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap(
-- 	"n",
-- 	"<leader>rr",
-- 	"<cmd>lua ReplaceAllOccurrences(vim.fn.input('New term for replacement: '))<cr>",
-- 	{ noremap = true, silent = true }
-- )
