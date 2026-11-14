# GDD Pre-Flight Validator — Ticket Spec

> **Status**: **PROPOSED — filed, not implemented** (filing is not authorization — see *Out of scope / sequencing*)
> **Ticket ID**: `GDD-PREFLIGHT-01` · **Date**: 2026-11-14
> **Owners**: `tools-programmer` (implementation) + `devops-engineer` (CI wiring)
> **Source**: benchmark-audit process levers **1 + 8** (PR #38) — named as this ticket at
> `production/review-doctrine/2026-11-14-right-sizing-review-scope.md` L4; sprint row **S1-006**
> in `production/sprints/sprint-01-2026-11-16.md` (0.5 d spec = this file)
> **Governing docs**: `design/reviews/metroidvania-benchmark-audit.md` § 5a (D-1…D-8), § 5 **RJ-6**,
> § 4 **IP-12**, § 3 **C-1**; `docs/framework/director-gates.md` § *Review Modes* (L26–63)

> **Guardrail (RJ-6, non-negotiable): "Right-size review scope, never skip seats."**
> The validator automates **mechanical** checks only. It never replaces the three review seats
> (creative / technical / QA) or the mandatory qa-lead spot-checks. A green run is not a review —
> it is the absence of a defect class a human should not have had to find.

---

## Problem statement

The corpus's review rounds keep spending seat time on defects that are mechanically detectable:
citations that resolve to nothing (or to the wrong ID), ledger sums that do not add, and index rows
that drift from the GDD bodies. Each one is found by a human, consumes a round, and — for the ledger
— is re-derived by hand more than once.

Verified evidence (file:line, read 2026-11-14 on `docs/review-levers`):

- **The same ledger was re-derived by hand four times.** `design/gdd/systems-index.md` Progress
  Tracker **SYS-01** row: "QA plan's 96-unit ledger printed at 96 = 67+19+3+7" and "the gate manifest
  and its mini-proof re-derived TOGETHER at 96 clause-units = 67 smoke + 19 device + 3 lock + 7 VS".
  `design/gdd/reviews/input-control-mapping-review-log.md` § *The 96-unit ledger — the
  manifest↔proof TOGETHER record* (L534) and L551: "the **FOURTH** deterministic derivation on
  record (#7, #8's qa-lead, the repair mini-proof, this one)".
- **A machine audit was already mandated by hand.** `input-control-mapping-review-log.md` L386 names
  "**The machine cross-reference membership audit (NEW MANDATORY ARTIFACT)** … enumerate every
  'consumed by / gated by / meets / rides / applies to / excluded / device-executed' claim … the
  cross-reference surface (79 ACs, ~50 membership claims) has outgrown per-fix human sweeps." Its
  artifact is a 47-row inventory, 35 PASS / 10 PASS(post) / 2 ADJ (L552). This ticket productizes
  exactly that check.
- **Arithmetic defects survive a PASS.** `design/gdd/reviews/combat-review-log.md` L79: the
  diff-scoped re-review returned "5 blockers (2 regressions … , **3 arithmetic/range defects**)";
  L106: the qa-lead spot-check still had to recompute "6/6 arithmetic fixtures … gate manifest
  39 + 4 + 5 + 0 = 48 with exactly-one membership". L185: the post-review CodeRabbit pass found
  4 + 6 + 3 = 13 findings (1 refuted). `systems-index.md` **SYS-08** row records "the post-review
  CodeRabbit pass found 4 more … all repaired".
- **Spot-checks keep failing on fixture/arithmetic defects.** `systems-index.md` Progress Tracker:
  **SYS-02** "qa-lead spot-check FAIL at 9 defects"; **SYS-13** "FAIL at 4 blockers"; **SYS-29**
  "FAIL at 1 blocking fixture defect + 5 repairs"; **SYS-32** "FAIL at 1 map defect → repaired →
  PASS; the diff-scoped re-verification rounds 1–3".
- **Citation-membership defects are real and cheap to catch.** Audit § 3 **C-1** (L131): Gemini cited
  `V-RWS-04` for `cells_discovered`; `V-RWS-04` is the one-room-one-cell law
  (`design/gdd/room-world-structure.md` L334) and the source family is `TR-RWS-025`. A resolver
  answers this without a seat.
- **The input shape varies — the validator must not assume.** 6 of 8 GDD bodies carry a canonical
  `### Gate manifest` table with a printed `a + b + c + d = N` (camera L545/555, combat L565/575,
  enemy L494/504, health L596/606, juice L511/521, room L483/493). `movement.md` has **no** manifest;
  `input-control-mapping.md`'s manifest is prose (the *Smoke gate* paragraph, ~L921) and prints no
  partition — its 96-unit ledger lives in the review log, the QA plan, and the index row.

**Cost being removed:** the mechanical share of each review round — citation sweeps, ledger
re-derivations, spot-check arithmetic — plus the four hand derivations of one partition.

---

## Scope — four functional areas

### Area 1 — Citation membership

- **Checks**: every ID token in a GDD body of the families `TR-/F-/V-/AC-/OQ-/PR-` resolves in its
  **owning** file; audit vocabularies (`GA-/IP-/RJ-/C-/D-`) resolve in
  `design/reviews/metroidvania-benchmark-audit.md`; review-log-local families (`NB-A…K`, `Q#`, `R#`,
  `N#`, `T#`, `O1`, `B-1`) resolve only inside their own log. Follows the SYS-01 audit pattern.
- **Inputs**: the 8 GDD bodies; `design/gdd/systems-index.md` (prefix→file map from the Progress
  Tracker `GDD path` column, header L146); `design/registry/entities.yaml` (facts keyed by `name:`,
  with `source`/`referenced_by` and TR mentions in `notes`/`values`); the 8 files in
  `design/gdd/reviews/`; the audit file.
- **Resolution order**: owning GDD body → systems index → `design/registry/entities.yaml` → the named
  review log. `docs/architecture/tr-registry.yaml` is a documented but **empty** stub
  (`requirements: []`, L30) and cannot resolve anything today; it becomes the primary index when
  `/architecture-review` populates it (v2 hook).
- **Failure output**: `design/gdd/combat.md:412 → TR-MOV-077 unresolved (owner: design/gdd/movement.md;
  also absent from systems-index, registry)`. Warnings (non-blocking): IDs declared but never cited.
- **Grammar notes the config table must carry** (derived from the corpus, not from the template):
  8 TR prefixes (`CAM, CMB, ENM, HD, INP, JCE, MOV, RWS`); 7 F/V/AC prefixes with **no `-INP`
  variant**; `OQ-` only `CAM/ENM/RWS`; `PR-` only `CAM` (probes `PR-CAM-01…08`).
  `input-control-mapping.md` uses **bare** IDs (`AC-01…79`, `F-01…F-10`, `V14`/`V15`/`V20`/`V21`),
  and other GDDs cross-cite them as "SYS-01 AC-63" (e.g. `combat.md` L573) — so bare `AC-nn`
  resolves to SYS-01's namespace, never locally. `docs/architecture/tr-registry.yaml` documents
  `TR-[system-slug]-[NNN]`; the corpus uses 2–4-letter area codes — the template's grammar is wrong
  for this repo and must not be copied.

### Area 2 — AC→gate ledger arithmetic

- **Checks**, wherever a partition is printed:
  (a) the four `Units` cells sum to the `Total` cell **and** to the printed expression in the same
  row; (b) each row's AC enumeration expands to exactly its `Units` cell, and the union is
  exactly-once over the declared AC range; (c) header↔manifest agreement where a `**Counts**` header
  exists (`health-damage.md` L10 vs L606, both `42 + 3 + 5 + 0 = 50`); (d) index↔GDD agreement where
  an index row prints a partition (SYS-01 L148 `96 = 67+19+3+7`; SYS-02 L149 `29+3+2+0 = 34`;
  SYS-13 L160 `29+3+4+0 = 36`; SYS-29 L176 `35+5+6+0 = 46`; SYS-32 L179 `28+3+6+0 = 37`).
- **Inputs**: the 6 canonical manifests above; `systems-index.md` Progress Tracker; the `Counts`
  header where present.
- **Failure output**: `design/gdd/combat.md:575 → Total says 48, Units sum = 49 (39 + 4 + 5 + 1)`;
  `systems-index.md:160 → 29+3+4+0 = 36 but enemy-ai-telegraphs.md:504 prints 29+3+4+0 = 36 [OK]`
  for the drift case; `health-damage.md:10 → header 50 ACs, manifest total 50, enumeration 48`.
- **SKIP-with-reason, never silent**: `movement.md` (no manifest) and `input-control-mapping.md`
  (prose manifest, no printed partition) are listed in the report as `SKIP — no canonical manifest`,
  with the reason. SYS-01's 96-unit species is covered only via its index row (d).

### Area 3 — Cross-ref drift

- **Checks**: (a) dependency sets — the GDD `## Dependencies` section (present in all 8 bodies:
  camera L419, combat L364, enemy L330, health L417, input L573, juice L347, movement L571,
  room L349) vs the index *System Enumeration* `Dependencies` column vs the index prose
  "depends on" line; (b) status sync — GDD `**Status**` header vs the Progress Tracker `GDD status`
  cell vs `design/registry/entities.yaml` `status` for facts whose `source` is that GDD;
  (c) rider states — each index rider tagged "recorded" must name a target symbol and its
  landed/not-landed state, and the validator asserts the symbol's presence in the target body
  matches (verified example: SYS-06 row L153 "SYS-32's TR-MOV-028 `position` rider recorded
  2026-11-14" while `movement.md` L95 publishes velocity/grounded/facing/wall-state/body_busy and
  not the body-center `position` field).
- **Inputs**: the 8 GDD bodies; `systems-index.md` (both tables + prose); `design/registry/entities.yaml`.
- **Failure output**: `systems-index.md:62 → SYS-08 depends on SYS-13, absent from combat.md
  § Dependencies (L364)`; `movement.md § Status APPROVED vs systems-index.md:153 APPROVED [OK]`.

### Area 4 — CI fold-in

- **Verified environment (corrects the filing brief).** `.github/workflows/` **exists** here:
  `test.yml`, `agent-validation.yml`, `stale.yml`. `agent-validation.yml` runs
  `node tests/agents/validate.mjs` on push/PR to `Main`/`development` (Node 20). The local mirror is
  therefore not "the only CI" — it is the developer-side fast path whose README promises parity with
  those workflows (`tools/ci/README.md`, parity table L6–10). A mirror-only job would break that
  promise, so the fold-in has two halves.
- **Mirror half**: a `gdd` entry in the `JOBS` map of `tools/ci/run-local.mjs` (L29–78), step
  `node tests/gdd/validate-gdd.mjs`; reachable as `npm run ci -- --job gdd` and included in `all`
  (the `ALL_STEPS` dedupe at L81–84 already handles shared steps).
- **Workflow half**: a `validate-gdd` job in `.github/workflows/agent-validation.yml`, mirroring the
  `validate-agents` job's shape (checkout, Node 20, run, `if: always()` report upload).
- **Optional hook half**: `tools/git-hooks/pre-commit.mjs` already computes gates from staged paths
  (L343–354) and runs `tests/agents/validate.mjs --no-report` for the `framework` gate (L428). Add a
  `gdd` gate for staged `design/gdd/**` + `design/registry/**`, invoked with `--no-report` — hooks
  must not mutate the work tree, which is why `--no-report` exists in `tests/agents/validate.mjs`
  (L513–518) — and honour the existing `OCGS_SKIP_HOOK_CHECKS=1` escape (L20).

---

## Non-goals

- **No GDD body edits, no auto-fix.** The tool is read-only outside its own report path.
- **No semantic, feel, or design-quality review.** The seats stay; so do the mandatory qa-lead
  spot-checks on repaired text.
- **Does not re-open closed review loops** (SYS-01 capped at #10; SYS-06/SYS-08 loops closed).
- **No new ID authority.** The validator never mints, renumbers, or deprecates IDs; it only resolves.
- **Not a merge gate on content.** A FAIL means "mechanically inconsistent", never "bad design".

---

## Proposed shape

`tests/gdd/validate-gdd.mjs` — single dependency-free ESM `.mjs`, Node 20, following
`tests/agents/validate.mjs`: a config block, one function per area, `generateReport(sections)`,
`main()`. Report to `tests/gdd/validation-report.md` with per-area PASS/FAIL, failures-only detail,
an overall `| Category | Passed | Failed | Total |` table, a Verdict and a Coverage line. Add the
report path to `.gitignore` beside `tests/agents/validation-report.md` (L43). Flags: `--no-report`,
`--area <name>` (fast local loop), `--strict` (warnings fail).

The ID grammar lives in **one** table (a `tests/gdd/id-grammar.json` or the config block): prefix →
family → owner file → shape → bare-ID exception. Unknown prefixes are warnings by default and
failures under `--strict` — new families must be added deliberately, not absorbed by a loose regex.

Fixtures live in `tests/gdd/fixtures/` as deliberately broken copies; the validator never runs
against mutated live files.

**Acceptance criteria**

1. **AC-1 (seeded defect, area 1)** — renaming `TR-CMB-007` in a fixture makes the run FAIL, naming
   `file:line`, the ID, and the expected owner; the unmodified fixture passes.
2. **AC-2 (seeded defect, area 2)** — changing one `Units` cell, one printed expression, or one
   header count in a fixture each produces a distinct FAIL carrying the arithmetic trace.
3. **AC-3 (seeded defect, area 3)** — dropping `SYS-13` from a fixture's `## Dependencies` (or
   flipping a rider's landed state) FAILs with both sides of the comparison printed.
4. **AC-4 (zero false positives)** — on the current corpus the run is PASS with zero findings.
   A finding here is a validator bug, not a corpus bug; suppress with a reasoned allowlist entry
   (house precedent: `AGENT_EXCEPTIONS`, `tests/agents/validate.mjs` L33–36) and a named owner.
5. **AC-5 (runtime budget)** — full sweep (10 files ≈ 3,600 lines + the 890-line registry) under
   **60 s hard ceiling**, target < 5 s; the measured time is printed in the report.
6. **AC-6 (report + exit codes)** — report written unless `--no-report`; exit `0` on pass, `1` on
   fail, `2` on bad arguments (mirrors `tools/ci/run-local.mjs`).
7. **AC-7 (read-only)** — a test hashes every GDD, the index, and the registry before/after a run and
   asserts no change (the non-goal made testable).
8. **AC-8 (CI wired)** — `npm run ci -- --job gdd` runs the validator; the workflow job exists; the
   pre-commit gate fires on a staged `design/gdd/**.md` change and skips with
   `OCGS_SKIP_HOOK_CHECKS=1`.
9. **AC-9 (guardrail documented)** — the validator's report header and its README print
   **"Right-size review scope, never skip seats."** plus one sentence: mechanical checks only, the
   three seats and qa-lead spot-checks are unchanged.

---

## Risks & mitigations

| Risk | Why it is real (verified) | Mitigation |
|---|---|---|
| Table-format variance across GDDs | 6 canonical manifests, 1 prose manifest (`input-control-mapping.md`), 1 absent (`movement.md`) | Ship areas 1 + 2 first (both grep/table-shaped); SKIP-with-reason for non-canonical bodies; defer area 3 to a second pass |
| ID-grammar drift | Corpus uses area codes (`TR-RWS-`), bare IDs (`AC-01`, `V14`), and the template documents `TR-[system-slug]-[NNN]` (`tr-registry.yaml` L21) | One config table, no scattered regexes; unknown prefix = warning; `--strict` opt-in |
| Review-log prose noise | Log-local families collide across logs (`Q#`/`R#`/`N#`/`T#` in all 8; `NB-A…K`, `O1`, `B-1` only in SYS-01's) | v1 resolves review-log IDs **only** inside their own log; logs are not citation sources |
| `PR-` prefix collision | `PR-CAM-01…08` probes vs `PR-SCOPE`/`PR-SPRINT`/`PR-MILESTONE` producer gates (`docs/framework/director-gates.md` L419+) | Never scan `docs/framework/`; scope inputs to `design/gdd/**`, `design/registry/**`, `design/reviews/**` |
| False-positive pressure from an APPROVED corpus | All 8 bodies are APPROVED/UNFROZEN with closed loops; a noisy tool gets disabled | AC-4 is a hard gate; reasoned allowlist with owner; findings must name `file:line` and the expected value |
| The tool becomes an excuse to skip seats | RJ-6 exists precisely because "lean" was proposed once | Guardrail in the report header (AC-9); non-goals restated in the README; no `--skip-review` style flag ever |

---

## Estimate

| Work item | Days | Owner |
|---|---|---|
| Grammar config + area 1 (citation membership) + fixtures | 2.0 | tools-programmer |
| Area 2 (ledger arithmetic) + fixtures | 1.5 | tools-programmer |
| Area 3 (drift) + fixtures | 1.0 | tools-programmer |
| Area 4 (mirror job + workflow job + pre-commit gate) | 0.5 | devops-engineer |
| Report/exit-code/read-only tests, README | 0.5 | tools-programmer |
| **Total** | **5.5 dev-days** | one calendar week with pairing |

Suggested pairing: tools-programmer implements and owns the grammar table; devops-engineer wires the
mirror, the workflow, and the hook, and validates `npm run ci -- --job gdd` on a clean checkout.
The 0.5 d spec is already spent (S1-006).

---

## Out of scope / sequencing

- **Filing is not authorization.** Implementation enters a **future sprint's planning**; the producer
  admits it (S1-006's acceptance line: "producer admits the implementation into the *next* sprint
  plan").
- **Do not schedule against MVP authoring weeks 1–2.** Sprint 1's protected gates are the shift-shader
  experiment and the MetSys smoke gate AC-RWS-28, both week 1
  (`production/sprints/sprint-01-2026-11-16.md` L59–63); S1-006 explicitly schedules "nothing else
  against MVP weeks 1–2 for it".
- **Best natural slot**: alongside the second authoring wave, once 2+ new GDDs exist to test against
  (the corpus is 8 bodies today; SYS-09/10/15/28/04 are in flight), or immediately before SYS-16/17
  authoring so the gear GDDs land pre-flighted.
- **v2 backlog (not this ticket)**: populate-and-consume `docs/architecture/tr-registry.yaml`;
  review-log arithmetic (the 96-unit species where it is printed in logs); a rider registry to make
  area 3(c) table-driven; `--fix` is **not** on any roadmap.

---

**Evidence verification**: every path, line, row name, and arithmetic expression above was read on
2026-11-14 from branch `docs/review-levers` before this ticket was written. The one premise corrected
in flight is Area 4's: `.github/workflows/` exists in this instance, so the fold-in covers the mirror
**and** the workflow.
