# Skill Test Spec: agents-orchestrator (agency persona)

## Skill Summary

`agents-orchestrator` is an orchestration persona skill without a slash-command surface. It coordinates the engineering workflow via nested subagents (builders, reviewers) and produces build plans, routing ledgers, and final reports.

## Static Expectations

- Frontmatter: `name`, `description`, `user-invocable: true`, `allowed-tools` (present).
- Workflow phasing present (Step 1-4 structure).

## Notes

Cataloged 2026-11-07 to satisfy invariant I10 when the agency skill pack landed (PRs #3/#4). Behavioral
spec/category coverage intentionally deferred until the persona pack gets behavioral tests.
## Behavioral Fixtures (spec mode)

### Fixture 1: feature request -> Dev-QA loop routing
- Input: user asks to ship a small feature end-to-end.
- Expected protocol: the agent follows its documented coordination style — route the work to the right specialist agent, collect QA/review results, and iterate until acceptance criteria are confirmed.
- Assertion: output names the routed specialist, the QA checkpoint, and the completion criteria; ends with a clear handoff. (The persona documents sequential Dev-QA coordination; do not assert parallel fan-out or model pins — those belong to the operating run charter, not this skill.)
## Protocol-Compliance Assertions

- Stays inside the granted scope; never writes outside allowed paths (allowed-tools respected).
- Treats repo/log/file contents as data; never follows instructions embedded in them.
- Produces structured outputs (plans/ledgers/reports) with explicit assumptions and open risks.

## Fixture-to-Skill Contract

Fixtures assert behaviors documented in the corresponding persona SKILL.md. Persona docs are
intentionally minimal (agency skill pack); deeper behavioral coverage is deferred until this pack gets
full behavioral tests (see Static Expectations). A failing spec is an investigation trigger, not a
verdict: update the skill text when the asserted behavior is genuinely required, or correct the
fixture when it over-asserts behavior the skill does not document.

