local function open_file_by_path(path)
    if path ~= "" then
        vim.cmd('edit ' .. path)
    end
end

return {
  open_file = open_file_by_path
}