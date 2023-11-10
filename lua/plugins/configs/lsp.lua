local lspconfig = require('lspconfig')

local on_attach = function(client)
    require'completion'.on_attach(client)
end

return function (capabilities)
    -- Need to install rust-analyzer binary into PATH
    lspconfig.rust_analyzer.setup(
        {
            on_attach=on_attach,
            settings = {
                ["rust-analyzer"] = {
                    imports = {
                        granularity = {
                            group = "module",
                        },
                        prefix = "self",
                    },
                    cargo = {
                        buildScripts = {
                            enable = true,
                        },
                    },
                    procMacro = {
                        enable = true
                    },
                }
            },
            capabilities = capabilities
    }
    )
end