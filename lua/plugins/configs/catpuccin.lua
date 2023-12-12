
return {
    transparent_background = true,
    show_end_of_buffer = false,
    term_colors = false,
    no_italic = false,
    no_bold = false,
    no_underline = false,
    styles = {
        comments = { "italic" }, -- Change the style of comments
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
    },
    -- custom_highlights = function(colors)
    --     local cobaltColors = {
    --         blue = "#0088ff",
    --         yellow = "#ffc600",
    --         white = "#ffffff",
    --         darkBlue = "#193549",
    --         lightGrey = "#aaa",
    --         green = "#3ad900",
    --         red = "#ff628c",
    --         magenta = "#fb94ff",
    --         cyan = "#80fcff",
    --         darkGrey = "#15232d",
    --     }

    --     return {
    --         Normal = { bg = cobaltColors.darkBlue, fg = cobaltColors.white },
    --         Comment = { fg = cobaltColors.blue },
    --         Constant = { fg = cobaltColors.cyan },
    --         String = { fg = cobaltColors.green },
    --         Character = { fg = cobaltColors.green },
    --         Number = { fg = cobaltColors.cyan },
    --         Boolean = { fg = cobaltColors.cyan },
    --         Float = { fg = cobaltColors.cyan },
    --         Identifier = { fg = cobaltColors.white },
    --         Function = { fg = cobaltColors.yellow },
    --         Statement = { fg = cobaltColors.magenta },
    --         Conditional = { fg = cobaltColors.magenta },
    --         Repeat = { fg = cobaltColors.magenta },
    --         Label = { fg = cobaltColors.yellow },
    --         Operator = { fg = cobaltColors.yellow },
    --         Keyword = { fg = cobaltColors.magenta },
    --         Exception = { fg = cobaltColors.red },
    --         PreProc = { fg = cobaltColors.yellow },
    --         Include = { fg = cobaltColors.yellow },
    --         Define = { fg = cobaltColors.yellow },
    --         Macro = { fg = cobaltColors.yellow },
    --         PreCondit = { fg = cobaltColors.yellow },
    --         Type = { fg = cobaltColors.yellow },
    --         StorageClass = { fg = cobaltColors.yellow },
    --         Structure = { fg = cobaltColors.yellow },
    --         Typedef = { fg = cobaltColors.yellow },
    --         Special = { fg = cobaltColors.yellow },
    --         SpecialChar = { fg = cobaltColors.yellow },
    --         Tag = { fg = cobaltColors.yellow },
    --         Delimiter = { fg = cobaltColors.yellow },
    --         SpecialComment = { fg = cobaltColors.blue },
    --         Debug = { fg = cobaltColors.red },
    --         Underlined = { fg = cobaltColors.white },
    --         Ignore = { fg = cobaltColors.darkGrey },
    --         Error = { fg = cobaltColors.red },
    --         Todo = { fg = cobaltColors.yellow },
    --     }
    -- end,
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        illuminate = {
          enabled = true,
          lsp = false
       },
       harpoon = true,
    },
}