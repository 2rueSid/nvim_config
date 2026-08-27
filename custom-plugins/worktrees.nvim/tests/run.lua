for _, suite in ipairs({ "git_spec", "session_spec", "picker_spec", "merge_spec" }) do
  local ok, tests = pcall(require, suite)
  if ok then
    for name, test in pairs(tests) do
      io.write(string.format("%s.%s ... ", suite, name))
      test()
      io.write("ok\n")
    end
  elseif not tostring(tests):match("module '" .. suite .. "' not found") then
    error(tests)
  end
end
