local K = require("constants.keys")

-- LEADER KEY
vim.g.mapleader = K.LEADER_KEY

-- BUILDIN
vim.keymap.set('n', '<C-n>', function() vim.cmd('bnext') end, {}) -- next file in buffer
vim.keymap.set('n', '<C-p>', function() vim.cmd('bprev') end, {}) -- prev file in buffer

-- TELESCOPE
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {}) -- Lists files in your current working directory, respects .gitignore
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {}) -- Search for a string in your current working directory and get results live as you type, respects .gitignore. (Requires ripgrep)
vim.keymap.set('n', '<leader>fs', builtin.grep_string, {}) -- Searches for the string under your cursor or selection in your current working directory
vim.keymap.set('n', '<leader>fb', builtin.buffers, {}) -- Lists open buffers in current neovim instance
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, {}) -- Lists previously open files
vim.keymap.set('n', '<leader>ft', builtin.treesitter, {}) -- Lists Function names, variables, from Treesitter!

-- harpoon
local harpoon = require("harpoon")

vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
