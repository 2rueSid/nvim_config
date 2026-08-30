for _, suite in ipairs({ "registry_spec" }) do
  for name, test in pairs(require(suite)) do
    io.write(string.format("%s.%s ... ", suite, name))
    test()
    io.write("ok\n")
  end
end
