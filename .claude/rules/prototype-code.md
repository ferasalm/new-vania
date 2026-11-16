---
paths:
  - "prototypes/**"
---

# Prototype Code Standards (Relaxed)

Prototypes are throwaway code for validating ideas. Standards are intentionally
relaxed to maximize iteration speed. The goal is learning, not production quality.

## What's Allowed in Prototypes
- Hardcoded values (no need for data-driven config)
- Minimal or no doc comments
- Simple architecture (no dependency injection required)
- Singletons and global state
- Copy-pasted code (no need for abstraction)
- Debug output left in place
- Placeholder art and audio
- Quick-and-dirty solutions

## What's Still Required
- Each prototype lives in its own subdirectory: `prototypes/[name]/`
- Every prototype MUST have a `README.md` with:
  - What hypothesis is being tested
  - How to run the prototype
  - Current status (in-progress / concluded)
  - Findings (updated when prototype concludes)
- Every playable prototype MUST be tunable by the user while playing (see "Tuning panel" below)
- No production code may reference or import from `prototypes/`
- Prototypes must not modify files outside `prototypes/`
- Prototypes must not be deployed or shipped

## Tuning panel (required for playable prototypes)

The user judges feel by playing, not by reading numbers. So:

- Every number that changes how the game feels (speeds, heights, timings, damage, volumes)
  lives in one file, `tuning.json`, never in the code. Each entry has `value`, `min`, `max`,
  `step`, a plain-words `label`, and a one-sentence `help` a non-developer can understand.
- Pressing `F1` in the game opens sliders for every entry. A change applies at once, while
  the game keeps running. `Save` writes `tuning.json`; `Reset` returns to the saved values.
- Choices that cannot be a number (which sound, which music) get a "previous / next" picker
  in the same panel, saved the same way.
- Before the user plays, commit the prototype including `tuning.json` and the saved choice
  files, so the diff after play shows only the user's changes (`git diff` does not show
  untracked files). After the user plays, run `git diff` on those files and copy the changed
  values into `production/playtests/VERDICTS.md` with a plain-words meaning for each. Then
  commit `tuning.json`, the saved choice files and `VERDICTS.md` together. Never overwrite
  values the user saved.
- Copy the working example instead of writing a new one: `prototypes/feel-v3/tuning.gd`,
  `tuning_panel.gd` and `tuning.json`.

## When a Prototype Succeeds
If a prototype validates a concept and the feature moves to production:
1. The prototype code is NOT migrated directly — it is rewritten to production standards
2. The prototype `README.md` findings inform the production design document
3. The prototype directory is preserved for reference but never extended

## Cleanup
Concluded prototypes should be archived or deleted after findings are captured.
Never let prototype code grow into production code through incremental "cleanup."

## Anti-Patterns

- Prototype code that "just needs a little cleanup" to become production — always rewrite from scratch
- Prototypes that grow beyond their timebox (set a hard deadline before starting)
- No README.md for a prototype (findings are lost when memory fades)
- Prototype code that accidentally ships (ensure build pipelines exclude `prototypes/`)
- Prototype code referenced by production code (breaks the isolation boundary)
- Spending time on polish during a prototype (if it needs polish, it needs a production pass)

## Cross-References

- Agent: `prototyper` — runs prototype workflow
- Agent: `creative-director` — approves proceed/pivot/kill decisions
- Skill: `prototype` — rapid prototyping workflow
- Skill: `hybrid-prototype` — discovery-phase prototyping
- Skill: `reverse-document` — captures findings after a successful prototype
