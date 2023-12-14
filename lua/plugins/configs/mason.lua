return {
  ensure_installed = { "lua-language-server", "luacheck", "ruff", "pyright", "ruff_lsp", "rust_analyzer", "tsserver", "typos_lsp", "eslint", "lua_ls", "prettier", "golangcilint","stylua","clangformat","gofmt","rustfmt",
  },

  ui = {
    icons = {
      package_pending = " ",
      package_installed = "󰄳 ",
      package_uninstalled = " 󰚌",
    },

    keymaps = {
      toggle_server_expand = "<CR>",
      install_server = "i",
      update_server = "u",
      check_server_version = "c",
      update_all_servers = "U",
      check_outdated_servers = "C",
      uninstall_server = "X",
      cancel_installation = "<C-c>",
    },
  },

  max_concurrent_installers = 10,
}