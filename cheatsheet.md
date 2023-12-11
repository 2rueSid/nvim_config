# Vim Cheat Sheet

## General

### Navigation

- `h`, `j`, `k`, `l`: Move left, down, up, right.
- `[number]hjkl`: Repeat motion `[number]` times; e.g., `10j` moves down 10 lines.
- `$`: Move to end of the line.
- `_`: Move to the first non-blank character in the line.
- `0`: Move to the beginning of the line.
- `w`: Move forward word by word.
- `b`: Move backward word by word.
- `gg`: Move to the beginning of the file.
- `G`: Move to the end of the file.
- `[number][command]`: Perform `[command]` `[number]` times; e.g., `10+w` moves 10 words forward.

### Finding Characters

- `f[char]`: Jump to the first occurrence of `[char]` in the line.
- `F[char]`: Jump to the first occurrence of `[char]` backwards in the line.
- `t[char]`: Jump right before the first occurrence of `[char]` in the line.
- `T[char]`: Jump right before the first occurrence of `[char]` backwards in the line.
- `;`: Navigate to the next occurrence of the symbol.
- `,`: Navigate to the previous occurrence of the symbol.

### Edit Mode

- `dd`: Delete the current line.
- `u`: Undo the last change.
- `Ctrl + r`: Redo the last change.
- `[command][motion]`: Combine a command with a motion; e.g., `d10k` deletes 10 lines upward.

### Visual Mode

- `v`: Enter visual mode to highlight text.
- `V`: Enter visual line mode to highlight entire lines.
- `[motion]`: Combine with motions in visual mode; e.g., `v10l` highlights 10 characters to the right.
- `y`: Copy highlighted text to the clipboard.
- `p`: Paste the yanked text under the cursor.

### Insert Mode

- `i`: Enter insert mode at the cursor.
- `a`: Enter insert mode after the cursor.
- `I`: Enter insert mode at the beginning of the line.
- `A`: Enter insert mode at the end of the line.
- `o`: Open a new line below and enter insert mode.
- `O`: Open a new line above and enter insert mode.

### File and Window Management

- `Sex!`: Open file explorer in a split window.
- `Ex!`: Open file explorer in the current window.
- `w`: Save file.
- `q`: Quit Vim.
- `wq`: Save and quit Vim.
- `:e [file name]`: Create or open a file.

## Keybindings

### Built-in Navigation

- Ctrl + n: Switch to the next file in the buffer.
- Ctrl + p: Switch to the previous file in the buffer.
- Leader + ch: Open cheatsheet file
### Telescope Keybindings

- Leader + ff: Use Telescope to list files in the current working directory (respects .gitignore).
- Leader + fg: Use Telescope to live search for a string in the current working directory (requires ripgrep, respects .gitignore).
- Leader + fs: Use Telescope to search for the string under the cursor or a selected string in the current working directory.
- Leader + fb: Use Telescope to list open buffers in the current Neovim instance.
- Leader + fo: Use Telescope to list previously opened files.
- Leader + ft: Use Telescope with Treesitter to list function names, variables, etc.

### Harpoon Keybindings

- Leader + a: Append the current file to the Harpoon list.
- Ctrl + e: Toggle Harpoon's quick menu to display the list.
