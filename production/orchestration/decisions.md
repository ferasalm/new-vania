# Decisions — the batched user-decision queue

> **Rule**: the orchestrator stops and asks the user **only** for a hard blocker,
> a contract revision, an art-bible direction decision, or a required-review
> refusal on a future lane PR. Everything else is batched here and presented at
> the next natural boundary. Do not interrupt for soft blockers.

## Open decisions

### D-ORCH-01 — SYS-11 OQ-1: the purple bridge vs the liminal-grey reservation

- **Lane**: ART-BIBLE (first item).
- **Question**: does the purple bridge become an art-bible-ratified gated tint, or
  does SYS-02's Player Fantasy line 36 get amended and the SYS-11 index row
  qualified?
- **The conflict**: SYS-02's Player Fantasy "Anchor moment — The Wrong Corridor"
  says: *"Beyond it a corridor the color of neither truth — the grey of a place
  between places, a purple bridge holding it together — and the last memory at its
  end."* SYS-09's TR-DR-002 reserves liminal space for greys; SYS-11's OQ-1 and
  TR-DR-012 make the purple a **gated proposal** with the P1–P5+G admission test.
- **Options**:
  - **A. Ratify the purple** as a low-saturation depth tint over the
    `PROV_LIM_*` ramp, only in the wing frame's W/E columns, never the threshold
    band, north row, fill, fixtures, or M4. The P1–P5+G admission test must pass.
  - **B. Amend SYS-02 line 36** ("a purple bridge holding it together" → the
    grey bridge / the bridge of neither truth) and qualify the SYS-11 index row
    (the OQ-M1 rider pattern). The grey `PROV_LIM_*` default ships either way.
- **Recommendation**: **B** is the lower-risk default: the grey ramp already
  ships, the liminal-grey reservation is a load-bearing color-philosophy rule,
  and the purple can still be revisited at the asset-spec pass. **A** is viable
  only if the art-director's admission test passes and the user wants the
  corridor's one chromatic signature.
- **Blocking?** The art bible's first item; the grey default ships either way, so
  it does not block SYS-11's implementation.
- **Status**: **OPEN** — the ART-BIBLE lane prepares the decision package.
- **Decision**: _pending_.

### D-ORCH-02 — SYS-11 OQ-4: the `PROV_LIM_*` L gaps + the grief pins

- **Lane**: ART-BIBLE.
- **Question**: approve the four `PROV_LIM_*` L values (with `gap_R ≥ 0.09`), the
  grief tint's C/L, and the grief hue band [330, 20]; or relax the D-gap clause to
  ≥ 0.01; or close the tint.
- **Blocking?** The art bible's palette section; not SYS-11's implementation.
- **Status**: **OPEN** — the ART-BIBLE lane prepares the values.
- **Decision**: _pending_.

### D-ORCH-03 — SYS-07-REWORK: the IP-17 baseline contract revision

- **Lane**: SYS-07-REWORK.
- **Question**: approve the low-stat baseline rework package (the reworked
  baseline numbers, the level 1–5 curve, the `TR-HD-006` "MVP has no gear" clause
  correction, the mana reconciliation input, and the ±10% parity situational-break
  OQ) as a contract revision to the frozen SYS-07 GDD.
- **Why it is a decision**: SYS-07 is an APPROVED, frozen contract. The rework is
  a revision, not a silent edit.
- **Blocking?** SYS-16 and SYS-17 are blocked until it lands.
- **Status**: **OPEN** — the lane prepares the package; do not edit the GDD until
  approved.
- **Decision**: _pending_.

## Resolved decisions (this era)

| ID | Lane | Decision | Date | Record |
|---|---|---|---|---|
| — | — | — | — | — |

## Standing authorizations

- **Admin-merge pre-authorization** (future lane PRs): if the ONLY blocker is the
  required review (0 unresolved threads, all required checks green), the user
  pre-authorizes **one** `gh pr merge --squash --delete-branch --admin` per lane
  PR. Record the bypass in the landing receipt. Any other blocker is diagnosed,
  not bypassed.
- **Checkpoint commits**: the user pre-authorizes small conventional checkpoint
  commits + pushes within a lane branch. No commits on `Main`; no force-push.
- **Batched cadence**: one CodeRabbit pass per landed milestone; triage in one
  batch; one fix commit; resolve threads manually; a confirm pass only for a
  Major-class fix batch.

## How to add a decision

1. Add the ID (`D-ORCH-NN`), the lane, the question, the options, the
   recommendation, the blocking status, and the owner.
2. Do **not** interrupt the user for it; batch it.
3. When the user decides, move the row to "Resolved decisions" with the date and
   the record path; update the lane's manifest `next_action`.
4. A contract revision is never applied before the decision is recorded here.
