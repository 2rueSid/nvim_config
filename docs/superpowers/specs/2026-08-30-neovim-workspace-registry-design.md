# Neovim Workspace Registry Plugin Design

**Date:** 2026-08-30
**Status:** Approved design

## Purpose

Add a local Neovim plugin that persistently registers arbitrary directories as labeled workspaces, lists them through fzf-lua with live Git metadata, and switches between in-process editor sessions without restarting Neovim.

The workspace plugin is independent of the existing worktree feature. A small shared session module will be extracted from `worktrees.nvim` so both plugins use the same tested capture, restore, LSP shutdown, and rollback mechanics while retaining different switching policies.

## Goals

- Register Neovim's exact current working directory with a user-provided label.
- Persist registrations across Neovim restarts and machine reboots.
- Support both Git and non-Git directories.
- Reject duplicate canonical paths while allowing duplicate labels.
- List registered workspaces in fzf-lua with live branch and concise Git status metadata.
- Switch to a selected workspace without restarting Neovim.
- Preserve independent tabs, splits, buffers, folds, cursors, and views for workspaces visited during the current Neovim process.
- Preserve unsaved buffer contents while switching.
- Stop source-rooted LSP clients and let normal buffer-loading autocommands start destination clients.
- Notify other plugins after a successful switch through a `User WorkspaceChanged` event.
- Deregister the current workspace through a command and mapping.
- Keep missing registrations visible and manually removable.
- Preserve all current `worktrees.nvim` behavior after extracting shared session mechanics.

## Non-goals

- SQLite or `/tmp` storage.
- Automatic workspace discovery.
- Persisting tabs, buffers, or layouts across Neovim restarts.
- Editing labels in place; users may deregister and add again.
- Automatically pruning missing paths.
- Caching Git status.
- Fully unloading or reloading lazy.nvim plugins.
- Deleting workspace directories during deregistration.
- Coordinating simultaneous registry writes from multiple Neovim processes.
- Supporting another picker implementation.
- Publishing either plugin or adding public-package metadata.

## Architecture

```text
custom-plugins/
├── workspace-session.nvim/
│   └── lua/workspace_session/init.lua
├── workspaces.nvim/
│   ├── plugin/workspaces.lua
│   ├── lua/workspaces/init.lua
│   ├── lua/workspaces/registry.lua
│   ├── lua/workspaces/git.lua
│   └── tests/
└── worktrees.nvim/
    └── lua/worktrees/session.lua

lua/plugins/workspaces.lua
lua/plugins/worktrees.lua
```

### `workspace-session.nvim`

This internal runtime module owns the mechanics shared by workspace and worktree switching:

- identify normal named file buffers;
- resolve path ownership using longest path-boundary matching;
- close non-file windows;
- capture restricted native session scripts;
- restore session scripts;
- preserve and clamp window views;
- stop source-rooted LSP clients;
- unload obsolete unmodified buffers while retaining modified buffers; and
- roll back to a just-captured source session after restoration failure.

The module receives a consumer-owned in-memory session table rather than maintaining one global table. Workspace and worktree sessions therefore cannot collide when both features refer to the same directory.

The switch operation accepts only the policy differences required by its two real consumers:

- whether modified file buffers block switching;
- whether an unvisited destination maps source-relative file paths or opens a clean window; and
- whether the source must belong to the supplied registry.

No command, mapping, persistence, Git discovery, or picker logic belongs in the shared module.

### `worktrees.session`

The existing `worktrees.session` module remains as a compatibility adapter. It owns the worktree session table and delegates mechanics to `workspace-session.nvim` with existing policies:

- modified buffers block switching;
- the source must be a registered worktree; and
- first visits map files by relative path.

Its current public API and tests remain valid.

### `workspaces.registry`

This module owns durable registration state at:

```text
stdpath("data")/workspaces.nvim/registry.json
```

The JSON document is an array containing only:

```json
[
  { "label": "API service", "path": "/absolute/canonical/path" }
]
```

The module:

- validates the document and every record when reading;
- canonicalizes new paths with `vim.uv.fs_realpath` and `vim.fs.normalize`;
- rejects empty labels and duplicate canonical paths;
- permits duplicate labels;
- writes a temporary sibling file and atomically renames it over the registry; and
- never overwrites malformed existing data.

No timestamps, generated IDs, migrations, or cached metadata are stored. Registry mutations use read-modify-write without multi-process locking; simultaneous Neovim writers are explicitly unsupported.

### `workspaces.git`

This module executes Git through argument arrays with `vim.system`; paths never enter shell command strings. It determines whether a workspace is a Git working tree and gathers:

- current branch or detached state;
- staged file count;
- unstaged file count;
- untracked file count; and
- commits ahead of and behind the configured upstream.

Status is calculated asynchronously whenever the picker opens. Non-Git directories are normal workspaces and return a non-Git result rather than an error.

### `workspaces.init`

This is the public Lua API and orchestration layer. It:

- prompts for labels;
- adds and removes registry records;
- gathers picker metadata;
- formats fzf rows and previews;
- revalidates selections;
- invokes the shared switching engine; and
- emits notifications and the post-switch user event.

### Runtime and lazy.nvim integration

`custom-plugins/workspaces.nvim/plugin/workspaces.lua` registers commands only. `lua/plugins/workspaces.lua` loads the local plugin, declares `fzf-lua` and `workspace-session.nvim` dependencies, and owns mappings.

`lua/plugins/worktrees.lua` adds `workspace-session.nvim` as a local dependency. No shared source is copied into either feature plugin.

## User Interface

### Commands and mappings

| Command | Mapping | Behavior |
| --- | --- | --- |
| `:WorkspaceAdd` | `<leader>wa` | Prompt for a label and register the canonical cwd. |
| `:WorkspaceList` | `<leader>ww` | Open the workspace picker. |
| `:WorkspaceDelete` | `<leader>wd` | Deregister the canonical cwd when it is an exact registry entry. |

Registration uses Neovim's exact cwd, not the enclosing Git root. Cancellation does nothing. An empty label or an already-registered canonical path produces a concise error and leaves the registry unchanged.

`:WorkspaceDelete` removes registry metadata only. It fails harmlessly when the exact canonical cwd is not registered.

### Workspace picker

Example rows:

```text
● API service     main       S:1 U:2 ?:0 ↑3 ↓0  /code/api
  Notes           —          —                   /notes
  Old project     [missing]                      /code/removed
```

- `●` marks the registered workspace that most specifically contains the current cwd.
- The label is user-provided and need not be unique.
- Git workspaces show branch and status counts.
- `S` counts paths with staged changes.
- `U` counts paths with unstaged changes.
- `?` counts untracked paths.
- `↑` and `↓` show upstream divergence; absent upstreams use `-`.
- Non-Git workspaces show `—` for Git fields.
- Missing paths show `[missing]`.
- Metadata failures show an error marker on only the affected row.

The preview displays the absolute path and, when available, `git status --short --branch` followed by recent one-line commits.

Picker actions:

- `Enter` re-reads the registry, revalidates the selected canonical path, and switches when the directory still exists.
- `Ctrl-d` removes the selected registry record, including a missing record, and closes the picker.

Missing workspaces remain visible but cannot be selected as destinations.

## Workspace Switching

### Source resolution

The source is the registered workspace with the longest path-boundary match containing the current cwd. This supports a registered workspace containing a nested registered workspace without assigning files to the broader root.

When no registered workspace owns cwd, cwd is used as a temporary source root for session rollback and LSP cleanup. Switching remains allowed, but the source receives neither a registry entry nor a named restorable session.

### Capture and transition

Before changing workspace, the plugin:

1. Re-reads the registry and confirms that the selected destination still matches a record.
2. Confirms that the destination directory exists.
3. Resolves the source root.
4. Closes terminal, quickfix, help, nvim-tree, fzf, and other non-file windows.
5. Captures the source tabs, splits, named file buffers, folds, cursor positions, and views with restricted native `:mksession` state.
6. Stores the captured script only when the source is a registered workspace.
7. Stops LSP clients whose roots belong to the source.

Modified file buffers do not block workspace switching. They remain loaded and hidden, retaining unsaved contents. Obsolete unmodified source buffers may be unloaded because a captured session can reopen them.

### Destination restoration

For a destination already visited during the current process, the plugin restores its last captured session. Existing loaded modified buffers are reused, preserving their unsaved contents.

For an unvisited destination, the plugin opens one clean unnamed normal window and sets global cwd to the destination. It does not map source-relative files, scan for a default file, or open `README.md` automatically.

Normal buffer-loading autocommands start destination LSP clients and let existing plugins react to cwd and buffer changes.

### Post-switch event

After a successful restoration and cwd change, the plugin emits:

```lua
vim.api.nvim_exec_autocmds("User", {
  pattern = "WorkspaceChanged",
  data = { from = source_path, to = destination_path },
})
```

Plugins requiring explicit refresh can subscribe to this event. The event is not emitted for a no-op selection or failed switch. The plugin does not unload or reload lazy.nvim plugins.

### Rollback

The source session captured immediately before transition is retained for rollback even when the source is unregistered. If destination restoration, cwd change, or another transition step fails, the plugin restores that source script and reports the original error. If rollback also fails, the error includes both failures and the source and destination paths.

## Deregistration Semantics

Deregistration removes only the matching `{ label, path }` record. It does not:

- delete the directory;
- wipe or unload its buffers;
- terminate its LSP clients;
- delete its process-local session; or
- switch away from it.

Retaining process-local session state makes an accidental deregistration non-destructive. The state becomes unreachable through the picker unless the path is registered again during the same process.

## Error Handling

- Invalid labels and duplicate paths fail before mutation.
- Invalid JSON or invalid record shapes are reported without overwriting the registry.
- A missing registry file represents an empty registry.
- Directory creation and atomic replacement failures include the registry path.
- A single Git metadata failure does not prevent the picker from opening.
- A missing selected directory cannot become cwd.
- Picker selections are revalidated after fzf closes.
- Switching failures restore the source editor state when possible.
- Expected operational failures use concise `vim.notify` messages; programming errors are not hidden by broad silent `pcall` wrappers.

## Testing

No new test framework is added. Tests use headless Neovim, built-in Lua assertions, `vim.system`, temporary directories, and temporary Git repositories.

Automated coverage includes:

- empty-registry behavior;
- registry read/write round trips;
- canonical duplicate rejection;
- duplicate-label acceptance;
- malformed JSON and malformed-record rejection without overwrite;
- atomic registry replacement;
- exact-cwd registration and deregistration;
- Git, detached, non-Git, metadata-error, and missing picker rows;
- asynchronous metadata completion before picker opening;
- picker selection revalidation;
- `Ctrl-d` removal, including missing records;
- clean first visits;
- registered per-workspace session restoration;
- switching from an unregistered source;
- unsaved buffer preservation across repeated switches;
- source-only LSP client shutdown;
- successful `WorkspaceChanged` event data;
- no event after failure;
- rollback after an injected destination restoration failure; and
- all existing `worktrees.nvim` ownership, modified-buffer rejection, relative mapping, session restoration, and rollback behavior through the extracted engine.

A manual smoke test verifies real fzf rendering and preview, add/list/delete mappings, Git metadata, non-Git workspaces, clean first visits, restored layouts, unsaved edits, LSP restart, and plugin refresh through `WorkspaceChanged`.

## Acceptance Criteria

- `<leader>wa` registers the exact canonical cwd with a non-empty user label in durable JSON storage.
- Registering the same canonical path twice aborts without changing the original record.
- Duplicate labels on different paths are accepted.
- `<leader>ww` lists all registrations, including non-Git and missing directories.
- Git rows display branch and concise live status; no Git metadata is persisted.
- Selecting an existing workspace changes global cwd without restarting Neovim.
- A first visit opens one clean unnamed window.
- Returning to a visited workspace restores its tabs, splits, buffers, folds, cursors, and views for the current process.
- Unsaved file contents survive switching and restoration.
- Source-rooted LSP clients stop, destination buffers trigger normal startup behavior, and successful switches emit `User WorkspaceChanged`.
- A switch failure restores the source editor state and emits no success event.
- `<leader>wd` deregisters the exact current workspace without deleting files or buffers.
- `Ctrl-d` removes a selected missing registration from the picker.
- The registry survives Neovim and machine restarts.
- Existing `worktrees.nvim` behavior and tests remain unchanged after session-engine extraction.
