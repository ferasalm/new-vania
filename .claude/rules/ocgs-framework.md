# OCGS on Claude Code

`AGENTS.md` is the main project guide. This rule covers only what differs in Claude Code.

## Where OCGS content lives

- **Canonical source:** `.agents/{agents,skills,rules}`. Make framework edits there.
- **Generated mirror:** `.claude/{agents,skills,rules}` is written by `npm run claude:sync` and listed in `.claude/ocgs-sync.json`. Never edit those files directly: change the `.agents/` source, run `npm run claude:sync`, and commit both. `npm run claude:check` reports drift.
- **Hand-written:** this rule, `.claude/settings.json` and `.claude/hooks/` are not part of the mirror.
- `.agents/commands/` is not mirrored: in Claude Code every skill is its own slash command.

## Translating OCGS instructions

OCGS skills and agents are shared with other harnesses. In Claude Code:

| OCGS text says | Use in Claude Code |
|---|---|
| `question` tool | `AskUserQuestion` |
| `Task` tool / delegate to an agent | `Agent` tool, `subagent_type` = the OCGS agent name (e.g. `technical-director`) |
| `/help` | `/ocgs-help` (Claude Code's built-in `/help` takes the name) |
| `/code-review` | `/ocgs-code-review` (a built-in or personal `/code-review` takes the name) |
| `.opencode/agents`, `.opencode/skills`, … | the same path under `.agents/` |
| an "OpenCode session" | this Claude Code session |

The mirror already renames the `/help` and `/code-review` references and the `allowed-tools` names inside mirrored files. Skill bodies and other docs (e.g. `docs/framework/workflow-catalog.yaml`) still use the OCGS names.

- **Choices:** `AskUserQuestion` takes up to 4 questions with 2–4 options each, and adds "Other" itself. When an OCGS skill lists more choices, split them across questions or group them.
- **Skill `agent:` field:** it names the OCGS agent that owns the skill. Claude Code runs the skill in this session, so its interactive steps still work; follow that agent's guidance, and delegate to it with the `Agent` tool where the skill says to.

## Hooks

`.claude/settings.json` runs `.claude/hooks/ocgs-hooks.mjs`, which reuses `.opencode/plugins/ccgs-hooks.ts` (needs `npm install` for tsx). It adds session context at start, keeps `production/session-state/active.md` in the compaction summary, blocks commits that fail OCGS validation (invalid `assets/data/*.json`), warns on protected-branch pushes and asset naming, and flags edits to generated `.claude/` files.

The commit check reads what is staged when the command starts. Stage files in a separate command before running `git commit`, rather than `git add x && git commit`.
