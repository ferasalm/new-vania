# Review-Doctrine Change Proposal — Right-Sizing Review Scope (process levers 3 + 4)

> **Status**: ADOPTED WITH CONDITIONS 2026-11-14 — creative-director **CONCERNS (accepted; 3 clause conditions folded into § 1/§ 2, no re-circulation required)**, producer **CONCERNS (accepted; 7 conditions pre-registered in § 4 — non-blocking for the Sprint 1 batch, blocking for the SYS-16+17 batch)**. Both verdicts verbatim in § 5. Fold-in target: `docs/framework/director-gates.md` → *Review Modes* (first paragraph of the next framework-doc touch — mandatory, per the CD ruling). Pilot-evaluation entries ride the next retrospective.
> **Date**: 2026-11-14 · **Source**: the Metroidvania benchmark audit's process levers (PR #38, `design/reviews/metroidvania-benchmark-audit.md`) — the review-cost follow-up to IP-12 (authoring throughput). Levers 1+8 (the GDD pre-flight validator) are filed separately as `production/tickets/gdd-preflight-validator.md`; levers 5/6/2 land in `production/sprints/sprint-01-2026-11-16.md`.
> **Sign-off**: creative-director (the RJ-6 author seat — doctrine authority) + producer (calendar authority — IP-12's owner). **Both recorded below.**

---

## 1. What is proposed — two mechanisms, one framing

### Mechanism A — Batch co-review (lever 3)

**Pilot: SYS-09 + SYS-10 as ONE joint review surface.** One three-seat panel reviews both
documents together; one joint review log with per-document sections; one qa-lead spot-check
sweep across both diffs. Each GDD keeps its own header, AC manifest, and verdict — batching
merges the *review surface*, never the ownership or the depth.

- **Why this pair**: SYS-10 consumes SYS-09's contracts outright (systems index: SYS-10
  depends on SYS-09, SYS-03, SYS-02); SYS-02's GDD pre-shaped both documents together (the
  epoch/palette data model, the mutation registry, the flip's atomic application); and the
  benchmark audit's IP-2 obligation (the epistemic Epoch-0 tells, user decision D-6) spans
  **both** rows by design — the tells are SYS-09's render surface and SYS-10's clue surface.
- **The defect class it removes**: the cross-document contract boundary is where three-seat
  panels keep re-finding the same blockers one seat at a time (SYS-07↔SYS-08's lose-branch
  OQ#2/#3, SYS-08↔SYS-13's strike-contract reconciliation, SYS-32's consumer-side notes).
  One joint surface reads that boundary once, with both documents' authors present in the
  same round.
- **CD condition C3 (the joint log's ledger items)**: the joint log carries an explicit
  **cross-document verdict item for the IP-2/D-6 epistemic-tells obligation itself** (so the
  tells cannot fall between two per-document APPROVED verdicts), plus **SYS-03's five source
  families** and **SYS-04's IP-7 ambient-shift edge** entered as recorded contract items
  their final homes must land. Per-document seat verdicts and per-document qa-lead PASS
  lines are required — a joint PASS alone is not sign-off (producer condition 1).
- **Later batch (not this sprint)**: SYS-16 + SYS-17 — the same consume-chain shape (17
  depends on 16), and the gear layer is one design surface per user decision D-1. SYS-18
  joins only if it is actually in the same window (producer condition 7). Scheduled only
  after the pilot's evaluation (§ 4) — the producer's conditions are blocking for this
  batch.

### Mechanism B — Diff-scoped first-pass default for leaf nodes (lever 4)

**Applies to: SYS-25, SYS-27, SYS-30, SYS-31.** SYS-23 is **excluded** — permanently for
this pilot (CD ruling in § 5: unauthored upstream, empty consumed-contract surface,
creative-differentiator content class; revisit only via its own doctrine entry after
SYS-14's GDD exists and the pilot evaluation passes).

- **First-pass surface**: the authored sections + the arithmetic/AC fixtures + **every
  consumed contract at its source of record — including that contract's pending-obligation
  ledger** (CD condition C2) — **plus the document's published contracts** (producer
  condition 4: a leaf's outputs are someone's inputs; the SYS-25 → SYS-24 pause surface is
  the proof). Not the SYS-01 #8/#9 whole-document seven-seat adversarial pattern.
- **CD condition C2 (the pending-obligation ledger)**: every recorded-but-not-yet-landed
  rider on a consumed contract (the SYS-02 `wall_segment_id` pattern, SYS-32's TR-MOV-028
  `position` rider) is read into review, and the leaf is verified against the contract **as
  it will stand after those riders land** — approval against a stale contract view is void.
  Every leaf approval record carries an **obligations table** (obligation → landing venue →
  verification route → owning seat); the mandatory qa-lead spot-check verifies both repaired
  text and ledger completeness, and doubles as the tripwire for surface omission.
- **Soft 2-round cap with a hard carve-out (CD condition C1)**: the cap may convert only
  *editing-discipline and single-document residues* into recorded one-clause obligations
  (entered in the AC manifest, each with a named verification route). A finding on a pinned
  cross-boundary contract, an ADR, a registry entity, another GDD's body, or a
  doctrine-class falsification **never cap-converts** — it re-routes per the escalation
  clause. A rider on a dependency contract is never closed by the leaf's cap: it remains
  owned by its source document until it lands and is re-verified there.
- **Cap is soft by design**: the creative-director or qa-lead may extend rounds on
  doctrine-class findings. Extensions are quality-authority territory but they are **priced
  in calendar** — the cost is recorded and the producer names the row that slips (producer
  condition 5).

### The framing that keeps RJ-6 intact

> **"Right-size review scope, never skip seats."**

RJ-6 rejected *lean single-pass authoring* — skipping review depth where depth pays (the
catch-rate proof: 39 blockers on SYS-02, 25 on SYS-32, SYS-01's loop closed at 96 ledger
units). These mechanisms change **(a)** the surface each seat reads, **(b)** the round count
on low-risk nodes, **(c)** the number of surfaces on co-dependent pairs — the *calendar*
problem IP-12 named, never the *quality mode*. Every GDD still gets all three seats plus
mandatory qa-lead spot-checks on any repaired text.

---

## 2. What does NOT change

- **Full panels stay pinned for the named bottlenecks**: SYS-08 · SYS-02 · SYS-09 · SYS-10 ·
  SYS-03 — whole-document adversarial first-pass, fresh seats, the #8/#9 pattern. (SYS-09/10
  get the bottleneck depth *and* the batched surface — **bottleneck depth and the batched
  surface compose**; the batch merges the surface, not the depth — producer condition 7.)
- qa-lead spot-checks remain mandatory on any repaired text; review routing unchanged
  (creative → GLM-5.3-Flash; technical/QA → deepseek-v4.1-flash-1017).
- Escalation: any leaf-node finding that touches a pinned cross-boundary contract (a
  registry entity, an ADR, another system's GDD body) re-routes that finding to the
  bottleneck review mode for that touch — and per CD condition C1, such findings never
  cap-convert.
- Review-mode config (`production/review-mode.txt` = `full`) is untouched — this doctrine
  sits *inside* full mode, right-sizing surfaces, not gates.
- **Systems-index header: no line added.** The header already carries the audit pointer; a
  review-process change is not a scope decision, and a second header line would dilute the
  scope riders' visibility. **Upheld by the CD** (§ 5) — the compensation is that the
  `director-gates.md` fold-in becomes the *first paragraph* of the next framework touch,
  mandatory, not optional.

---

## 3. Why now (the evidence)

1. **IP-12's sharpened risk**: nine GDDs in the MVP window after user decisions D-1…D-6
   (SYS-12/16/17/25 joined SYS-09/10/15/28/04) — and producer review of the plan counts the
   full MVP load higher still (SYS-03/05/11/14/20/24 are also Not Started). Authoring
   throughput is the recorded schedule risk; review surfaces are the largest non-authoring
   cost inside it.
2. **The corpus's own numbers**: SYS-01's adversarial loop ran 10 rounds before the cap; the
   expensive whole-document pattern was the default for *everything*, including systems the
   index itself marks as leaf nodes with "design late".
3. **The pattern is already proven — this is an extension, not an invention**: diff-scoped
   re-reviews are house doctrine for re-verification (Combat 16/16, Movement 16/16,
   SYS-01 #10); batching formalizes what SYS-09/10's joint pre-shaping already implies.
4. **The validator (levers 1+8) composes**: once the pre-flight validator lands, the
   mechanical spot-check rounds (citation membership, ledger arithmetic) stop consuming
   review rounds entirely — the doctrine change covers what automation cannot: surface
   count and round economy.

---

## 4. Pilot evaluation & rollback — pre-registered (producer's 7 conditions, binding)

1. **Pre-registered pass/fail thresholds** (recorded here *before* SYS-09's review starts):
   - **Mechanism A**: at least one round and at least half a day per document saved, with
     **zero escaped blockers**.
   - **Mechanism B**: no increase in escaped blockers against the **house diff-scoped
     precedent** (Combat 16/16, Movement 16/16, SYS-01 #10) at or under two rounds — *not*
     the SYS-02/29/32 whole-document baselines; comparing a leaf first-pass to a bottleneck
     panel guarantees a false negative.
   - The joint log requires **per-document seat verdicts and per-document qa-lead PASS
     lines**; any capped remainder lands as one-clause obligations in the AC manifest with
     named verification routes.
2. **Event-based evaluation, not a set**: Mechanism A is evaluated **at Sprint 1's close**;
   Mechanism B at **SYS-25's first review** — never at SYS-30/31 (Full Vision/post-launch
   cannot gate an MVP/VS decision). Both halves can land before the SYS-16+17 batch.
3. *(folded into 1 — the B baseline correction.)*
4. *(folded into § 1 Mechanism B — the published-contracts surface.)*
5. *(folded into § 1 Mechanism B — priced cap extensions.)*
6. **Rollback = doctrine revert + a diff-scoped re-verification of the pilot documents
   against the escaped defect class.** "Degrades to the exact prior doctrine" is true for
   *future* documents only; the pilot documents must be re-verified on rollback.
7. **Later batch = SYS-16 + SYS-17** (SYS-18 only if in-window; SYS-23 stays out until it
   enters a window); and the § 2 wording fix is recorded ("bottleneck depth and the batched
   surface compose" — no one reads the batch as a scope downgrade).

The producer signs the pilot with these recorded and **prices its results at the
evaluation**; the milestone re-estimate (S1-001) must not bank the doctrine's savings as
certainty.

---

## 5. Sign-off verdicts (verbatim, recorded 2026-11-14)

### creative-director — CONCERNS (accepted; conditions C1–C3 folded into § 1/§ 2)

**Doctrine ruling (verbatim):**

> The framing "right-size review scope, never skip seats" preserves RJ-6 and is adopted as
> doctrine. RJ-6 rejected lean single-pass *authoring* of the differentiator systems — the
> named bottlenecks (SYS-09/10 among them) where the corpus's own catch-rate proof (39
> blockers on SYS-02, 25 on SYS-32, SYS-01's loop closed at 96 ledger units) establishes
> that review depth pays — and this doctrine keeps every bottleneck on whole-document
> adversarial first-pass with fresh seats, extends diff-scoping only to first-pass review of
> index-classified leaf nodes, and changes seat-surfaces, round economy, and surface count —
> the calendar problem IP-12 owns — never the quality mode; Mechanism B is therefore not a
> disguised regression of RJ-6 but its complement, under four binding conditions. First: the
> leaf first-pass surface includes, besides the authored sections and the arithmetic/AC
> fixtures, every consumed contract at its source of record *including that contract's
> pending-obligation ledger* — every recorded-but-not-yet-landed rider is read into review
> and the leaf is verified against the contract as it will stand after those riders land,
> because approval against a stale contract view is void. Second: the 2-round cap may
> convert only editing-discipline and single-document residues into one-clause obligations —
> a finding on a pinned cross-boundary contract, an ADR, a registry entity, another GDD's
> body, or a doctrine-class falsification never cap-converts and re-routes per the
> escalation clause, and a rider on a dependency contract is never closed by the leaf's cap:
> it remains owned by its source document until it lands and is re-verified there, which is
> precisely what prevents the cap from laundering prior sessions' "recorded, not yet landed"
> riders into approval. Third: every leaf approval record carries an obligations table —
> obligation, landing venue, verification route, owning seat — and the mandatory qa-lead
> spot-check verifies both repaired text and ledger completeness; on leaves the spot-check
> doubles as the tripwire for surface omission, and a leaf spot-check that finds a
> cross-boundary defect the first-pass missed is a recorded Mechanism-B rollback signal
> entering § 4's evaluation. Fourth: Mechanism A for SYS-09+SYS-10 is sound and *serves* the
> D-6/IP-2 obligation — the epistemic tells are one design surface across two owners
> (SYS-09's render surface, SYS-10's clue surface), so reviewing the pair jointly with both
> authors present, at full bottleneck depth with per-document verdicts, is how the boundary
> class that keeps re-blocking one seat at a time gets caught in a single round; with the
> conditions above the escalation clause is sufficient, and the joint log carries the
> explicit cross-document tells verdict item plus the pair's unauthored upstreams (SYS-03's
> five source families, SYS-04's IP-7 ambient-shift edge) as recorded contract items their
> final homes must land. The SYS-23 exclusion stands: it is the only leaf whose direct
> upstream (SYS-14 Grief-Boss Framework) is both unauthored and named in the High-Risk
> Systems table, so its consumed-contract surface is empty — right-sizing would be
> meaningless there and the escalation clause would fire on everything — and variety bosses
> are creative-differentiator content of exactly the class where depth pays, so SYS-23
> remains under the unchanged default doctrine, revisitable only by its own doctrine entry
> after SYS-14's GDD exists and the pilot evaluation passes. The no-header-line call is
> upheld: review process is not a scope decision, the header's riders must stay scope-only
> and undiluted, and the audit pointer already sits in the header; the compensation is that
> the fold-in to `docs/framework/director-gates.md` becomes the first paragraph of the next
> framework touch — until then, a session unaware of this doctrine simply defaults to full
> review, which fails safe.

**Explicit rulings**: SYS-23 — excluded, permanently for this pilot (grounds: unauthored +
high-risk direct upstream, empty consumed-contract surface, creative-differentiator class);
leaf *graph position* alone never justifies right-sizing. Systems-index header — no line
added; the `director-gates.md` fold-in is mandatory and first-paragraph at the next
framework touch. CD conditions C1–C3 are folded into § 1/§ 2; no re-circulation required —
"these conditions, as recorded here, are the doctrine."

### producer — CONCERNS (accepted; 7 conditions pre-registered in § 4; the pilot is authorized to proceed)

**Producer ruling (verbatim):**

> **Producer ruling (calendar authority) — CONCERNS; the pilot is authorized to proceed.**
> The doctrine buys real days without touching RJ-6: the catch-rate proof RJ-6 rests on came
> from bottleneck and differentiator documents, every named bottleneck — SYS-08, SYS-02,
> SYS-09, SYS-10, SYS-03 — keeps whole-document adversarial review with fresh seats, no seat
> is skipped anywhere, and the leaf set is exactly where the index itself says depth does
> not pay. It buys days, not weeks, and the milestone re-estimate must not bank it. Seven
> conditions, non-blocking for the Sprint 1 batch and blocking for the SYS-16+17 batch: (1)
> pre-register the pass/fail thresholds here before SYS-09's review starts — A: at least one
> round and half a day per document saved with zero escaped blockers; B: no increase in
> escaped blockers against the house diff-scoped precedent at or under two rounds — and
> require per-document seat verdicts and per-document qa-lead PASS lines in the joint log,
> with any capped remainder recorded as one-clause obligations in the AC manifest, each with
> a named verification route; (2) evaluate on events, not a set — A at Sprint 1 close, B at
> SYS-25's first review, never at SYS-30/31, which are Full Vision and post-launch and
> cannot gate an MVP/VS decision — and because SYS-16/17 sit behind SYS-07's rework, both
> halves can land before the gear batch; (3) B's baseline is the house diff-scoped precedent
> (16/16, 16/16, SYS-01 #10), not the SYS-02/29/32 whole-document baselines — comparing a
> leaf first-pass to a bottleneck panel guarantees a false negative; (4) B's first-pass
> surface must include the document's published contracts, not only its consumed ones — a
> leaf's outputs are someone's inputs, and SYS-25's pause surface to SYS-24, which has no
> GDD body for the generic escalation clause to catch, is the proof; (5) a CD or qa-lead
> round extension is quality-authority territory, but it is priced — record its calendar
> cost and I name the row that slips, so the cap stays soft on quality and not free on
> calendar; (6) rollback is a doctrine revert plus a diff-scoped re-verification of the
> pilot documents against the escaped class — "degrades to the exact prior doctrine" is true
> for future documents only; (7) the later batch is SYS-16+17, not +18 unless SYS-18 is
> actually in the same window, SYS-23 stays out until it enters one, and § 2's "the two
> mechanisms compose" should read "bottleneck depth and the batched surface compose" so no
> one reads the batch as a scope downgrade. With those recorded, I sign the pilot and will
> price its results at the evaluation.

**Outcome: ADOPTED WITH CONDITIONS.** The pilot set (SYS-09+10 batch; SYS-25/27/30/31
diff-scoped first-pass; SYS-23 excluded) is in force from 2026-11-14. Process note for the
record: the producer agent made two read-only git calls (log/status) before its no-git
constraint registered — no writes, no index changes.
