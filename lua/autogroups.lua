local augroup = vim.api.nvim_create_augroup

local M = {}

M.inlay_hints_group = augroup("InlayHintsGroup", { clear = true })
M.hover_group = augroup("HoverGroup", { clear = true })

return M
