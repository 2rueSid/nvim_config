local source = debug.getinfo(1, "S").source:sub(2)
local tests = vim.fs.dirname(source)
local plugin = vim.fs.dirname(tests)
vim.opt.runtimepath:prepend(plugin)
package.path = tests .. "/?.lua;" .. package.path
