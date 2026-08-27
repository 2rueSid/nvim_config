for _, suite in ipairs({ "git_spec", "session_spec", "picker_spec", "merge_spec" }) do
  for name, test in pairs(require(suite)) do
    io.write(string.format("%s.%s ... ", suite, name))
    test()
    io.write("ok\n")
  end
end
