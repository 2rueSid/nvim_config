return {
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "tsx", "typescript", "python", "yaml", "cpp", "go", "javascript" },

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
