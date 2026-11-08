# Claude Code Compatibility Guide

OpenCode Game Studios (OCGS) runs on [Claude Code](https://code.claude.com/docs/) alongside OpenCode, Pi, oh-my-pi and Codex.
Claude Code 2.1.277+ reads `AGENTS.md` natively, so no `CLAUDE.md` is needed.

## Quick Start

```bash
npm install          # git hooks + tsx (needed by the Claude Code hooks)
claude
```

On first start, approve the project MCP servers in `.mcp.json` when prompted.
Type `/` to see the OCGS skills; start with `/start` or `/ocgs-help`.

## What Lives Where

```
.agents/{agents,skills,rules}   ← canonical OCGS content; edit here
.claude/
  agents/  skills/  rules/      ← generated mirror of .agents/ (do not edit)
  ocgs-sync.json                ← list of generated files and their sources
  rules/ocgs-framework.md       ← hand-written: Claude Code notes, always loaded
  settings.json                 ← shared permissions and hooks
  hooks/ocgs-hooks.mjs          ← hook adapter (reuses .opencode/plugins/ccgs-hooks.ts)
  settings.local.json           ← per-user (gitignored), e.g. MCP approvals
.mcp.json                       ← project MCP servers (aseprite, godot)
```

## The `.claude/` Mirror

Claude Code reads subagents, skills and rules only from `.claude/`. `npm run claude:sync`
(`tools/sync-claude.mjs`) writes them from `.agents/` and records every generated path in
`.claude/ocgs-sync.json`. It only rewrites or removes files listed there, so hand-written files
under `.claude/` are safe. A generated file that collides with an existing hand-written file is
reported as a conflict and skipped unless you pass `--force`.

| Source | Mirror | Change |
|---|---|---|
| `.agents/agents/*.md` | `.claude/agents/*.md` | Adds the `name:` frontmatter Claude Code requires |
| `.agents/skills/<name>/` | `.claude/skills/<name>/` | `allowed-tools`: `question` → `AskUserQuestion`, `Task` → `Agent`, `webfetch` → `WebFetch` |
| | | A `context: \|` preload block (not valid in Claude Code) becomes a "Context preload" note under the title |
| `.agents/skills/help/` | `.claude/skills/ocgs-help/` | Renamed: Claude Code's built-in `/help` would take the name |
| `.agents/skills/code-review/` | `.claude/skills/ocgs-code-review/` | Renamed: a built-in or personal `/code-review` would take the name |
| `.agents/rules/*.md` | `.claude/rules/*.md` | Unchanged (`paths:` frontmatter already works) |
| `.agents/commands/` | — | Not mirrored: every Claude Code skill is already a slash command |

All `/help` and `/code-review` command references inside mirrored files are renamed to match.

### Keeping it in sync

After changing anything in `.agents/{agents,skills,rules}`:

```bash
npm run claude:sync    # regenerate .claude/
npm run claude:check   # exit 1 if .claude/ is stale (no writes)
```

Commit the `.agents/` change and the regenerated `.claude/` files together. Restart Claude Code
(or start a new session) so it reloads agents and skills. Drift is caught at four points:

- the Claude Code `SessionStart` hook reports a stale mirror;
- editing a generated file adds a note pointing at its `.agents/` source;
- the pre-commit hook runs `claude:check` when mirrored paths or `.claude/` are staged;
- `npm test` (and the CI `test` workflow) includes a test that the committed mirror is in sync.

### Adding modules

The module installer's `--harness claude` target copies from `.agents/modules/`, whose copies
currently lag behind canonical `.agents/` content. In this repository, install modules into
`.agents/` instead (`--harness pi` writes there directly), then run `npm run claude:sync`.

## Hooks

`.claude/settings.json` runs `node .claude/hooks/ocgs-hooks.mjs <event>`. The adapter maps
Claude Code hook events onto the functions in `.opencode/plugins/ccgs-hooks.ts`, so OpenCode and
Claude Code share one implementation.

| Claude Code event | OCGS behaviour |
|---|---|
| `SessionStart` (startup, resume, clear) | Adds branch, recent commits, active sprint/milestone, open bugs, TODO counts and project gaps to context; warns if `.claude/` is stale |
| `SessionStart` (compact) | Points Claude back at `production/session-state/active.md` |
| `PreCompact` | Sends `active.md`, modified files and design-doc WIP markers into the compaction summary |
| `SessionEnd` | Archives `active.md` and a session summary to `production/session-logs/session-log.md` |
| `PreToolUse` · Bash `git commit` | Blocks the command when staged `assets/data/*.json` is invalid; passes design-doc, hardcoded-value and TODO warnings to Claude |
| `PreToolUse` · Bash `git push` | Reminder when pushing to `main`, `master` or `develop` |
| `PreToolUse`/`PostToolUse` · `Agent` | Logs subagent start and finish to `production/session-logs/agent-audit.log` |
| `PostToolUse` · `Write`/`Edit` | Asset naming and JSON checks under `assets/`; `/skill-test` reminder for skill changes; note when a generated `.claude/` file or a mirrored `.agents/` file is edited |

The TypeScript module loads through `tsx` only when an event needs it. Other Bash calls return in
under 100 ms. Without `npm install` the hooks stay inactive and say so at session start.
Tests: `npm run test:claude`.

## Permissions

`.claude/settings.json` mirrors the `opencode.json` policy:

- **Allowed without prompting:** read-only git (`status`, `diff`, `log`, `branch`, `rev-parse`),
  `ls`/`dir`, `python -m json.tool`, pytest, and the repo's test and `claude:*` npm scripts.
- **Denied:** `rm -rf`, force pushes, `git reset --hard`, `git clean -f*`, `sudo`, `chmod 777`,
  and reading `.env` files.

Skill `allowed-tools` pre-approve the listed tools while a skill runs, which is Claude Code's
meaning for that field. Deny rules still apply. Personal overrides go in
`.claude/settings.local.json`.

## OCGS Names in Claude Code

Skill bodies are shared with other harnesses, so some still use OpenCode names.
`.claude/rules/ocgs-framework.md` (always loaded) tells Claude how to read them:

| OCGS text | Claude Code |
|---|---|
| `question` tool | `AskUserQuestion` |
| `Task` tool / delegate to an agent | `Agent` tool with `subagent_type` = the OCGS agent name |
| `/help`, `/code-review` | `/ocgs-help`, `/ocgs-code-review` |
| `.opencode/agents`, `.opencode/skills`, … | the same path under `.agents/` |

## Known Gaps

- **Commit gate timing:** the commit check sees what is staged when the hook runs. In
  `git add x && git commit`, `x` is not yet staged and is not checked.
- **Protected-branch match is case-sensitive:** the shared `detectPushToProtected` matches `main`,
  `master` and `develop` exactly, so this repository's `Main` branch gets no push reminder.
- **Skill `agent:` and `isolation:` fields:** Claude Code applies `agent:` only together with
  `context: fork`, and skills have no `isolation:` field. OCGS skills therefore run in the main
  session, which keeps their interactive `AskUserQuestion` flows working.
- **Desktop notifications:** the OpenCode plugin's notification helper is not ported; Claude
  Code has its own notification settings.
- **OpenCode and `.claude/`:** OpenCode v2 does not read `.claude/agents/`; it loads the same
  agents with or without the mirror. Its Claude Code compatibility mode can read
  `.claude/skills/`, which would list the mirrored skills next to the `.agents/` ones. Set
  `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` where OpenCode runs to keep it on `.agents/` only.
