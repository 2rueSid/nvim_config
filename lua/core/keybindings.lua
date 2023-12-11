local C = require("constants")
local utils = require("core.utils")

-- LEADER KEY
vim.g.mapleader = C.keys.LEADER_KEY

-- BUILDIN
vim.keymap.set('n', '<C-n>', function() vim.cmd('bnext') end, {}) -- next file in buffer
vim.keymap.set('n', '<C-p>', function() vim.cmd('bprev') end, {}) -- prev file in buffer
vim.keymap.set('n', '<leader>ch', function() utils.open_file(C.path.CHEATSHEET_FILE) end, { noremap = true, silent = true })
-- move cursor half screen down and center cursor on the screen
vim.keymap.set('n', '<C-d>', function() vim.api.nvim_exec('execute "normal! \\<C-d>zz"', false) end, { noremap = true, silent = true })
-- move cursor half screen up and center cursor on the screen
vim.keymap.set('n', '<C-u>', function() vim.api.nvim_exec('execute "normal! \\<C-u>zz"', false) end, { noremap = true, silent = true })

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

-- Nvim tree
local nvim_tree = require "nvim-tree.api"
vim.keymap.set("n", "<leader>tt", function () nvim_tree.tree.open() end) -- open file explore
vim.keymap.set("n", "<leader>tc", function () nvim_tree.tree.close() end) -- close file explore

