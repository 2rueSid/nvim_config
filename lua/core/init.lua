require("core.keybindings")

vim.wo.relativenumber = true
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.cmd("colorscheme nightfox")
require("bufferline").setup{}