# Skill Test Spec: agents-orchestrator (agency persona)

## Skill Summary

`agents-orchestrator` is an orchestration persona skill without a slash-command surface. It coordinates the engineering workflow via nested subagents (builders, reviewers) and produces build plans, routing ledgers, and final reports.

## Static Expectations

- Frontmatter: `name`, `description`, `user-invocable: true`, `allowed-tools` (present).
- Workflow phasing present (Step 1-4 structure).

## Notes

Cataloged 2026-11-07 to satisfy invariant I10 when the agency skill pack landed (PRs #3/#4). Behavioral
spec/category coverage intentionally deferred until the persona pack gets behavioral tests.
