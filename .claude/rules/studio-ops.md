# Studio ops (Claude Code)

Hand-written. Not part of the `.agents/` mirror; `npm run claude:sync` leaves it alone.
Keep it short: it is loaded in every session.

## Session start

- Read the hook context and `production/session-state/active.md`, then give a one-line status.
- Status words, always: **done | in progress | planned | not planned | waiting on user**.

## Reading

- Grep first, then at most 2 targeted excerpts. Never read whole big files or binaries.
- Wide sweeps go to `Explore` or a Haiku subagent; only the conclusion comes back.

## Routing

- Opus plans and reviews. Sonnet executes from a written brief. Haiku reads and searches.
  Set `model` on every `Agent` call.
- Hermes is an optional builder: `hermes chat -Q --oneshot` (see `setup/HARNESS-MAP.md`).
  Limit it with `-t` toolsets or the Docker backend, never with prompt text.

## Gates

- **G1** read-only sweep before writing.
- **G2** the user reviews before any merge.
- **G3** host config, Task Scheduler and anything outside the workspace need approval first.
- Paid generation tools (`ask` rule in `settings.json`) always need a yes.

## Git

- Never commit to `Main`. One worktree per task: `git worktree add ../<repo>-<topic> -b <type>/<topic>` (forward slashes work in Git Bash, PowerShell and cmd).
  Preferred: `npm run task:new -- <type>/<topic>` (fetches, then branches from `origin/Main`). The pre-commit hook blocks commits on `Main` and on branches that predate the generated `.opencode` links.
- WIP commits, never a bare stash. No `reset --hard`, `clean` or force-push.
- Move aside, never delete. Back up a config file before editing it.
- Review = PR + CodeRabbit governor (at most 2 rounds, then ask). Backup tag before every merge.
- The user removes worktrees and branches.
- Stage in a separate command before `git commit` (the commit gate reads the index at start).

## Failure

- Two failures in a row on the same step: stop and ask, with a recommended option first.

## Context hygiene

- Update `active.md` at milestones. One task per chat.
- Hand off when the task is done or at about 85% of the window.

## Multi-harness

- `.agents/` is canonical; run `npm run claude:sync` after editing it. Never edit `.claude/{agents,skills}`.
- From a repo task, never edit `opencode.json`, `.opencode/*`, `.pi`, `.omp` or Hermes config.
  Never add `.hermes.md` (it hides `AGENTS.md` from Hermes).
- When a harness breaks: read `HARNESS-MAP.md` and run `scripts/harness-status.ps1` from the `setup` repo
  (`ferasalm/setup`, checked out as `workspace/setup` beside this repo; it is not part of this checkout).

## Collaboration

- Keep the `AGENTS.md` protocol (Question, Options, Decision, Draft, Approval). For several files, ask one
  `May I write this to <path>?` question that lists every path; one approval covers that whole changeset.
