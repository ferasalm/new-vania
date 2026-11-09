---
name: ocgs-on-hermes
description: Translate OCGS framework instructions (question tool, Task delegation, .opencode paths) into Hermes tools. Use when a task or skill text written for OpenCode or Claude Code is run in Hermes inside this project.
---

# OCGS on Hermes

`AGENTS.md` is the project guide. `.agents/{agents,skills,rules}` is the canonical OCGS content.
OCGS text is written for OpenCode; in Hermes read it with this table.

| OCGS text says | Use in Hermes |
|---|---|
| `question` tool | `clarify`: up to 4 choices, and it appends "Other" itself (do not add one). If the skill lists more than 4, group them or split them across several `clarify` calls |
| `Task` tool / delegate to an agent | `delegate_task`. The OCGS agent file is `.agents/agents/<name>.md`: read it and pass its body as the subagent's instructions. Subagents are leaf workers by default and cannot delegate further: when an agent file says to delegate (e.g. `lead-programmer` to specialists), you, the parent, run each specialist as its own `delegate_task` and pass results between them. Subagents also cannot call `clarify`, so they cannot ask the user for approval: have the child return its questions and draft, ask the user yourself (`clarify`) for the affected files, then start a second `delegate_task` (a fresh conversation) that carries the task, the agent instructions, the approved draft, the affected paths and the user's decision, before the child writes anything |
| `.opencode/agents`, `.opencode/skills`, `.opencode/rules`, `.opencode/commands` | the same path under `.agents/` |
| `/help` | `/skill help` (Hermes's own `/help` is built in and only lists commands) |
| `/code-review` | `.agents/skills/code-review` |
| an "OpenCode session" | this Hermes session |

## Rules that still apply

- Never add `.hermes.md` to the repo: it would hide `AGENTS.md` from Hermes.
- Do not touch the `.opencode/*` link files, and do not edit `.claude/{agents,skills,rules}` (generated mirror).
- No commits to `Main`; one worktree per topic; no `reset --hard`, `clean` or force-push.
- Ask before writing files (AGENTS.md collaboration protocol), once per changeset.
- Skills load from `.agents/skills` only if this project root is trusted (`hermes skills trust <path>`).
