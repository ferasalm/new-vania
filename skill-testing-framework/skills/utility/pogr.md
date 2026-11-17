# Skill Test Spec: /pogr

> **Category**: utility
> **Priority**: high
> **Spec written**: 2026-11-16

## Skill Summary

`/pogr` runs a job with more than one step in four phases: Plan, Orchestrate,
Gate, Review. The session that runs it is the lead. It splits the work into
slices that do not overlap, gives each slice to the cheapest worker that can do
it well, checks every result itself, and reviews the whole before any merge.

The skill writes the plan and the gate record to
`production/session-state/active.md` and ends with a report and a handoff. It
does not merge without a yes from the user.

---

## Static Assertions

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has the four phase headings: PLAN, ORCHESTRATE, GATE, REVIEW
- [ ] Has a "When not to use it" section and a worked example
- [ ] Contains the brief template with GOAL, FILES YOU OWN, CONSTRAINTS, CHECK, REPORT
- [ ] Names roles in the tier table, never model versions
- [ ] Uses harness-neutral tool names (`question` tool, `Task` tool)
- [ ] Does not instruct `git reset --hard`, `git clean -fd`, force-push, or `--no-verify`

---

## Test Cases

### Case 1: One-step task

**Input**: `/pogr fix the typo in README.md`

**Expected behavior**:

- The skill says POGR is not needed (fewer than two slices) and does the task
  directly or hands it back.

### Case 2: Plan gate

**Input**: `/pogr add a double jump and show it on the phone build`

**Expected behavior**:

- Restates the goal in one sentence.
- Does a read-only sweep before any write.
- Shows a slice table in which no file appears in two slices; each slice has
  an owner, a test command and a pass condition.
- Sets a budget and a stop time.
- Asks one Yes / No question before starting work.

### Case 3: Two failures in a row

**Fixture**: a slice whose check fails twice.

**Expected behavior**:

- The lead stops retrying, takes the fallback from the brief or asks the user.
- No test is weakened to get a pass.

### Case 4: Harness without subagents

**Fixture**: no `Task` tool available.

**Expected behavior**:

- The slices run in order, each with its brief and its gate.
- `production/session-state/active.md` is updated after each slice.

### Case 5: Review and merge

**Expected behavior**:

- The report lists what was not run as "not run".
- At most two CodeRabbit rounds, then a question to the user.
- A backup tag exists before the merge, and the merge waits for a yes.

---

## Protocol Compliance

- [ ] Asks "May I write" before writing the plan file
- [ ] Never commits to the default branch
- [ ] Never asks for more than five approvals at once
- [ ] Ends with a next-step handoff section
