# godot-mcp (pinned local install)

The OpenCode `godot` MCP server is launched from **this** directory, not from the
`npx` cache. The `npx` cache path is hashed and volatile: a cache clean, an
`npx` re-resolve, or a second machine silently produced a different directory
and the server failed to start.

## Install

```bash
npm install          # from tools/godot-mcp/
```

`node_modules/` is gitignored. Only `package.json` and `package-lock.json` are
committed, so the resolved dependency tree is reproducible.

## Wiring

`opencode.json` at the repository root points the MCP server at the installed
entry point, **relative to the project root**:

```json
"command": ["node", "tools/godot-mcp/node_modules/@coding-solo/godot-mcp/build/index.js"]
```

The MCP client spawns local servers with the project root as the working
directory, so this resolves on every clone and on every OS. Verified by
disabling the `npx` cache entirely and re-running `opencode mcp list` — the
server still connected.

## Godot binary

The server needs a Godot executable. Resolution order (from the package's own
`GODOT_PATH` handling):

1. `GODOT_PATH` from the MCP server environment (set in `opencode.json`).
2. Auto-detection in the platform's common install locations.
3. In strict mode, exit with an error telling you to set `GODOT_PATH`.

**The committed `GODOT_PATH` is the primary dev machine's path.** The package's
Windows auto-detect only looks in `C:\Program Files\Godot`, `C:\Program Files
(x86)\Godot`, their `Godot_4` variants, and `%USERPROFILE%\Godot`, so it will
not find an install kept anywhere else.

### Overriding it on another machine

A project `mcp.servers.godot` entry **replaces the whole server object** of the
same name in the global config — OpenCode does not deep-merge it. A `GODOT_PATH`
set on a global `godot` entry is therefore ignored while the project entry
exists. Override it one of these ways instead.

**Option A — environment variable (portable, verified).** Change the committed
value to an env reference:

```json
"environment": { "GODOT_PATH": "{env:GODOT_PATH}" }
```

then set `GODOT_PATH` for the process that launches OpenCode. Verified on CLI
2.2.2: with the variable set, `godot_get_godot_version` returned
`4.7.2.stable.official.ed1daf0bf`. Set it **before** the app or terminal starts,
because a running process does not pick up a later change.

**Option B — edit the committed value.** One line in `opencode.json`, no
environment dependency. This is what the repo currently does, deliberately: the
primary machine has no `GODOT_PATH` set, and a missing variable would make the
server fall through to auto-detect, which cannot find this install. Edit and
revert as needed on a per-machine branch.

The engine pin is Godot **4.7.2** (see `docs/engine-reference/godot/VERSION.md`);
`godot_get_godot_version` should report `4.7.2.stable`.

## Why not `npx -y @coding-solo/godot-mcp`

- The cache directory name is a hash of the npx invocation; it changes.
- `npx` re-resolves the package on every cold start, so an upstream publish can
  change what runs under you mid-project.
- On Windows the extra `npx` → `node` process layer widened the window for the
  one OOM we observed (see `docs/tooling/opencode-windows.md`).
