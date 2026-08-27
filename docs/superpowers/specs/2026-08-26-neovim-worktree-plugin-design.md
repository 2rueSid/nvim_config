# Neovim Worktree Plugin Design

**Date:** 2026-08-26
**Status:** Approved design

## Purpose

Add a local Neovim runtime plugin for creating, inspecting, switching, and merging Git worktrees without leaving the current Neovim process. Worktrees created by the plugin live under the repository root at `.worktrees/<name>`.

The plugin lives under `custom-plugins/worktrees.nvim/` and follows Neovim's standard runtime layout so it can later move into its own repository without restructuring its implementation. The parent configuration loads it through lazy.nvim and installs `fzf-lua` separately as its only plugin dependency. Nothing is vendored into the plugin.

## Goals

- Create a worktree and same-named branch from the current `HEAD`.
- List every worktree registered to the current repository.
- Show useful Git status for every worktree in an fzf-lua picker.
- Switch worktrees while keeping Neovim running.
- Preserve independent tab and split layouts for worktrees visited during the current Neovim process.
- Map open files to the same relative paths on the first visit to another worktree.
- Merge a selected worktree branch into the branch currently checked out in the main worktree.
- Prefer safe refusal over automatic saving, stashing, branch switching, or destructive cleanup.

## Non-goals

- Persist workspace layouts across Neovim restarts.
- Preserve terminal, quickfix, help, nvim-tree, or other plugin windows.
- Delete worktrees or branches after merging.
- Choose a different merge target or automatically switch the main worktree branch.
- Preserve unsaved buffer contents during a switch.
- Support `/` in plugin-created worktree names.
- Maintain a worktree registry separate from Git.
- Add support for another picker implementation.
- Add a README, Vim help, license, CI, release configuration, or other public-package metadata in this change.
- Publish the plugin or move it into a separate repository in this change.

## User Interface

### Commands and mappings

| Command | Mapping | Behavior |
| --- | --- | --- |
| `:WorktreeCreate` | `<leader>wc` | Prompt for a name, create the worktree, and switch to it. |
| `:WorktreeList` | `<leader>wl` | Open the worktree picker; `Enter` switches to the selected worktree. |
| `:WorktreeMerge` | `<leader>wm` | Select a source worktree and merge it into the main worktree's current branch. |

The plugin registers the three user commands and exposes `create()`, `list()`, and `merge()` as Lua entry points. The parent lazy.nvim spec owns mappings, dependency declaration, and loading. The plugin does not impose mappings or introduce a generic `setup()` API.

### Worktree picker

The picker source of truth is:

```bash
git worktree list --porcelain
```

The plugin parses every registered worktree, including worktrees outside `.worktrees/`. It does not scan directories or maintain its own registry.

A row has this shape:

```text
● main       main       S:1 U:2 ?:0 ↑3 ↓0  /usr/app
  A          A          S:0 U:4 ?:2 ↑0 ↓1  /usr/app/.worktrees/A
```

- `●` marks the worktree containing Neovim's current cwd.
- The first text column is the worktree name; the second is its branch.
- `S` counts paths with staged changes.
- `U` counts paths with unstaged changes.
- `?` counts untracked paths.
- A path with both staged and unstaged changes contributes to both counts.
- `↑` and `↓` show commits ahead of and behind the configured upstream.
- Missing upstreams display `↑- ↓-`.
- Detached, locked, and prunable worktrees receive visible labels.
- A worktree whose status cannot be read remains selectable but displays `ERR`.

Status is recalculated with asynchronous `vim.system` calls whenever the picker opens. The preview displays `git status --short --branch` followed by recent one-line commits. No status cache is retained.

## Architecture

```text
custom-plugins/worktrees.nvim/
├── plugin/
│   └── worktrees.lua       User-command registration
├── lua/worktrees/
│   ├── init.lua            Public operations and fzf-lua integration
│   ├── git.lua             Git execution and porcelain parsing
│   └── session.lua         In-process workspace state and switching
└── tests/                  Headless plugin tests

lua/plugins/worktrees.lua   Parent lazy.nvim integration and mappings
```

The lazy.nvim integration loads the local plugin with:

```lua
dir = vim.fn.stdpath("config") .. "/custom-plugins/worktrees.nvim"
```

It declares `ibhagwan/fzf-lua` as a separate dependency and defines `<leader>wc`, `<leader>wl`, and `<leader>wm`. The runtime plugin contains no copied dependency code and does not depend on unrelated parent-config modules.

### `plugin/worktrees.lua`

This runtime entry point registers `:WorktreeCreate`, `:WorktreeList`, and `:WorktreeMerge`. It contains no feature logic beyond command registration.

### `worktrees.git`

This module owns repository discovery and Git execution:

- Resolve the current worktree root with `git rev-parse --show-toplevel`.
- Resolve the common Git directory with `git rev-parse --git-common-dir` and derive the main worktree root from it.
- Execute Git with argument arrays through `vim.system`, using `git -C <path>` where appropriate.
- Parse `git worktree list --porcelain` and porcelain status output.
- Collect staged, unstaged, untracked, and upstream counts.
- Validate and create worktrees.
- Validate and perform merges.

No command uses shell interpolation.

### `worktrees.session`

This module owns state keyed by canonical worktree path:

- Save a controlled native `:mksession` script for each visited worktree.
- Keep session scripts only in a Lua table for the lifetime of the current process.
- Restore a previously visited worktree's session.
- Map source-relative file paths on a destination's first visit.
- Close non-file windows.
- Reject switches while normal buffers are modified.
- Stop LSP clients rooted in the source worktree before destination files load.
- Roll back to the source session when destination restoration fails.

### `worktrees.init`

This module is the plugin's public Lua API and coordinates the feature:

- Prompt for creation names with `vim.ui.input`.
- Construct fzf-lua pickers and previews.
- Invoke repository, creation, switching, and merge operations.
- Format notifications and picker rows.
- Expose the three public operations used by commands and the parent lazy.nvim mappings.

## Repository and Worktree Rules

Given a repository at `/usr/app`, plugin-created worktrees have this layout:

```text
/usr/app/.git
/usr/app/.worktrees/A
```

The placement is based on the main repository root, not Neovim's startup subdirectory and not the currently selected linked worktree. The plugin creates `.worktrees/` when needed.

Creation idempotently adds this repository-local exclusion to the common Git directory's `info/exclude` file:

```gitignore
/.worktrees/
```

The project `.gitignore` is not modified.

A creation name:

- must be non-empty;
- must not contain `/` or a platform path separator;
- must pass `git check-ref-format --branch`;
- must not name an existing local branch; and
- must not resolve to an existing destination path.

For name `A`, creation runs the equivalent of:

```bash
git worktree add -b A /usr/app/.worktrees/A HEAD
```

The branch and directory have the same name. The new branch starts at the `HEAD` of the worktree from which creation was invoked. Successful creation immediately enters the normal switching flow. If creation succeeds but switching fails, the valid worktree remains and its path is reported.

## Workspace Switching

### Preflight

Before changing editor state, switching:

1. Confirms that the destination still appears in `git worktree list --porcelain`.
2. Rejects the operation if any normal file buffer has unsaved edits.
3. Captures the source and destination canonical worktree paths.

A preflight failure changes neither the editor workspace nor Git state.

### Source state capture

After preflight:

1. Close all non-file windows across all tabs. Tabs that contain no remaining normal file window may be removed.
2. Set the global cwd to the source worktree root.
3. Save the user's current `'sessionoptions'` value.
4. Temporarily use a restricted session configuration containing cwd, folds, tab pages, and window sizes. Hidden buffers, blank windows, terminals, help windows, global options, mappings, and globals are excluded.
5. Run `:mksession` into a unique temporary file.
6. Read the generated Vim script into the in-memory state table and immediately delete the temporary file.
7. Restore the user's original `'sessionoptions'` value even if capture fails.

The temporary file is only an interchange format for the built-in command. It is not a cache and requires no exit cleanup.

### First destination visit

When the destination has no saved session:

1. Keep the surviving tabs and split topology.
2. For each normal file window owned by the source worktree, compute its source-relative path.
3. Open the corresponding path below the destination root in that window.
4. If the destination file does not exist, open a normal new buffer at that path. Saving it creates the file.
5. Leave files outside the source worktree at their original absolute paths.
6. Preserve cursor positions and views where the corresponding destination buffer permits them.
7. Set cwd to the destination root.
8. Unload obsolete buffers owned by the source worktree.

Registered worktree paths are used to determine buffer ownership. This avoids treating `/usr/app/.worktrees/A/file` as a file owned by the main `/usr/app` worktree merely because its path is nested below it.

### Returning to a visited destination

When the destination has saved state:

1. Stop LSP clients whose roots belong to the source worktree.
2. Execute the destination's saved session script.
3. Ensure cwd is the destination worktree root.
4. Unload obsolete source-worktree buffers.

Normal buffer loading triggers the existing Neovim LSP configuration. nvim-tree is not restored; opening it later uses the destination cwd.

If destination restoration fails, the module executes the source session captured immediately before the attempt. A rollback failure is reported as a high-severity error with both worktree paths.

## Merge Workflow

`:WorktreeMerge` and `<leader>wm` open a picker for the source worktree. The only target is the branch currently checked out in the main worktree.

The operation rejects:

- selecting the main worktree as the source;
- a detached source worktree;
- identical source and target branches;
- a main worktree not currently on a branch;
- staged, unstaged, untracked, or conflicted changes in either source or main worktree; and
- relevant modified Neovim buffers.

The plugin does not switch branches or stash changes. After showing source and target branch names, it requires explicit confirmation and runs Git's normal configured merge in the main worktree:

```bash
git -C /usr/app merge A
```

It does not force fast-forward or no-fast-forward behavior.

On success:

- the source worktree and branch remain;
- Neovim remains in its current worktree; and
- if the main worktree is currently displayed, `:checktime` refreshes unmodified buffers changed by the merge.

On merge failure, the module checks whether Git left an active merge. If so, it runs `git merge --abort`. A successful abort is reported with the original merge error. If abort also fails, the module reports a high-severity error and the main worktree path for manual recovery. Failures that did not start a merge are reported without running an unrelated abort.

## Error Handling

- Operations outside a Git worktree fail with a concise notification.
- Git failures include the operation and relevant stderr, but routine stdout is not displayed.
- Invalid names, existing branches, and occupied paths fail before `git worktree add` runs.
- Status failure for one worktree does not prevent the picker from opening.
- Selection is revalidated after the picker closes to account for external worktree changes.
- Git subprocesses and session capture restore temporary editor options on every exit path.
- The merge path never claims that uncommitted source changes were included.

## Testing

No test framework or test dependency is added. Tests live inside `custom-plugins/worktrees.nvim/tests/` and use headless Neovim, built-in Lua assertions, `vim.system`, and temporary Git repositories.

Automated checks cover:

- worktree porcelain parsing, including detached, locked, and prunable records;
- staged, unstaged, untracked, and upstream count parsing;
- picker row formatting and missing-upstream/error states;
- repository and main-root resolution from the main worktree, a linked worktree, and a subdirectory;
- name validation;
- branch creation, destination placement, and idempotent `info/exclude` updates;
- first-visit relative-path mapping across tabs and splits;
- missing destination files opening as new buffers;
- external files retaining absolute paths;
- modified-buffer switch rejection;
- per-worktree session restoration;
- restoration rollback after an injected destination failure;
- clean merges;
- dirty source and target rejection; and
- merge conflict detection and successful abort.

The fzf-lua window receives a manual smoke test covering row rendering, preview output, and `Enter` switching. A terminal UI automation dependency is intentionally out of scope.

## Acceptance Criteria

- Creating `A` from `/usr/app` produces branch `A` at the invoking `HEAD`, creates `/usr/app/.worktrees/A`, and switches Neovim into it.
- The picker lists the same registered worktrees as `git worktree list --porcelain` and displays current status metrics.
- Switching changes global cwd while preserving all normal-file tabs and split layouts.
- A file open at `a.md` maps to `a.md` in the destination; a missing destination file opens as a new unsaved path.
- Returning to a visited worktree restores its last captured normal-file workspace for the current Neovim process.
- Unsaved normal buffers block switching.
- All non-file windows close during a successful switch.
- Merge accepts only clean source and main worktrees, targets only the main worktree's current branch, confirms before execution, and retains the source afterward.
- Merge conflicts are aborted automatically and reported.
- Exiting Neovim leaves no plugin-managed workspace state on disk.
- The plugin runs from `custom-plugins/worktrees.nvim/` through a local lazy.nvim spec, with `fzf-lua` declared separately.
- Moving `custom-plugins/worktrees.nvim/` to a standalone repository requires integration changes only, not restructuring plugin implementation files.
