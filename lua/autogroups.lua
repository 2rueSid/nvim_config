local augroup = vim.api.nvim_create_augroup

local M = {}

M.inlay_hints_group = augroup("InlayHintsGroup", { clear = true })

return M
