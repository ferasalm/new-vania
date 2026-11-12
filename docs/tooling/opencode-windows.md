# OpenCode on Windows — shell, MCP, and crash diagnosis

Tooling record for the `new-vania` repo. Everything here was measured on
2026-11-12 with OpenCode **v2.2.2** (CLI) and desktop app **v2.1.3** on
Windows 11 (build 26100), PowerShell 5.1, Node 26.8.1.

---

## 1. Shell binary

### Decision

The `shell` path lives in the **global** config only:

```
C:\Users\AUC\.config\opencode\opencode.json
  "shell": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
```

It is **not** in the project `opencode.json`.

### Why

The project config is committed and shared. A Windows absolute path there is
machine-specific, breaks non-Windows clones, and would be the only
OS-specific key in an otherwise portable file. OpenCode merges config sources
per key, so a project file that omits `shell` inherits the global value.

The fix was needed because the harness's default `pwsh` resolution landed on
the **0-byte WindowsApps alias** at
`C:\Users\AUC\AppData\Local\Microsoft\WindowsApps\pwsh.exe`. Every shell spawn
failed with "The system cannot find the path specified". Naming Windows
PowerShell 5.1 explicitly fixed it. PS7 is not installed on this machine —
only the alias exists.

### Verified

A private server (`opencode run --standalone`) — i.e. a genuinely fresh
session, not the one that edited the config — ran `git rev-parse --short HEAD`
and returned `a93c21f`. The `shell` value came from the global file.

### Fallback for another machine

If the shell breaks elsewhere, add the same key to that machine's **global**
config pointing at its own shell. Do not add it to the project file. See
`opencode debug config`, which lists every config source and its contents in
merge order.

---

## 2. Godot MCP

### Decision

Install the server as a pinned dev dependency at `tools/godot-mcp/` and launch
it by a **repo-relative** path:

```json
"command": ["node", "tools/godot-mcp/node_modules/@coding-solo/godot-mcp/build/index.js"]
```

Pinned at `@coding-solo/godot-mcp@0.1.1`. `GODOT_PATH` is kept.

### Why

The previous command was `npx -y @coding-solo/godot-mcp`, then a hard-coded
`C:\Users\AUC\AppData\Local\npm-cache\_npx\6e568f649a25892d\...\index.js`.
Both are volatile: the `_npx` directory name is a hash, and `npx` re-resolves
the package on cold start. A cache clean or an upstream publish silently
changes what runs.

### Verified

`opencode mcp list` → `godot connected` with the `npx` cache directory renamed
out of the way, proving the relative path — not the cache — is what serves the
server. A fresh `--standalone` session then called `godot_get_godot_version`
and got `4.7.2.stable.official.ed1daf0bf`.

### Fallback

`GODOT_PATH` is checked first, then the package auto-detects common install
locations. Override it in your global config; see
`tools/godot-mcp/README.md` for the snippet.

---

## 3. The occasional CLI crash — what the evidence says

### Verdict

**The RAM hypothesis is not supported for the CLI or the server.** There is
exactly one genuine out-of-memory event in the record, and it is a **child
process** — the Godot MCP server — not OpenCode.

### Evidence collected

| Source | Result |
|---|---|
| `opencode --version` | `2.2.2` |
| `opencode service status` | `http://127.0.0.1:28894` |
| Log | `~/.local/share/opencode/log/opencode.log`, 27.9 MB, 2026-10-22 → 2026-11-12 |
| DB | `opencode.db` **188 MB** (plus 14.7 MB WAL) |
| `opencode stats --days 7` | 109 sessions, 104 subagents, 187 prompts, 5.4k steps, 943m tokens |
| Sessions in this project | 32 (`session list --max-count 100`) |
| Event Viewer (Application, 8 days, level 1–3) | **zero** `opencode`/`node` entries |
| Crashpad dumps | **none** (only `metadata`, `settings.dat`) |
| Desktop `crash.log` | "crash reporter started" only, both sessions |
| Desktop renderer errors | 8,567, all `ResizeObserver loop completed with undelivered notifications` (benign DOM noise) |
| Memory, 50 min of heavy tool use | server WS 384 → 393 MB, private 668 → 704 MB (+36 MB) |
| System memory | 15.7 GB total, 2.7–2.8 GB free, Memory Compression 656 MB, commit 10.2/31.4 GB free |

Log level tally over the whole file: **96,831 INFO / 738 WARN / 180 ERROR**.
Literal-string counts, after excluding lines that merely *quote* the search
terms in logged shell commands:

| Pattern | Real occurrences |
|---|---|
| `JavaScript heap out of memory` | 0 |
| `FATAL ERROR` | 0 |
| `SIGABRT` | 0 |
| `Fatal process out of memory` | **1** (Godot MCP child, see below) |

### The one real OOM

```
2026-11-11T02:59:31.962Z level=WARN run=6c1c63fa message="mcp transport error"
  server=godot error="MCP server process exited with code 3: ...
  # Fatal process out of memory: AlignedAlloc
  ... v8::Isolate::Initialize ... node::Start ..."
2026-11-11T02:59:32.263Z level=WARN message="mcp connect failed" server=godot
  status.status=failed
```

The child died during `v8::Isolate::Initialize` — it could not allocate its
**initial** heap. The parent server logged a WARN, marked the MCP failed, and
kept running. No CLI crash.

This matters for the fix: raising `--max-old-space-size` makes an
**initial-allocation** failure *worse*, not better, because it reserves more
address space up front. Do not set it as a reflex. The pinned install removes
the extra `npx` → `node` process layer, which is the part we can actually
control.

### Crash-adjacent events (all explainable)

- **7× `run could not resolve its server: Standalone server exited before
  reporting readiness`** — all on 2026-11-10T22:19, all `--standalone`, and the
  last one was a bare `opencode run --standalone "Reply with exactly: PONG"`.
  So it was the private-server boot that failed, not the prompt. Not
  reproducible now: the same flag worked in this session.
- **2× `unhandled rejection: EPIPE: broken pipe, write`** (2026-11-02) —
  the CLI writing to a stdout that had already closed. Terminal/TUI teardown,
  not a compute crash.
- **23× `cli process failed`** — mostly `CliError/ShowHelp: Help requested`
  from bad `--model` values, plus one `EPERM` renaming `service.json` (Windows
  file lock).
- **45× `Failed to drain Session`** — every one is an API error ("Free usage
  limit reached", "Insufficient unified billing credits"). Billing, not crash.

### The structural risk worth naming

The desktop app **v2.1.3** owns the shared background server on port **28894**
— the same URL `opencode service status` reports. The desktop app's own log
records the mismatch:

```
v2 CLI background service starting { reason: 'version-mismatch', previousVersion: '2.2.2' }
v2 CLI background service ready { version: '2.1.3', url: 'http://127.0.0.1:28894' }
```

So: CLI 2.2.2, bundled desktop service 2.1.3, and 2.2.7 is downloaded and
sitting in `@opencodedesktop-updater\pending\` since 2026-11-11T15:21. When
the desktop app restarts — update, quit, or its own failure — every CLI
attached to that server loses it. That is the most plausible mechanism for a
"the CLI just died" report, and it is a **version-skew** problem, not memory.

**Recommended, not performed:** install the pending 2.2.7 update at a natural
break. It was deliberately not done during this session because applying it
restarts the desktop app and would kill the server hosting the session.

### Resource churn (measured, not proven causal)

Watchers over the whole log: **13,391 started / 11,745 stopped / 31,859
subscribes**, dominated by three copies of the same skill tree:

| Path | Watcher starts |
|---|---|
| `C:\Users\AUC\.agents\skills` | 3,958 |
| `C:\Users\AUC\.claude\skills` | 3,511 |
| `<repo>\.claude\skills` | 2,435 |

Median interval between `.agents\skills` watcher starts in the recent window:
**4.2 s**. No watcher errors are logged — this is churn, not a retry loop.
Every `opencode` CLI invocation boots a server that subscribes to all of them,
and `.opencode/skills` is a junction to `.agents/skills`. It is real overhead
on Windows but is not evidence of a crash.

### Mitigation applied

1. Godot MCP runs from one pinned, repo-relative install (above).
2. `--max-old-space-size` deliberately **not** raised — the only OOM was an
   initial allocation, where a larger reservation is counterproductive.
3. No session deletion, no DB surgery, no service re-registration, no
   uninstall.

### Instrumentation plan for the next trigger

If it recurs, capture in this order before restarting anything:

1. **Which process died?** Event Viewer (`Application`, level 1–3) for
   `opencode`/`node`; Crashpad under
   `%APPDATA%\ai.opencode.desktop\Crashpad`; desktop
   `logs\<stamp>\crash.log`.
2. **Role split.** `role=cli` vs `role=server` in the log tail tells you
   whether the TUI, the shared server, or a child MCP died. `--standalone`
   isolates a private server from the desktop app's shared one.
3. **Memory at the moment.** Sample
   `Get-Process | ? { $_.ProcessName -match 'opencode|node' } |
   select ProcessName,Id,WorkingSet64,PrivateMemorySize64`
   every ~60 s into a file. If the server's private bytes climb past ~1.5 GB
   without settling, run `opencode debug heap-dump` **while it is high** and
   keep the snapshot path.
4. **Log tail** around the timestamp, plus the exact literal counts above
   (filtering out lines that merely quote the search terms).

Record the result here. Do not change `NODE_OPTIONS`, `tool_output`,
`compaction`, or `location_idle_timeout` until one of those shows up in the
evidence.

---

## 4. Throwaway bridge cleanup

The 2026-11-11/12 sessions landed commits through a disclosed Godot
`OS.execute` bridge while the shell tool was broken. Six untracked files lived
in `prototypes/combat-concept-test/`:

```
exec_bridge.gd  exec_bridge.tscn  repair_bridge.gd
repair_bridge.tscn  manifest_dump.gd  manifest_dump.tscn
```

They were **never committed** and were **deleted** once the shell and the MCP
were both verified working. Nothing in the repo references them.
