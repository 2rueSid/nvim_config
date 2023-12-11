

local plugins = {
  "neovim/nvim-lspconfig",
  "nvim-lua/plenary.nvim",
  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
        local tree_sitter = require("plugins.configs.treesitter")
        require("nvim-treesitter.configs").setup(tree_sitter)
    end
  },
  "alexaandru/nvim-lspupdate",
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
    cmd = "Telescope",
    opts = function()
      return require "plugins.configs.telescope"
    end,
    config = function(_, opts)
      local telescope = require "telescope"
      telescope.setup(opts)

      -- load extensions
      for _, ext in ipairs(opts.extensions_list) do
        telescope.load_extension(ext)
      end
    end,
  },
  -- nvim-tree
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup()
    end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  -- status line
    {
        "sontungexpt/sttusline",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = { "BufEnter" },
        config = function(_, opts)
            require("sttusline").setup {
                laststatus = 3,
                disabled = {
                    filetypes = {
                    },
                    buftypes = {
                    },
                },
                components = {
                    "mode",
                    "filename",
                    "git-branch",
                    "git-diff",
                    "%=",
                    "diagnostics",
                    "lsps-formatters",
                    "indent",
                    "pos-cursor",
                    "pos-cursor-progress",
                },
            }
        end,
  },
  -- tabline
   {
    'Bekaboo/dropbar.nvim',
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim'
    }
  },
  {
    "RRethy/vim-illuminate",
    config = function()
      -- default configuration
      require('illuminate').configure({
      -- providers: provider used to get references in the buffer, ordered by priority
      providers = {
          'lsp',
          'treesitter',
          'regex',
      },
      -- delay: delay in milliseconds
      delay = 100,
      -- filetype_overrides: filetype specific overrides.
      -- The keys are strings to represent the filetype while the values are tables that
      -- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
      filetype_overrides = {},
      -- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
      filetypes_denylist = {
          'dirbuf',
          'dirvish',
          'fugitive',
      },
      -- filetypes_allowlist: filetypes to illuminate, this is overridden by filetypes_denylist
      -- You must set filetypes_denylist = {} to override the defaults to allow filetypes_allowlist to take effect
      filetypes_allowlist = {},
      -- modes_denylist: modes to not illuminate, this overrides modes_allowlist
      -- See `:help mode()` for possible values
      modes_denylist = {},
      -- modes_allowlist: modes to illuminate, this is overridden by modes_denylist
      -- See `:help mode()` for possible values
      modes_allowlist = {},
      -- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
      -- Only applies to the 'regex' provider
      -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
      providers_regex_syntax_denylist = {},
      -- providers_regex_syntax_allowlist: syntax to illuminate, this is overridden by providers_regex_syntax_denylist
      -- Only applies to the 'regex' provider
      -- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
      providers_regex_syntax_allowlist = {},
      -- under_cursor: whether or not to illuminate under the cursor
      under_cursor = true,
      -- large_file_cutoff: number of lines at which to use large_file_config
      -- The `under_cursor` option is disabled when this cutoff is hit
      large_file_cutoff = nil,
      -- large_file_config: config to use for large files (based on large_file_cutoff).
      -- Supports the same keys passed to .configure
      -- If nil, vim-illuminate will be disabled for large files.
      large_file_overrides = nil,
      -- min_count_to_highlight: minimum number of matches required to perform highlighting
      min_count_to_highlight = 1,
      -- should_enable: a callback that overrides all other settings to
      -- enable/disable illumination. This will be called a lot so don't do
      -- anything expensive in it.
      should_enable = function(bufnr) return true end,
      -- case_insensitive_regex: sets regex case sensitivity
      case_insensitive_regex = false,
      })
    end
  },
  -- theme
  {
    "EdenEast/nightfox.nvim"
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {}
  },
}

-- check if lazyvim installed
local lazy = require("boot.lazy")
lazy.setup(plugins)

require("harpoon").setup()