local lsp = require "plugins.configs.lsp_config"

require("lspconfig").rust_analyzer.setup {
    on_attach = lsp.on_attach,
    capabilities = lsp.capabilities,

  settings = {},
}