return {
	"mrjones2014/smart-splits.nvim",
	lazy = false,
	config = function()
		require("smart-splits").setup({
			default_amount = 5,
			at_edge = "wrap",
			float_win_behavior = "previous",
			move_cursor_same_row = true,
			cursor_follows_swapped_bufs = true,
			-- ignore these autocmd events (via :h eventignore) while processing
			-- smart-splits.nvim computations, which involve visiting different
			-- buffers and windows. These events will be ignored during processing,
			-- and un-ignored on completed. This only applies to resize events,
			-- not cursor movement events.
			ignored_events = {
				"BufEnter",
				"WinEnter",
			},
			-- enable or disable a multiplexer integration;
			-- automatically determined, unless explicitly disabled or set,
			-- by checking the $TERM_PROGRAM environment variable,
			-- and the $KITTY_LISTEN_ON environment variable for Kitty.
			-- You can also set this value by setting `vim.g.smart_splits_multiplexer_integration`
			-- before the plugin is loaded (e.g. for lazy environments).
			multiplexer_integration = nil,
			-- disable multiplexer navigation if current multiplexer pane is zoomed
			-- NOTE: This does not work on Zellij as there is no way to determine the
			-- pane zoom state outside of the Zellij Plugin API, which does not apply here
			disable_multiplexer_nav_when_zoomed = true,
			-- Supply a Kitty remote control password if needed,
			-- or you can also set vim.g.smart_splits_kitty_password
			-- see https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.remote_control_password
			kitty_password = nil,
			-- In Zellij, set this to true if you would like to move to the next *tab*
			-- when the current pane is at the edge of the zellij tab/window
			zellij_move_focus_or_tab = false,
			-- default logging level, one of: 'trace'|'debug'|'info'|'warn'|'error'|'fatal'
			log_level = "info",
		})
	end,
}
