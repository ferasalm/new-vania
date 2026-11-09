---
name: ocgs-on-hermes
description: Translate OCGS framework instructions (question tool, Task delegation, .opencode paths, /help) into Hermes tools. Use when a task or skill text written for OpenCode or Claude Code is run in Hermes inside this project.
---

# OCGS on Hermes

`AGENTS.md` is the project guide. `.agents/{agents,skills,rules}` is the canonical OCGS content.
OCGS text is written for OpenCode; in Hermes read it with this table.

| OCGS text says | Use in Hermes |
|---|---|
| `question` tool | `clarify` (one question, optional choices; add "Other" yourself) |
| `Task` tool / delegate to an agent | `delegate_task`. The OCGS agent file is `.agents/agents/<name>.md`: read it and pass its body as the subagent's instructions |
| `.opencode/agents`, `.opencode/skills`, `.opencode/rules`, `.opencode/commands` | the same path under `.agents/` |
| `/help` | the project's help skill (`.agents/skills/help`) |
| `/code-review` | `.agents/skills/code-review` |
| an "OpenCode session" | this Hermes session |

## Rules that still apply

- Never add `.hermes.md` to the repo: it would hide `AGENTS.md` from Hermes.
- Do not touch the `.opencode/*` link files, and do not edit `.claude/{agents,skills,rules}` (generated mirror).
- No commits to `Main`; one worktree per topic; no `reset --hard`, `clean` or force-push.
- Ask before writing files (AGENTS.md collaboration protocol), once per changeset.
- Skills load from `.agents/skills` only if this project root is trusted (`hermes skills trust <path>`).
