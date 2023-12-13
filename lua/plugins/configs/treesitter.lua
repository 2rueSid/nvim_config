return {
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "tsx", "typescript", "python", "yaml", "cpp", "go", "javascript", "toml" },
  additional_vim_regex_highlighting = false,
  sync_install = false,

  auto_install = true,

  ignore_install = { },

  highlight = {
    enable = true,

    disable = {},
    use_languagetree = true,
  },
  indent = { enable = true },
}
