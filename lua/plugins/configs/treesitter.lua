return {
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "tsx", "typescript", "python", "yaml", "cpp", "go", "javascript", "toml" },

  auto_install = true,

  highlight = {
    enable = true,
    -- use_languagetree = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = true },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = nil,
  }
}

