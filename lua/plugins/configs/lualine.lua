return {
  options = {
    icons_enabled = true,
    theme = "catppuccin",
    component_separators = {  left = "\u{ea9b}", right = "\u{ea9c}"},
    section_separators = {left = "\u{e0bb}", right = "\u{e0bb}"},
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {
	    {
	      'branch',
		    icons_enabled=true,
		      icon="\u{e725}"
      },
	    'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'buffers', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
