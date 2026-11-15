# ADR-0002: Save & Serialization — The Persistence Boundary, the Canonical Record, and the Writer's Thread

## Status

**Proposed** — drafted 2026-11-15 by the ADR-DRAFT lane (support). **Acceptance
awaits the technical-director's TD-ADR verdict**: the `/architecture-review` gate
returned `CONCERNS` with **zero blockers** and all ten recommendations were applied
and confirmed (the gate trail is `docs/architecture/adr-draft-review-log.md` §5),
but an advisory architecture-review verdict does not replace the TD-ADR gate, and
`Status: Accepted` would let story-readiness start stories against this decision
early. The acceptance text is prepared and recorded in the log; the status flips to
`Accepted` on the TD's verdict. The engine-probe register in §13 is an
**implementation gate**, not an ADR-status gate. Carried obligations (not status
gates): the story-gated engine half of the twin, and **CR-SAV-01** — the abandonment
regime's four-clause **exit-path reconciliation** of AC-SAV-23 and TR-SAV-014 (§5b). If a later
architecture review finds a contradiction with a newer Accepted ADR, this ADR
reverts to `Proposed` and is superseded explicitly.

## Date

2026-11-15

## Last Verified

2026-11-15 — verified against the SYS-03 GDD at Main `3fcedc6`
(`design/gdd/save-serialization.md`, APPROVED 2026-11-14), the Godot 4.7.2
engine-reference snapshots (`VERSION.md`, `breaking-changes.md`,
`deprecated-apis.md`), and a live run of the authoring twin
(`node tests/save-twin/save_twin.mjs` → **34/34 PASS**, 2026-11-15).
**Count discrepancy, recorded not edited:** the registry entry
`save_roundtrip_twin` says **32/32**; the twin prints **34/34** and the GDD's
header and gate manifest both say 34/34. The twin's own output is the authority;
the registry correction is queued to the sync lane.

## Decision Makers

| Seat | Role in this decision |
|---|---|
| technical-director | Acceptance chair; the thread model, the refusal doctrine, the ADR dependency ruling |
| lead-programmer | The core/adapter split, the canonicalizer, the migration registry API, the worker shape |
| godot-specialist | Engine-API verdicts: `FileAccess`/`JSON`/`HashingContext`/`Thread`/`DirAccess`, the verification register |
| qa-lead | The twin's engine half, the AC→gate ledger, the refusal fixtures |
| user | Scope authority; the MVP posture pinned 2026-11-14 (OQ-SAV-2/3/4/9) |

## Summary

SYS-03 is design-complete but its GDD deliberately stopped at the behaviour level,
leaving four implementation choices to this ADR: the writer's thread shape, the
file's byte layout and canonicalization, the migration table's registration API,
and the platform path helper. This ADR decides those four, plus the two engine
facts the GDD could not settle without a code decision — Godot's float-typed
`JSON` parse (handled by a schema-typed normalization pass that sits *below* the
hash) and the post-4.4 `FileAccess.store_*` boolean returns (every store call is
checked, and a `false` is classified by §5a's explicit `Error`→code table, never
by message inspection). The shape is one pure `PersistenceCore` over injected
ports, one `SaveWriter` node owning a single dedicated `Thread` with a
per-slot cancellable one-deep queue, one canonicalizer whose **fragment is a
byte-identical substring of the file and whose projection is the hash's input**,
and one path helper — with no second write path, no repair write, and no downgrade
writer anywhere.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (pinned; GDScript) |
| **Domain** | Core + Persistence (Core/FileAccess/JSON/Hashing/Threading) |
| **Knowledge Risk** | **HIGH** — 4.7.2 is post-cutoff (May 2025). The *persistence* APIs are the ones that moved (`FileAccess.store_*` returns `bool` from 4.4); the JSON number model is undocumented in the repo's snapshots and is probe item 1 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `breaking-changes.md` (4.3→4.4 `store_*` row; 4.6→4.7 table); `deprecated-apis.md`; `docs/framework/technical-preferences.md`; **ADR-0001 §16** (the notification-family probe this ADR's item 8 shares) |
| **Post-Cutoff APIs Used** | `FileAccess.store_*` → `bool` (4.4, **pinned by `breaking-changes.md`**); `FileAccess.flush()` / `close()` / `get_error()`; `JSON.parse_string()` returning floats for every number (the GDD's TR-SAV-026; the reason this ADR exists); `HashingContext` (SHA-256) — **`FileAccess.get_sha256()` is rejected**: it would hash the file, and the hash input is the canonical projection, not the file bytes; `Thread.start(Callable)` / `wait_to_finish()`; `DirAccess.rename_absolute()`; `DirAccess.get_space_left()` **[unverified name for 4.7.2 — register item 10]**; `OS.get_user_data_dir()` **[not used outside the path helper]**; `NOTIFICATION_WM_CLOSE_REQUEST` / `NOTIFICATION_APPLICATION_PAUSED` (**not** `NOTIFICATION_APPLICATION_FOCUS_OUT`, which is not an exit and must never trigger a save) |
| **Verification Required** | The 10-item register in §13, each with a Method and an Owner. **9 are `PROBE-PENDING`** and block their named gate; **item 2 is the only `DOCUMENTED`** (the 4.4 `store_*` row the repo's snapshot pins). On the TD-ADR verdict this ADR becomes **Accepted as architecture**; the register is the implementation gate, and no story may consume a `PROBE-PENDING` item as settled fact. |

> **Knowledge-gap warning (HIGH).** Two failure modes are specific to this
> version band and are load-bearing here: (1) `JSON` parses *every* number as a
> float, so a canonicalizer that refuses floats would refuse every legitimate
> save — the normalization pass (§6) is not optional polish, it is the load path;
> (2) `store_*` returns `bool` since 4.4, so an unchecked store is a silent short
> write, which is the exact torn-file failure the six-step write exists to make
> unreachable.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | **ADR-0001** (Accepted) — §3's freeze law (the E4 queue's window) and §5's tick-boundary pipeline (the completion drain, the snapshot tick) |
| **Enables** | SYS-05 Game Flow (the `load_result`/`restore_complete`/`load_complete` ordering), SYS-15 (the `cache` namespace + the `v1→v2` bump), SYS-16/SYS-17 (`progress`/`inventory` namespaces), SYS-20/SYS-25 (the read-only families), SYS-24 (the refusal/load-result surfaces + slot metadata) |
| **Blocks** | The first SYS-03 implementation story; every story that persists or restores state; the QA plan's device gate (AC-SAV-14/23) |
| **Ordering Note** | SYS-05's authoring consumes this ADR's `restore_complete`→`load_complete` ordering; the ADR does not wait on SYS-05 (SYS-03 publishes the contract). The engine-path twin runs at the first story, not at this ADR. |

## Context

### Problem Statement

The GDD is design-complete and its format contract is *proven* — the Node twin
runs 34/34 on real files — but the GDD explicitly stops at behaviour:
"*Implementation patterns (the writer's thread shape, the file's byte layout, the
migration table's registration API) are ADR raw material for the planned Save &
Serialization ADR; this GDD stays at the behavior level*" (§Overview) and
"*The Save & Serialization ADR (owned by the ADR-DRAFT lane) carries: the
writer's thread shape, the file's byte layout and canonicalization, the migration
table's registration API, and the platform path helper*" (§Dependencies).

Without this ADR, two implementers can build two incompatible persistence layers
from the same GDD, and the specific failure mode is not cosmetic: a save format
that is *almost* canonical writes files that fail their own hash on the next
load; a writer that does not check `store_*`'s boolean commits a truncated file;
a thread model that lets the game thread wait on IO blows the 16.6 ms budget at
the worst possible moment (the close request); a load path that materializes
absent-key defaults before the hash turns every valid sparse file into
`REFUSE_HASH_MISMATCH`; and a migration API that is not contiguous ships a chain
with a hole and silently strands a generation of saves.

The cost of not deciding is therefore a class of bugs the player experiences as
"the game forgot", in the one channel the design says the player must be able to
trust without thinking (the Player Fantasy's honesty clause).

### Current State

- `src/` contains no game code; the project has no `project.godot`. There is no
  persistence code to migrate.
- The SYS-03 GDD is **APPROVED** (2026-11-14) at Main `3fcedc6`, with the
  authoring gate recorded: the **reference twin, 34/34 PASS**
  (`tests/save-twin/save_twin.mjs`). The engine half (Godot `FileAccess`/`JSON`,
  `user://`, the worker `Thread`) is a **story-gated obligation** under the same
  fixtures (OQ-SAV-1 option (a), user-approved).
- The GDD's pinned MVP posture (2026-11-14): canonical JSON + SHA-256; `auto` +
  `manual_1`; no autosave timer; one dedicated worker thread with a one-deep
  queue; forward-only schema at v1 with zero registered migrations; no
  encryption, no anti-cheat.
- ADR-0001 is Accepted and supplies the two clocks, the freeze law and the
  tick-boundary discipline this ADR consumes.
- `docs/architecture/tr-registry.yaml` is still empty (`requirements: []`); the
  TR population is `/architecture-review`'s write, not this lane's.

### Constraints

- **Engine**: Godot 4.7.2, GDScript; 2D; mobile-first (iOS/Android) with PC
  secondary; 60 fps; 16.6 ms frame budget; ~150 MB memory ceiling.
- **Platform**: `user://` only; iOS background-kill is the most common exit on
  the primary platform, so the close/suspension event is the mobile kill path
  (TR-SAV-011); Android 16 KB page support is irrelevant to file IO but the
  export must still carry it.
- **Design**: SYS-03 reads no gameplay value and publishes none; it is never in a
  gameplay tick's critical path (the not-join precedent). No floats. No repair
  writes. No downgrade writer. The file is evidence.
- **Process**: Main is protected; work lands via branch + PR; the collaboration
  protocol requires approval before writes; every checkpoint is pushed.

### Requirements

- **R1 — One canonicalizer, one fragment.** The canonical form is a pure function
  of `{schema_version, payload}`; the fragment `canon(payload)` is a
  **byte-identical substring** of the file, and the hash input is the projection
  `canon({schema_version, payload})`. No second canonicalizer exists anywhere.
- **R2 — Integrity before interpretation.** The hash is checked before any
  semantic decision, but after the mechanical minimum (parse + normalize) that
  makes a hash computable.
- **R3 — The commit point is one rename.** No state is ever observable from a
  partially written file; a failure on either side of the rename leaves either
  the previous generation or a recoverable `.bak`.
- **R4 — The game thread never waits on IO during gameplay.** One write in
  flight per slot; one-deep queue; the completion drains at a tick boundary.
  Exactly one legal blocking path (the close-save), with `SAVE_JOIN_TIMEOUT_MS` as
  its **dev-assert measurement bound** — not a preemption guarantee. The exit
  policy is §5's, and it is stated as **two regimes, not one promise**: the write
  is **abandoned at a single fence** placed before the commit sequence, so an
  abandoned write never *starts* a rename and the slot keeps the last station
  autosave; and if a rename is **already in flight** when the bound expires it may
  still complete — landing the suspension snapshot AC-SAV-23 asks for — or be cut
  off by the platform's kill between steps 4 and 5, in which case step 5's row
  applies and the boot sweep promotes the `.bak` to the last station autosave. No
  regime leaves a torn file, and none leaves a state older than the last station
  save. A close-save that **fails** on the exit path is the third way to end without
  committing, and it recovers per its step's row (§5b). Regime 1's AC wording is a
  **filed revision (CR-SAV-01)**, not an interpretation (§5b).
- **R5 — The snapshot is taken at an eligible tick, once per request.** The E4
  queue's predicate is read from SYS-29's `FreezeState`; a mid-choreography
  snapshot is unreachable by construction.
- **R6 — Forward-only, contiguous, pure migrations.** A chain with a hole fails
  the boot; a migration moves values and only a genuinely new key takes a
  conservative default.
- **R7 — Refuse, never repair.** The eleven `REFUSE_*` and six `SAVE_FAILED_*`
  codes are a stable API; no code path clamps, defaults a contradiction, or
  rewrites a refused file.
- **R8 — One path helper.** Every save path string comes from one function; no
  `res://` writes, no absolute paths, no `OS.get_user_data_dir()` assembly
  outside it.
- **R9 — Testability.** The core is pure and injected (a `FileSystemPort`); the
  twin's 34 fixtures are the contract; the engine half runs at the first story.
- **R10 — Performance.** The snapshot is bounded constant (≤ ~150 elements,
  ≤ 0.5 ms dev assert); the restore is ≤ 1 ms (dev assert); the write is ≤ 2 KB.

## Decision

### 1 · Scope and non-goals

**In scope.** The core/adapter split; the byte layout and the canonicalizer; the
hash; the six-step atomic write and its thread shape; the read path and the
number-normalization pass; the migration registry API; the snapshot; the E4
freeze queue; the path helper and the platform event set; the slot-state record
and the boot sweep; the test seams; the engine verification register.

**Out of scope (owned elsewhere).** The truth model and the five families
(SYS-02); the flip's sequencer and E4's *law* (SYS-09); the epoch store and the
reconciliation (SYS-10); the `FreezeState` publication (SYS-29); the `cache`
namespace's shape (SYS-15); the refusal *flow* (SYS-05) and the refusal *surface*
(SYS-24); the bindings file `user://controls.cfg` (SYS-01, TR-INP-036).

**Non-goals.** No encryption or anti-cheat at MVP (the security audit may reopen);
no autosave timer; no third slot; no backup depth beyond one `.bak`; no binary or
`ResourceSaver` format; no compression; no cloud-sync logic; no repair write of
any kind; no migration step registered at v1.

### 2 · The node graph and the core/adapter split

The GDD's laws are all *decidable from data* — the canonical form, the gate, the
verdict, the queue's predicate — so they live in a pure `RefCounted` with no
`FileAccess`, no `Time`, no `SceneTree`, and no `JSON` singleton read. The engine
touches only the adapter.

```
                    ┌──────────────────────────── PersistenceCore (RefCounted, pure) ─┐
 SYS-02 store ─────▶│ TruthPort.read_world() → Dictionary                             │
 SYS-29 freeze ────▶│ FreezePort.sources_active() → PackedStringArray                 │
 ADR-0001 clock ───▶│ ClockPort.tick() → int                                          │
                    │                                                                 │
                    │  Snapshotter · Canonicalizer · SchemaGate · MigrationChain      │
                    │  IntegrityVerdict · QueueScheduler · RefusalCodes · Telemetry   │
                    └───────────┬─────────────────────────────┬───────────────────────┘
                                │ Snapshot (dict, bounded)    │ load_result / codes
                                ▼                             ▼
                    ┌──── SaveWriter (Node) ────┐   ┌──── LoadReader (Node) ────┐
                    │ Thread + Mutex + 2×Sem      │   │ synchronous (≤ 2 KB)      │
                    │ one-deep job queue        │   │ staging dict → swap       │
                    └──────────┬────────────────┘   └──────────┬────────────────┘
                               │ FileSystemPort                      │
                               ▼                                     ▼
                    ┌──────────── SaveIO (adapter) ──────────────────────┐
                    │ FileAccess · DirAccess · HashingContext · PathHelper│
                    └────────────────────────────────────────────────────┘
                               │
                               ▼
                        user://saves/<slot>.sav · .bak · .tmp
```

**Why the split is load-bearing.** AC-SAV-07's port spy, V-SAV-05's runtime
write ban, AC-SAV-26's static audits and AC-SAV-24's twin all need a core that
runs headless against a temp directory. A core that calls `FileAccess` directly
would make the twin an engine test, and the twin's whole value is that it runs at
authoring time with no Godot binary.

### 3 · The byte layout and the canonical form

The file is one JSON object. **The layout is fixed and the order is the law**;
the payload inside it is canonically ordered (sorted keys), so the two orders are
different things and must not be conflated:

- the **envelope's** key order is fixed and human-readable
  (`schema_version`, `game_version`, `saved_at_utc`, `state_hash`, `payload`);
- the **payload's** key order is canonical (byte-order sorted at every level).

```
{"schema_version":1,
 "game_version":"0.1.0",
 "saved_at_utc":"2026-11-14T12:00:00Z",
 "state_hash":"<64 lowercase hex>",
 "payload":{"world":{…}}}
```

**The canonicalizer** (`canon`, TR-SAV-009) is one pure function with five rules,
applied to `{schema_version, payload}` only:

1. object keys sorted by byte order, at every level;
2. **only the three outer family arrays are sets** — `doors_opened`,
   `memories_collected`, `cells_discovered` — sorted by their element's canonical
   string; a coordinate pair's inner order is **data**, never sorted (the twin's
   `CANON-pair` proves `[1,0] ≠ [0,1]`);
3. integers in decimal, no leading zeros, no exponent form; **no floats**;
4. strings JSON-escaped per the standard; booleans `true`/`false`; **no `null`**
   (an absent key is the only "nothing");
5. no insignificant whitespace inside the payload.

`game_version` and `saved_at_utc` are informational, sit **outside** the hash
input, and never gate anything (TR-SAV-008). A re-save of an unchanged state
therefore hashes identically with a different timestamp — the twin's
`RT-hash-stable`.

**One canonicalizer, two artifacts — stated precisely.** `canon(payload)` returns
the payload's canonical bytes (the **fragment**). The hash is computed over the
**projection** — the two-element object `{schema_version, payload}` run through the
*same* `canon` — and the file is the five-key envelope with **that same fragment
spliced in unchanged**. The law is therefore:

> the hashed fragment is a **byte-identical substring** of the file.

**The projection's byte order is the canonicalizer's, not this brace notation's.**
`canon` sorts object keys by byte order, so the projection's bytes are
`{"payload":…,"schema_version":1}` — `payload` first. The `{schema_version,
payload}` above is a **set**, never a byte order; an implementer who writes the
braces in that order hashes a different byte stream and the twin's three digests
will not reproduce. The twin proves the shape: `envelope()` wraps
`canon(payload)` and the hash covers `canon({payload, schema_version})`
(`tests/save-twin/save_twin.mjs`). There is no second canonicalizer and no second
payload serializer; the envelope's five keys are string-assembled *around* the
fragment. **Exactly three values in the file are outside the hashed input** —
`game_version` and `saved_at_utc` (informational, TR-SAV-008) and `state_hash`
itself (the digest) — and **everything else is inside it**: `schema_version` and
the whole payload. An implementer who excludes a fourth value, or who includes one
of these three, hashes a different byte stream. A debug pretty-printer, if one is
ever wanted, is a *different file* and never a save.

### 4 · The hash

`state_hash = sha256_hex(canon({schema_version, payload}))` (F-SAV-01), computed
with `HashingContext` (SHA-256) over the canonical bytes — one pass, no string
concatenation of hex, no `Crypto.sign` (there is no key and no authenticity
claim; the hash is *integrity*, and the GDD says so explicitly: "integrity is not
authenticity").

Because `schema_version` is inside the hash input, a downgrade edit (`99 → 1`)
yields `REFUSE_HASH_MISMATCH` and never a gate bypass (AC-SAV-22). This is the
single most important property of the layout: **the version is part of the
record, not metadata about it.**

### 5 · The write path on the worker thread

`SaveWriter` owns **one** `Thread`, one `Mutex`, **two** `Semaphore`s — one for the
job wakeup and one for the **completion signal** — and a **one-deep job queue per
slot** (TR-SAV-014): **one write in flight, at most one pending per slot**. It is
created at boot and joined at shutdown — **except on the close-save's abandonment
path, where the join is skipped and the platform's kill is the final bound (§5b;
the departure from TR-SAV-014's "joined at shutdown" is filed as CR-SAV-01, never
read into the text)**. The game thread
hands over an immutable job — **the deep-copied snapshot dict** (the copy is
synchronous, TR-SAV-012), the slot id and the cause — and never touches the
filesystem. **The bytes are produced off-thread**, exactly as TR-SAV-010/012
require; the copy is what is synchronous, not the serialization. **The two
semaphores are distinct and that is load-bearing**: the job semaphore wakes the
worker, the completion semaphore is posted once per finished job and is what the
close-save's timed wait blocks on (§5b) — the tick-boundary drain below still
reads the result record, so the completion signal is an *addition* to the drain,
not a replacement for it. **The post alone is not the answer, because it is not
job-specific**: the writer increments a `completed_seq` counter under the `Mutex`
when a job finishes and *then* posts; a waiter records its own job's seq at
dispatch and, once the wait returns, re-reads `completed_seq` under the same
`Mutex` — only `completed_seq ≥ its own seq` counts as completed. A stale post
from an earlier autosave, or a post from the other slot's job, therefore cannot
satisfy the wait. **A superseded or fence-cancelled job advances `completed_seq`
when it is dropped**, so no seq gap can exist and a completed close-save is never
misread as abandoned.

Six steps, all on the worker (TR-SAV-010), with the boolean-return discipline
from `breaking-changes.md`. **Row 3b is not a seventh step**: it is the
abandonment fence (§5b), inserted at the one place where no rename has begun yet,
so TR-SAV-010's six-step shape is unchanged.

| # | Step | Failure → |
|---|---|---|
| 1 | `canon()` the job's snapshot dict to bytes; compute `state_hash` | a canon failure is a **dev assert**, not a save failure (the snapshot is schema-typed by construction) |
| 2 | write bytes to `<slot>.tmp`; **check every `store_*` return**; `flush()`; `close()` | `SAVE_FAILED_DISK_FULL` / `SAVE_FAILED_PERMISSION` (§5a) |
| 3 | re-read `<slot>.tmp`, verify its hash (cheap at ≤ 2 KB) | `SAVE_FAILED_VERIFY` (pre-commit) |
| **3b** | **the abandonment fence** — read the job's `cancelled` flag; if set, stop here and emit nothing (the `.tmp` is deleted by the boot sweep, §11, or overwritten by the next write) | **no code**: the slot is unchanged, and an abandoned exit is not a save failure (§5b) |
| 4 | if `<slot>.sav` exists, `rename_absolute` it to `<slot>.bak` (replacing an older `.bak`) | `SAVE_FAILED_RENAME` |
| 5 | `rename_absolute` `<slot>.tmp` → `<slot>.sav` — **the commit point** | `SAVE_FAILED_RENAME` (`.sav` missing, `.bak` present → boot sweep recovers) |
| 6 | re-read `<slot>.sav`, verify its hash, emit `save_completed` (or `save_failed`) | `SAVE_FAILED_VERIFY` (post-commit → **roll back**: promote `.bak` back to `.sav`; no `.bak` → delete the unverified `.sav`, slot `EMPTY`) |

**§5a · The `Error` → `SAVE_FAILED_*` classification.** A boolean `store_*` plus
`get_error()` cannot by itself separate a full volume from a read-only one
(`ERR_FILE_CANT_WRITE` covers both), so the classification is **pre-flighted and
explicit**, never inferred from the message:

| Condition (in this order) | Code |
|---|---|
| the path is not writable / the directory cannot be created (`ERR_UNAUTHORIZED`, `ERR_FILE_NO_PERMISSION`) | `SAVE_FAILED_PERMISSION` |
| a pre-flight free-space check on the slot's volume is below `SAVE_MIN_FREE_BYTES` (**a constant, not a knob** — 4× the largest expected file; an ADR-local constant, in neither the GDD's knob table nor its "not knobs" list; if it ever becomes player-tunable it needs a GDD knob entry) | `SAVE_FAILED_DISK_FULL` |
| a `store_*` returns `false` **and** the pre-flight passed | `SAVE_FAILED_DISK_FULL` if the volume's free space dropped during the write, else `SAVE_FAILED_UNKNOWN` |
| `rename_absolute` returns non-`OK` at step 4/5 | `SAVE_FAILED_RENAME` |
| a read-back hash mismatch at step 3 / step 6 | `SAVE_FAILED_VERIFY` |
| the freeze publication is unreadable past `N_max` (queue path) | `SAVE_FAILED_FREEZE_UNAVAILABLE` |

The pre-flight's mechanism (`DirAccess.get_space_left()` or the platform
equivalent) is **register item 10**; the mapping table above is the contract, and
AC-SAV-09's injected-IO fixtures assert the code, not the message.

**The step-6 rollback is the one place a "restore" is legal**, and it is a
*file-level* restore of the last good bytes — the same operation as the boot
sweep. It invents no state. The distinction is stated once in the GDD and is a
law here: **promoting a `.bak` restores bytes; it is not a repair write.**

**The completion drain.** The worker's result record is drained at the **next tick
boundary** on the game thread — `physics_tick`, this ADR's `ClockPort` (§12; the
binding itself is Migration step 4), the clock that runs during a freeze and in a
non-Gameplay context. It is **not** the
`logic_tick`, which advances only in Gameplay and only unfrozen: a drain pinned to
it would defer a completed write through a flip freeze and could never run on the
quit-from-menu path. ADR-0001 §5 defines the *input* pipeline's phases 0–6 and has
no save phase — the save service runs its own drain **after** that pipeline, on the
same tick boundary, so `save_completed` lands on a tick without borrowing an input
phase. This is what AC-SAV-12's frame probe asserts.

**The close-save (the one legal block).** On the close request the save is
**dispatched to the writer and waited on** from the game thread — the bytes are
still produced on the worker (TR-SAV-010/012, §5); the game thread only blocks in
the wait. There is no frame to miss, the file is ≤ 2 KB, and
`SAVE_JOIN_TIMEOUT_MS` 250 ms is the **dev-assert measurement
bound**, not a preemption guarantee: no mechanism can interrupt a blocked syscall
or a stalled `wait_to_finish()`. **The wait is a timed wait on §5's *completion*
`Semaphore`** — `Semaphore.wait(SAVE_JOIN_TIMEOUT_MS)` **[unverified for 4.7.2 —
register item 5]**, the signal the worker posts
once per finished job, distinct from the job-wakeup semaphore — and that is what
makes expiry observable at all: without a timed wait, §5b's fence could never be
set. **If `Semaphore.wait` has no timeout argument in 4.7.2**, the same design runs
as a `Mutex`-guarded poll of `completed_seq` against a deadline — the mechanism is
the counter, not the primitive, so the probe's verdict changes no law here. **The wait is job-specific**, so it cannot be satisfied by a stale or
another-slot post: on return it re-reads §5's `completed_seq` under the `Mutex` and
counts the close-save as completed only if `completed_seq ≥` its own job's seq. The
counter is sound because the worker **dequeues one job at a time in seq order**
(one write in flight, TR-SAV-014), so a job that has not started cannot have
incremented the counter. **Three guards** — (a) and (b) are AC-SAV-23's two guard
clauses; (c) is AC-SAV-11's latest-wins coalescing applied at the writer: (a) if a write is
in flight, it completes first;
(b) **if `flip_sources_active` is non-empty, the close-save is skipped** and the
last station autosave is the fallback — a close-save snapshot taken there would
capture the mid-choreography state that V-SAV-05 and E4 forbid; **(c) a pending
(not yet started) job for the same slot is superseded and its result drained
before the close-save is dispatched** — otherwise the queued job would run after
the close-save, write the same `<slot>.tmp`, and rotate the newer file over it,
which is exactly the race AC-SAV-23's "the restored state equals the state at the
suspension" forbids. Guard (c) is why the one-deep queue is per slot and
cancellable rather than a bare ring.

**§5b · The abandonment fence — what "abandoned" means.** The exit policy is
explicit rather than aspirational, and it has **two regimes**, stated once here and
once in R4:

1. **The common regime — abandoned before the commit sequence.** If the close-save
   has not completed within the bound, the game thread sets the job's `cancelled`
   flag and **proceeds to exit**. The worker reads that flag at the **fence, step
   3b**, which sits immediately before the first destructive operation: a cancelled
   write stops there, performs **no rename**, emits **no** result (an abandoned
   exit is not a save failure, so no seventh `SAVE_FAILED_*` code exists), and
   leaves `<slot>.sav` untouched. The slot therefore still holds the **last station
   autosave**, which is the state the player returns to. The `.tmp` it may have
   written is deleted by the boot sweep (§11 step 1) or overwritten by the next
   write. **The abandoned path does not join the worker** — joining is what would
   re-block the game thread past the bound — so the shutdown join is skipped on
   this path and the platform's kill is the final bound. The `Thread` object is
   deliberately **not freed** here either, because freeing it can implicitly join;
   the process exit reclaims it.
2. **The residual regime — a commit already in flight.** A fence cannot un-issue a
   `rename_absolute` that the kernel is already executing, and the blocked syscall
   that *caused* the timeout may be exactly that rename. Two outcomes, both
   bounded: if the commit sequence **completes**, the slot holds the **close-save
   snapshot** — the suspension state AC-SAV-23 asks for, **newer** than the last
   station autosave, and guard (c) above has already drained any older pending job
   for the slot, so no ordering exists in which a late commit puts an *older* state
   over a newer one; if the **platform's kill** lands between steps 4 and 5, step
   5's failure row is the operative one — `.sav` missing, `.bak` present → the boot
   sweep promotes the `.bak`, i.e. the **previous generation**, which is the last
   station autosave. Neither outcome is torn and neither is older than the last
   station save; the platform's kill is the backstop, exactly as it is for a crash.

Neither regime can leave a torn file — the six-step write's commit point is the
rename — and neither can make the session worse than the last station save. **A
close-save that fails outright on the exit path is the third way a close-save can end
without committing** (beside abandonment and the kill): §5a's `SAVE_FAILED_*` code is
*produced* but never *observed*, because the drain happens on a tick the exiting app
will not run. The recovered state is **the one its step's row names**, and the split
is the commit point's, not a range: a failure at **steps 1–4** leaves the slot
**unchanged** (nothing has been renamed — a step-4 rename is atomic, so `.sav` is
untouched); a failure at **step 5** leaves `.sav` missing with `.bak` present, so the
boot sweep promotes the `.bak`; and a failure at **step 6** is post-commit, so its own
rollback promotes the `.bak` back over the unverified `.sav`. That is why CR-SAV-01's
clause 1 names the failed write beside the abandoned and the interrupted ones, and why
its clause 4 scopes the AC's code-assertion to a process that survives to observe it. What
the policy does **not** claim is that the write "never lands", or that a commit in
flight "always finishes": a blocked rename is precisely the case the timeout fires
on, and a kill between steps 4 and 5 is precisely the case step 5's row prices.
The fence is what makes the promise checkable: **an abandoned write never *starts*
a commit; a commit already started ends in one of the two states above — the
suspension snapshot, or the previous generation via step 5's row — and never in a
torn file.**

**AC-SAV-23's enumeration, and CR-SAV-01.** The frozen AC states **three outcome
cases** (plus AC-SAV-23's two guard clauses, both carried in §5): the event is delivered and
the close-save lands (restored = the suspension state); the event is **not
delivered** or the close-save is **skipped** (the last station autosave is the
fallback, "only when" one of those holds); and the event is delivered but the write
**fails** (a `SAVE_FAILED_*` code is asserted and the previous good state is
recovered). **Regime 1 is a fourth case**: delivered, attempted, abandoned. Its
*recovered state* is clause (c)'s — the previous good state, which is the last
station autosave — but **no code is observable**, because the process is exiting
and there is nothing left to report to. This ADR does **not** reinterpret the
frozen text (R7 freezes the six codes): it files **CR-SAV-01**, the exit-path
reconciliation of the close-save's non-completing cases, in **four** clauses —

1. **AC-SAV-23 clause 1** gains "…**the close-save's commit that completes — including
   one that completes after `SAVE_JOIN_TIMEOUT_MS` — restores the suspension
   snapshot; where the commit is abandoned before its rename, interrupted before step
   5, or fails on the exit path, the fallback clause applies**". Two things are being
   keyed here. **Completion, not the timeout**: §5b explicitly permits a rename
   already in flight to finish late, and that late commit restores the **better**
   state — a "committed-within-the-bound" test would misclassify exactly that case as
   a fallback. **And the failed write**: a failure on the exit path recovers per its
   step's row (§5b), which is not always the suspension snapshot. Without this clause
   the AC would also assert both "it lands and the restored state is the suspension"
   and "the fallback holds" — self-contradictory, and a QA run would fail the build
   for the behaviour §5b prices as correct.
2. **AC-SAV-23 clause (b)**'s "only when" gains "…**or the close-save was abandoned
   before its rename, interrupted before step 5, or failed on the exit path**", so
   the fallback is named rather than inferred.
3. **TR-SAV-014**'s "joined at shutdown" is qualified: "…**except on the close-save's
   abandonment path**, where the join is skipped and the platform's kill is the
   final bound" — joining there would be a second unbounded wait, i.e. the very
   thing the exit policy exists to prevent.
4. **AC-SAV-23 clause (c)**'s code-assertion is scoped: "…the reported
   `SAVE_FAILED_*` code **is asserted where the process survives to observe it**; on
   the exit path it is produced but not asserted, and the recovery is per the step's
   row." Without this the AC demands an assertion that no process is left to make —
   clause (c) applies whenever the event is delivered and the write fails, which is
   exactly the exit-path failure the fence exists for.

It is carried as an obligation (report §5, review log §5). The mechanism (the fence
and the two regimes) is this ADR's; the frozen wording is the GDD's.

### 6 · The read path and the number-normalization pass

Nine steps (TR-SAV-018), and the ordering is the law. The two engine-specific
decisions:

**6a. `JSON.parse_string` yields floats for every number.** A legitimately
written `truth_epoch: 0` re-parses as `0.0`; a canonicalizer that refuses floats
would refuse *every legitimate save*. The **normalization pass** (TR-SAV-026)
therefore sits between the parse and the hash, and it is **schema-typed, not
heuristic**: walk the parsed payload against the declared type table, accept a
number for an `int` key iff it is integral and in range and coerce it, refuse a
non-integral number as `REFUSE_FLOAT`, refuse a number for a non-integer key as
`REFUSE_TYPE`. The **envelope's `schema_version` gets the same pass** (it is
parsed as a float too). The pass is idempotent and total over the schema.

**The precedence is explicit** (the two codes can both claim one input): a
**non-integral number anywhere** is `REFUSE_FLOAT`, whatever its key's declared
type — TR-SAV-006's "a float anywhere" is the stronger law; an **integral number
at a non-integer key** is `REFUSE_TYPE`. `3.5` at a `String` key is therefore
`REFUSE_FLOAT`, and the fixtures that pin it are AC-SAV-06 (the float, write and
load sides) and AC-SAV-17's refusal matrix (the named code per fixture) — the two
must agree on this input.

**6b. Two refusal rules are decisions, not outcomes.** They are decided here
because the GDD states them as laws and only an implementation choice makes them
enforceable:

- **The epoch guard sits upstream of SYS-10** (TR-SAV-024(2)): `truth_epoch` is
  range-checked against SYS-02's `max_epoch` **inside the verdict** (F-SAV-04 row 8),
  so an out-of-range epoch is `REFUSE_EPOCH_RANGE` and SYS-10 is never called. The
  guard is a row in the ordered verdict, not a caller's check — that is the whole
  difference between "upstream" and "hopefully before".
- **A schema-ahead file never falls back to the `.bak`** (TR-SAV-020/021): the
  `.bak` is older by construction, so falling back would silently downgrade the
  session — the one lie the refusal exists to prevent. `REFUSE_SCHEMA_AHEAD` is
  therefore the **only** refusal that skips the `.bak` retry, and the rule lives in
  the load machine's **step 5** (TR-SAV-018's version gate → the GDD's `REFUSED`
  state; the slot records `REFUSED_READ_ONLY`), not in a caller's policy.

Both rules are enforced inside the verdict — the epoch guard is **F-SAV-04 row 8**
and the version gate is **row 4** — and the validation list asserts them
(AC-SAV-20/18).

**6c. Absence survives the hash.** A declared key that is absent **stays absent**
in the normalized payload — materializing the defaults there would change the
hash input and turn a valid sparse file into `REFUSE_HASH_MISMATCH`. The defaults
are applied **at restore, after the hash** (TR-SAV-023). This is the single
easiest way to get the load path wrong, and it is why the twin has an
`ABS-defaults` fixture.

The verdict function (`integrity_verdict`, F-SAV-04) is an **ordered list** whose
first three rows are mechanical (parse, version-is-int, every number integral) —
they are the minimum that makes a hash computable — then the hash, then the
interpretation (gate, shape, range). `MIGRATE` is an **output**, not a refusal.

### 7 · The registry: namespaces and migrations

Two registrations, one boot check, and one composition rule.

```gdscript
## Registers a namespace: one owner, a declared shape, and the migration step that
## introduces it. Called at boot, in code. TR-SAV-004.
## @param owner           the publishing system id (&"world", &"cache", &"progress", …)
## @param shape           {key: type} — the declared per-key type/range table
## @param migration_step  the version at which the key first appears (0 = present since v1)
func register_namespace(owner: StringName, shape: Dictionary, migration_step: int) -> void

## Registers a one-step, pure migration. Called at boot, in code, never at runtime.
## @param from_version  the source version; must be >= 1 and < CURRENT_SCHEMA_VERSION
## @param migrate       Callable(payload: Dictionary) -> Dictionary; pure; must not
##                      read the store, the clock, or any singleton
## @param shape_note    the human-readable shape delta (one line) for the boot log
func register_migration(from_version: int, migrate: Callable, shape_note: String) -> void
```

**The composition rule (the two APIs are not alternatives).** A namespace
registered with `migration_step = k > 0` **requires** a registered
`MIGRATIONS[k−1]` that adds the key with its conservative default; the boot
checks that pairing (V-SAV-08's owner+reader check and V-SAV-02's contiguity are
the same check seen from two sides). A namespace present since v1
(`migration_step = 0`) requires no migration. `cache` is the worked example:
registered, `migration_step = 2`, and its `v1→v2` step is what makes the key
appear (TR-SAV-004).

- **Contiguity is a boot check** (V-SAV-02): `MIGRATIONS[n]` must exist for every
  `1 ≤ n < CURRENT_SCHEMA_VERSION`; a hole is a dev boot failure.
- **One step at a time, forward only**: `migrate(v) = M_{CURRENT−1} ∘ … ∘ M_v`.
- **A rename is `put(new_key, pop(old_key))`** — the value moves; only a genuinely
  NEW key takes the conservative default. Losing a set flag to a default would
  silently cancel the pending flip, which is the exact failure the migration
  exists to prevent (the twin proves the idiom with a test-only `v1→v2` rename
  that is **never shipped**).
- **The chain is testable below the gate** by a synthetic `CURRENT = 3` harness
  with two registered steps (AC-SAV-16); a `v0` file is a *refusal* fixture and
  never a migration input.
- **v1 registers zero migrations**; the machinery ships on day one anyway,
  because retrofitting a chain into a shipped format is the change that cannot be
  tested.

### 8 · The snapshot

The snapshot is taken **synchronously on the game thread at `t_write`**
(TR-SAV-012): a deep copy of the `world` namespace plus every registered
namespace's current values, **as typed containers** (`Array`/`Dictionary` of
`int`/`String`/`bool`), never as engine resources. Its cost is bounded constant —
SYS-02's registries bound the arrays (128 borders, 1 flag, 4 memories, 6 cells)
so the copy is ≤ ~150 elements — and the dev assert prices it at ≤ 0.5 ms. The
job carries **the deep copy, not a live reference** (the worker reads a dict nobody
else can mutate), which removes the shared-mutable-state question without moving
serialization onto the game thread: TR-SAV-012's split is preserved exactly — the
**copy** is synchronous, the **bytes** are produced off-thread.

The snapshot is taken **once per request**; a re-request after a failure is a new
request with a new snapshot (a save is a snapshot of *now*).

### 9 · The E4 freeze queue

The predicate is `writable(t) ≡ flip_sources_active(t) = ∅`, read from **SYS-29's
`FreezeState` publication** — which is the **flip-scoped projection of ADR-0001
§3's `freeze_sources` set**: the base `truth_flip` source plus every admitted
`truth_flip_ext_n`. The flip source's clear tick is the force-release boundary on
the abort path and `freeze_close` (E6) on the committed path; ADR-0001 owns the
set, SYS-29 owns the projection, and SYS-03 reads only the projection. `t_write =
min { t ≥ t_req : writable(t) }` (F-SAV-03), and the bound `N_max` is **consumed
from SYS-09** (`worst_case_hold_ticks`, base plus the two admitted extension
spans) — SYS-03 never re-derives the ms→tick conversion.

- **Coalescing**: one pending request per slot; a second for the same slot is
  latest-wins with one telemetry record. Different slots queue independently.
- **The bound is the liveness proof**: a queued save cannot wait longer than the
  longest legal hold.
- **The unreadable publication** (a boot-order defect) reads **true** (the
  conservative reading: unreadable means frozen) for at most `N_max` ticks, then
  fails with `SAVE_FAILED_FREEZE_UNAVAILABLE` — a bounded wait, never a hang.
  **The reading's owner is SYS-29** (the publication's publisher); SYS-03 infers
  the freeze state from that one signal and from nothing else.

### 10 · The path helper and the platform policy

```gdscript
## The ONLY place a save path is assembled. Every caller passes a slot id and a suffix.
## @param slot    &"auto" or &"manual_1" (SLOT_IDS; a third is a code change + migration review)
## @param suffix  &"sav" | &"bak" | &"tmp"
## @return        "user://saves/<slot>.<suffix>"
static func save_path(slot: StringName, suffix: StringName) -> String
```

- `user://saves/` is created by the helper on first use (`DirAccess.make_dir_recursive_absolute`).
- **No** `res://` write, **no** absolute path, **no** `OS.get_user_data_dir()`
  outside the helper. AC-SAV-26's audit greps for the second occurrence.
- **The platform event set** is `{station ack, desktop quit, Android onStop, iOS
  application-paused}` (TR-SAV-011) — an **event set, never a timer**. In Godot
  terms: `NOTIFICATION_WM_CLOSE_REQUEST` (desktop quit),
  `NOTIFICATION_APPLICATION_PAUSED` (both mobile platforms' suspension),
  `NOTIFICATION_APPLICATION_FOCUS_OUT` is **not** in the set (a focus loss is not
  an exit) and must not be wired to a save.
- A read-only or full volume yields `SAVE_FAILED_PERMISSION` /
  `SAVE_FAILED_DISK_FULL`; the session continues and the surface reports it.

### 11 · The slot-state record and the boot sweep

States: `EMPTY` · `OK` · `BAK_ONLY` · `REFUSED_READ_ONLY`. Edges are total
(`EMPTY → OK` on the first successful write; `OK → BAK_ONLY` on a step-5 rename
failure; `BAK_ONLY → OK` on the sweep or the next successful write;
`OK|BAK_ONLY → REFUSED_READ_ONLY` when **both** files fail the load — **or
immediately on `REFUSE_SCHEMA_AHEAD`**, where the `.bak` is never attempted
(§6b). TR-SAV-020's footnote 1 authorises the carve-out explicitly
("`REFUSE_SCHEMA_AHEAD` is read-only unconditionally"), while the GDD's edge
sentence (line 362) enumerates the edge as firing "only when both files fail" —
the footnote is the authority and the carve-out is stated rather than implied.

The **boot sweep** runs per slot, in this order, before any load: (1) if
`<slot>.tmp` exists, delete it (`tmp_swept`); (2) if `<slot>.sav` is missing and
`<slot>.bak` exists, promote the `.bak` (`bak_promoted`); (3) neither file →
`EMPTY`, which is the first boot and not an error. The order matters: deleting the
`.tmp` first means the promotion can never race a stale temp. (TR-SAV-015's prose
lists the promotion first; **AC-SAV-13's list is the one the sweep implements** —
the divergence is deliberate and cited, not an oversight.)

### 12 · Test seams

- **`FileSystemPort`** — `read_bytes(path) -> PackedByteArray`, `write_bytes(path,
  bytes) -> Error`, `rename(from, to) -> Error`, `exists(path) -> bool`,
  `remove(path) -> Error`. The real implementation is `SaveIO`; the twin's is an
  in-memory/temp-dir implementation. Fault injection at each of the six steps is a
  port decorator, not a code path in the writer.
- **`ClockPort`**, **`TruthPort`**, **`FreezePort`**, **`TelemetryPort`** — the
  four reads the core performs, all injected.
- **The engine half** (story-gated): the same 34 fixtures, run in-engine, must
  assert `typeof(value) == TYPE_INT` after the normalization pass on a real
  `JSON.parse_string` result **and** reproduce the three digests recorded in the
  GDD's **F-SAV-01 worked-example table** (`bf18d435…`, `e3f7a6a0…`, `05b1e48e…` —
  the **full** 64-hex values live in that table and in the twin's own run output;
  a fixture copies them from the GDD, never from this ADR's truncated prefixes).
  The reference twin cannot simulate the float-typed parse (JavaScript has one
  number type) — it tests the refusal branch and the coercion's identity only.
  **This is the named split, not an omission.**

### 13 · The engine verification register

Every `PROBE-PENDING` row carries a **Method** (a runnable protocol with a
pass/fail) and an **Owner**, so a probe can be closed or failed rather than
narrated.

| # | Item | Verdict | Method (pass = ) | Owner | Blocks |
|---|---|---|---|---|---|
| 1 | `JSON.parse_string` returns `float` for **every** JSON number, including `schema_version` | **PROBE-PENDING** | parse the three twin payloads; every number's `typeof` is `TYPE_FLOAT` before the pass and `TYPE_INT` after it | godot-specialist | The first story (the load path's premise) |
| 2 | `FileAccess.store_*` returns `bool` (4.4+) and `false` is detectable | **DOCUMENTED** (`breaking-changes.md`, 4.3→4.4 row) | — | — | — |
| 3 | `HashingContext` SHA-256 over the canonical bytes equals the Node twin's digest for the same input | **PROBE-PENDING** | the three fixture payloads hash to `bf18d435…`, `e3f7a6a0…`, `05b1e48e…` — the **full digests from F-SAV-01's worked-example table** (`design/gdd/save-serialization.md`), which the twin reproduces; the engine run must match all three | lead-programmer | The first story; AC-SAV-24's engine half |
| 4 | `DirAccess.rename_absolute` is atomic-enough on iOS/Android for the commit point | **PROBE-PENDING** | kill the process during step 5, 20 trials: 20/20 boots load either the old `.sav` or the promoted `.bak`; zero torn reads | devops-engineer | The first story; AC-SAV-14/23 |
| 5 | `Thread.start(Callable)` + two `Semaphore`s (job wakeup; completion) + `Mutex` gives one in flight + one pending per slot with no lost wakeup, and a **timed, job-specific** completion wait | **PROBE-PENDING** | 1,000 alternating requests per slot: every **non-cancelled** request yields exactly one result, no result is duplicated, no job is dropped; a wait with an expired timeout returns without a result (the abandonment path); and a **stale post** (a completed earlier job, or the other slot's job) does **not** satisfy a subsequent timed wait (`completed_seq`'s check) | lead-programmer | The first story; §5b's fence |
| 6 | `flush()` before `close()` makes a short write detectable by the step-3 re-read | **PROBE-PENDING** | inject a truncated buffer: step 3 fails 20/20 with `SAVE_FAILED_VERIFY`, and the previous `.sav` is byte-identical afterwards | lead-programmer | The first story; AC-SAV-09 |
| 7 | `user://` resolves to the app's data dir on both platforms and survives a relaunch | **PROBE-PENDING** | write, kill, relaunch, load: the file is under the app data dir and the state restores | qa-lead | AC-SAV-14 |
| 8 | The suspension notification is delivered **before** the platform kills the app (iOS background-kill; Android `onStop`) | **PROBE-PENDING** | background the app from gameplay on real hardware 10× per platform: the close-save lands **within `SAVE_JOIN_TIMEOUT_MS` 10/10** and the restored state equals the suspension state. An abandonment is a **probe failure**, not a pass — §5b defines what the player gets if the fence ever fires, it does not license the fence to fire | qa-lead | AC-SAV-23 — **the same notification family as ADR-0001 §16 item 14** (held-state semantics, still open there); this ADR scopes the probe to the save's use |
| 9 | The `Error`→code classification separates a full volume from a read-only one (§5a) | **PROBE-PENDING** | an injected full-volume fake and an injected read-only fake yield `SAVE_FAILED_DISK_FULL` and `SAVE_FAILED_PERMISSION` respectively; the same pair on a device (a full volume via a disk-fill harness) agrees | devops-engineer | AC-SAV-09 |
| 10 | `DirAccess.get_space_left()` (or the platform equivalent) exists in 4.7.2 and reports the slot's volume | **PROBE-PENDING** | the call returns a plausible byte count for `user://saves/` and falls back to the store-only path if absent | godot-specialist | §5a's pre-flight |

`PROBE-PENDING` is an open verdict, not a pass: no story may consume items 1, 3–10
as settled fact (the AC-74 pattern from ADR-0001). **Item 2 is the only engine
fact the repo's own snapshot pins**; the JSON float model is **not** in
`docs/engine-reference/godot/` (a grep for `JSON` finds nothing), which is why it
is a probe and not a citation — and why item 1's Method is the load path's proof.

### Architecture diagram — one save request at a glance

```
game thread                                   worker thread
-----------                                   -------------
[tick] request(slot, cause)
  │  context gate (loading? → REJECTED)
  │  eligibility (FreezePort) ── frozen ──▶ QUEUED ─┐
  │                                    ◀────────────┘ (first unfrozen tick)
  ▼
SNAPSHOTTED  (deep copy, ≤150 elements, ≤0.5 ms — SYNCHRONOUS)
  │  job = {snapshot copy, slot, cause}   (the copy is the only game-thread work;
  │                                        the close-save is the one exception, §5)
  ▼
job → one-deep queue ────────────────────────▶ 1 canon() + hash
                                               2 tmp write + store_* checks
                                               3 verify
                                             3b FENCE (cancelled → stop, no rename)
                                               4 rotate .bak
                                               5 RENAME (commit) ─ 6 re-read verify
                                               ─▶ result record + completion post
  ┌──────────────────────────────────────────────────────────┘
  ▼
[tick boundary] drain → save_completed(slot, tick, bytes, hash)
                       | save_failed(slot, code)  [step 6's rollback runs on the worker]
```

### Key interfaces

```gdscript
# ---- core (pure, injected) -------------------------------------------------
class_name PersistenceCore extends RefCounted

func request_save(slot: StringName, cause: StringName) -> void      # intent only
func tick(t: int) -> void                                            # queue + drain
func request_load(slot: StringName) -> LoadResult                    # synchronous
func snapshot_world() -> Dictionary                                  # bounded copy
func canon(envelope: Dictionary) -> PackedByteArray                  # the ONE serializer
func integrity_verdict(bytes: PackedByteArray) -> Verdict           # F-SAV-04 order
func normalize_numbers(parsed: Variant, schema: Dictionary) -> Variant

# ---- ports ----------------------------------------------------------------
class_name FileSystemPort extends RefCounted
func read_bytes(path: String) -> PackedByteArray
func write_bytes(path: String, bytes: PackedByteArray) -> Error
func rename(from: String, to: String) -> Error
func exists(path: String) -> bool
func remove(path: String) -> Error

# ---- the result records (stable API; never display text) ------------------
# save_completed(slot, tick, bytes, hash)
# save_failed(slot, code)             code ∈ the six SAVE_FAILED_*
# load_result ∈ {restored(slot), refused(slot, code), absent(slot)}
# restore_complete(slot, tick)        # strictly before SYS-05's load_complete
```

### Implementation guidelines

- **Never** serialize twice. If a debug dump is wanted, it is a separate file and
  a separate function name.
- **Check every `store_*` return.** An unchecked store is a silent short write.
- **Never materialize a default before the hash.** Defaults live in one function
  (`apply_absent_defaults`) called at restore only.
- **Never** call `FileAccess` from the core; the port is the only door.
- **Never** write to a `.sav` directly; the temp+rename path is exclusive
  (V-SAV-04, a CI grep).
- The refusal codes are a **stable API**, not display text — SYS-24 owns the
  sentences.
- A new namespace is a registration + a migration step + at least one reader
  (V-SAV-08), never a silent key.

## Alternatives Considered

### Alternative 1: A binary format (`store_var` / `ResourceSaver`)

- **Description**: write a `Dictionary` via `FileAccess.store_var` or save a
  `Resource`.
- **Pros**: smaller, no canonicalization question, no float-parse problem.
- **Cons**: `store_var` is not a stable cross-version contract and has no
  canonical form, so the hash would be a hash of an unspecified byte stream;
  `ResourceSaver` loads arbitrary resource types, which is a code-execution
  surface from a user-writable file.
- **Estimated Effort**: 0.4× the chosen approach to write, ∞ to keep.
- **Rejection Reason**: the GDD pins canonical JSON + SHA-256 (OQ-SAV-3,
  user-approved); a binary blob cannot be *evidence* in the design's sense.

### Alternative 2: `ConfigFile` / INI

- **Description**: one section per namespace.
- **Pros**: human-readable, engine-native, no JSON float model.
- **Cons**: no arrays of dicts, no nesting depth, no canonical ordering, and no
  integer type guarantee.
- **Estimated Effort**: 0.5×.
- **Rejection Reason**: the schema is nested (`world.truth_flags`, coordinate
  pairs); INI cannot express it without inventing an encoding, which is worse
  than JSON.

### Alternative 3: Encrypt at MVP

- **Description**: AES the payload so a hand-edited file is not merely refused
  but unreadable.
- **Pros**: raises the tampering cost; hides the schema from casual inspection.
- **Cons**: key storage on-device is theatre without a server; a lost key is an
  unrecoverable save; the hash already detects every edit, and the refusal path
  already handles it honestly.
- **Estimated Effort**: +0.6×, plus a key-management surface.
- **Rejection Reason**: the GDD records the abstention explicitly (OQ-SAV-3); the
  security audit may reopen it as its own decision.

### Alternative 4: A thread pool / `WorkerThreadPool`

- **Description**: submit writes to the engine's pool.
- **Pros**: no thread lifecycle to own; the engine handles the join.
- **Cons**: the pool gives no ordering or one-in-flight guarantee per slot, and
  the close-save needs a *specific* join with a bounded timeout; a pool task
  cannot be cancelled or awaited per-slot without building the same bookkeeping.
- **Estimated Effort**: 0.8×.
- **Rejection Reason**: OQ-SAV-9 (user) pins one dedicated thread with a
  one-deep queue; the ordering guarantee is the point.

### Alternative 5: Direct overwrite (no temp+rename)

- **Description**: write `<slot>.sav` in place.
- **Pros**: simplest; half the IO.
- **Cons**: a kill mid-write leaves a torn file, and a torn file is the one state
  the whole design forbids.
- **Estimated Effort**: 0.3×.
- **Rejection Reason**: R3. The rename is the commit point; there is no
  alternative that preserves it.

### Alternative 6: Store the derived targets (avoid re-derivation)

- **Description**: persist border states, gate openings, materials, MetSys's
  Dictionary.
- **Pros**: a faster load; no derivation code at load.
- **Cons**: two sources of truth; a derived value that disagrees with its source
  is a contradiction the file cannot resolve, and the design's whole promise is
  "store sources, derive targets".
- **Estimated Effort**: −0.2× to write, +2× to debug.
- **Rejection Reason**: TR-SAV-002 and V-SAV-03; the MetSys Dictionary is a
  **written derived target** only.

### Alternative 7: Clamp or repair on load

- **Description**: an out-of-range epoch is clamped to `max_epoch`; an impossible
  combination is "fixed".
- **Pros**: the player always gets a playable world; no refusal surface.
- **Cons**: a repair write is the system lying about the past — the Player
  Fantasy's honesty clause exists to forbid exactly this.
- **Estimated Effort**: 0.2×.
- **Rejection Reason**: R7. The refusal path is a first-class outcome with named
  codes.

### Alternative 8: An autosave timer

- **Description**: autosave every N seconds.
- **Pros**: never lose more than N seconds; no dependency on station placement.
- **Cons**: a new cadence knob and a new perf surface; it duplicates the station
  save and makes the diegetic save point meaningless.
- **Estimated Effort**: 0.3×.
- **Rejection Reason**: OQ-SAV-4 (user) — the event set replaces it, including
  the iOS background-kill path.

### Alternative 9: Snapshot inside the freeze window, guarded by a double epoch read

- **Description**: take the snapshot at `t_req` and read the epoch twice to
  detect a mid-flip race.
- **Pros**: no queue, no wait.
- **Cons**: the "read twice" defence is a race detector, not a guarantee, and the
  GDD's E4 law is a *timing* law; a snapshot at an unfrozen tick makes the
  post-flip capture true **by construction** instead.
- **Estimated Effort**: 1.2× and permanently fragile.
- **Rejection Reason**: TR-SAV-013 — "no read race exists, and no 'read the epoch
  twice' defence is needed."

### Alternative 10: A backup depth of two

- **Description**: `.bak` + `.bak2`.
- **Pros**: survives two consecutive corruptions.
- **Cons**: new naming, rotation and sweep rules; two corruptions in a row is
  already a storage failure, not a save-format failure.
- **Estimated Effort**: 0.4×.
- **Rejection Reason**: the GDD lists backup depth as **not a knob**; depth-2 is
  a future change with its own review.

## Consequences

### Positive

- The format contract is **already proven** (34/34) and this ADR only fixes the
  implementation shape, so the first story starts from evidence rather than from
  a hypothesis.
- The core/adapter split makes every law headless-testable; the twin's fixtures
  become the story's fixtures with no rewrite.
- One canonicalizer means the hash and the file cannot drift: **the fragment is a
  substring of the file by construction**, so a re-serialized payload is
  impossible.
- The step-6 rollback makes "the committed state is the previous state" true even
  after the commit point, which is the strongest honest guarantee available.
- The verification register turns the version band's uncertainty into a checklist
  with owners instead of a lurking risk.

### Negative

- A dedicated thread is a lifecycle the project now owns (create at boot, join at
  shutdown — except on the close-save's abandonment path, §5b — one lost-wakeup
  class of bug).
- The canonical form costs a sort on every write and every load; at ≤ 150
  elements this is microseconds, but it is not free.
- The normalization pass is a second walk of the payload on every load.
- `user://` is the only location: a player who reinstalls loses the save, and
  that is the platform contract rather than a bug.

### Neutral

- The twin's engine half remains a story-gated obligation; this ADR does not
  discharge it and does not pretend to.
- `docs/architecture/tr-registry.yaml` stays empty until `/architecture-review`
  populates it (ADR-0001 left it empty too).
- The refusal codes' *sentences* are SYS-24's; this ADR owns only the codes.
- `SAVE_TELEMETRY_RATE_LIMIT_MS` and `SAVE_JOIN_TIMEOUT_MS` are dev-assert and
  telemetry knobs, not player-facing settings.

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| `JSON` float model mishandled → every save refuses | Medium | High | The schema-typed normalization pass below the hash; V-SAV-09; the engine-half fixture |
| Unchecked `store_*` → silent short write | Medium | High | The boolean discipline in §5; the step-3 re-read; AC-SAV-09's six-step fault injection |
| Rename not atomic on a mobile filesystem | Low | High | Register item 4; the `.bak` promotion path; AC-SAV-14/23 |
| Lost wakeup / lost job in the one-deep queue | Low | High | Register item 5; one job per slot; the completion drained on a tick |
| Close-save blocks past the suspension window | Low | Medium | The two-regime exit policy (§5, §5b) and **CR-SAV-01**: the step-3b fence abandons the write with no rename and the last station autosave stands; a commit already in flight lands the suspension snapshot, or — killed between steps 4 and 5 — step 5's row promotes the `.bak`; a failure on the exit path recovers per its step's row, with its code produced but never observed. Never older, never torn. Plus the freeze-skip guard; ≤ 2 KB by construction |
| Absent-key defaults materialized before the hash | Medium | High | TR-SAV-026 step 4 + TR-SAV-023; the twin's `ABS-defaults` |
| Migration chain hole ships | Low | High | V-SAV-02's contiguity boot check; the synthetic `CURRENT = 3` harness |
| A second write path appears (an ad-hoc `FileAccess` call) | Medium | High | V-SAV-04's CI grep; AC-SAV-26; the port is the only door |
| A repair write is introduced "to be helpful" | Medium | High | R7; the law stated once (file-level restore ≠ state repair); review discipline |
| Registry/twin count drift (32 vs 34) | **Occurred** | Low | The twin reproduces **34/34** on this checkout (§Last Verified) and the GDD says 34/34; the registry entry `save_roundtrip_twin` still says 32/32 → reported to the sync lane as a registry correction, never edited here |

## Performance Implications

| Metric | Before | Expected After | Budget |
|---|---|---|---|
| CPU — snapshot + canon | N/A (no code) | ≤ 0.5 ms dev assert per request (≤ ~150 elements) | Inside the request's own tick; not the gameplay envelope |
| CPU — write | N/A | ≤ 2 KB of IO on the worker; the game thread touches nothing | Zero gameplay-frame cost (AC-SAV-12) |
| CPU — load | N/A | ≤ 1 ms restore (dev assert); synchronous inside the loading context | The loading context, not a gameplay tick |
| Memory | N/A | One snapshot dict (≤ ~150 elements) + one job + a 256-record telemetry ring | ~150 MB process ceiling; the save is not a memory consumer |
| Load time | N/A | ≤ 2 KB read + parse + normalize; sub-millisecond | Negligible |
| Network | N/A | None (single-player; cloud backup is the platform's) | N/A |

SYS-03 **does not join the gameplay-tick envelope** — the snapshot is bounded
constant work and the write is off-thread (the SYS-02/SYS-09/SYS-10 not-join
precedent). SYS-03 prices **event budgets** (the snapshot assert, the restore
assert) instead of a frame share.

## Migration Plan

No existing game code exists; the migration is a greenfield scaffold.

1. **Pure core.** Add `src/save/core/` (`PersistenceCore`, `Canonicalizer`,
   `SchemaGate`, `MigrationChain`, `IntegrityVerdict`, `QueueScheduler`,
   `RefusalCodes`, `TelemetryRing`) and the GUT suite under `tests/unit/save/`
   with the `FileSystemPort` fake. No `FileAccess`, no `Thread`.
2. **Adapters.** Add `SaveIO` (FileAccess/DirAccess/HashingContext), `PathHelper`,
   `SaveWriter` (the thread), `LoadReader`. Wire the boot sweep and the platform
   notification set.
3. **The engine twin.** Run the 34 fixtures in-engine; assert the three hashes
   and `TYPE_INT` after normalization; attach the verdict to the first story's
   evidence. Close register items 3–7.
4. **The seams.** Wire `FreezePort` to SYS-29's `FreezeState`, `TruthPort` to
   SYS-02's store, `ClockPort` to ADR-0001's `physics_tick`; wire the MetSys
   adapter's write-only Dictionary.
5. **The publications.** `save_completed` / `save_failed` / `load_result` /
   `restore_complete` + the slot-list metadata; hand SYS-05 the ordering
   obligation (`restore_complete` strictly before `load_complete`).
6. **Device gate.** AC-SAV-14/23 on real iOS and Android hardware.

**Rollback plan.** Delete `src/save/` and the boot wiring. No save data needs
migrating: v1 is the only version ever shipped at MVP, and the sweep/refusal paths
already tolerate an absent or unreadable file. The GDD and this ADR remain; a
superseding ADR would replace the writer, not the laws.

## Validation Criteria

**Two gates, two lists.** The **decision-conformance** list (15 criteria) states
what this decision must be able to prove. Several are verified by fixtures that land
with the implementation (`src/save/` does not exist yet), so they are the criteria
the *decision* fixes — not checks runnable at sign-off. The **story gate**
(2 criteria) closes at the first implementation story.

**Decision conformance (what the decision must be able to prove).**

- [ ] One canonicalizer: `canon(payload)` produces the fragment, the hash covers
      the projection `canon({schema_version, payload})`, and the fragment appears
      byte-identically in the file — asserted by the step-3/step-6 re-read
      (AC-SAV-09) **and** by a CI grep for a second `to_json`/`JSON.stringify`
      site under `src/save/` (V-SAV-04's grep family).
- [ ] The version is inside the hash: a `99 → 1` edit refuses with
      `REFUSE_HASH_MISMATCH`, never a gate bypass (AC-SAV-22).
- [ ] The six-step write's fault injection names the outcome **per commit point**;
      no torn file is ever readable (AC-SAV-09, the twin's `WRITE-*`).
- [ ] The step-6 rollback restores the previous generation, or leaves the slot
      `EMPTY` on a first write (AC-SAV-09/23).
- [ ] The close-save supersedes a pending same-slot job before it writes; no
      queued job can overwrite the close-save (AC-SAV-23). The abandonment fence
      (step 3b) is asserted twice: a cancelled job performs **no rename** and
      leaves the slot's bytes unchanged (the last station autosave stands), and a
      job whose commit sequence has begun completes with the suspension snapshot
      — the two regimes of §5b, each with its own injected-IO fixture; a failure on
      the exit path recovers **per its step's row** — the slot unchanged for steps
      1–4, `.bak` promotion for step 5, step 6's rollback for step 6 — with no code
      observable.
- [ ] The hash input excludes exactly three values — `game_version`,
      `saved_at_utc`, `state_hash` — and includes `schema_version` and the whole
      payload; the twin's three digests do not reproduce if a fourth is excluded
      (§3, §4).
- [ ] The snapshot is taken once per request, at an eligible tick, and never
      mid-choreography (AC-SAV-10/11, V-SAV-05); its **gating** bound is
      ≤ ~150 elements, with the 0.5 ms wall-clock figure kept as AC-SAV-10's
      **non-gating probe**.
- [ ] The queue's bound holds: `t_write ≤ t_req + N_max`; an unreadable
      publication fails with `SAVE_FAILED_FREEZE_UNAVAILABLE` (AC-SAV-11).
- [ ] The normalization pass runs below the hash, preserves absence, is idempotent,
      refuses a non-integral number as `REFUSE_FLOAT` and an integral number at a
      non-integer key as `REFUSE_TYPE` (§6a's precedence) (AC-SAV-25, V-SAV-09).
- [ ] The migration chain is contiguous, pure, and forward-only; a namespace's
      `migration_step` has its paired `MIGRATIONS[k−1]`; the rename idiom preserves
      the value; a `v0` file is refused at the gate (AC-SAV-16, V-SAV-02/08).
- [ ] All eleven `REFUSE_*` codes have a refusal fixture (AC-SAV-17) and all six
      `SAVE_FAILED_*` codes have an injected-failure fixture (AC-SAV-09/11/23);
      the file's bytes are identical after every refusal.
- [ ] The absent-key matrix holds: three arrays `[]`, `truth_flags` `{}` with every
      flag unset, the absent epoch refuses (AC-SAV-19).
- [ ] The epoch guard sits upstream of SYS-10; out-of-range never reaches it; state
      (d) is restored as-is (AC-SAV-20).
- [ ] `restore_complete` precedes `load_complete` in every case (AC-SAV-20).
- [ ] No persistence module calls a UI API; every path string comes from the one
      helper; every write goes through temp+rename (AC-SAV-26).

**Story gate (the first SYS-03 implementation story).**

- [ ] The engine half runs the 34 fixtures in-engine, asserts `TYPE_INT` after the
      normalization pass on a real `JSON.parse_string` result, and reproduces
      F-SAV-01's three recorded digests (the **engine-path twin**; AC-SAV-24 is
      explicitly labelled "reference twin only", so the engine half is this story's
      own obligation — named in §12 and in the report's carried list).
- [ ] Every `PROBE-PENDING` item in §13 has a verdict; zero remain open.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|---|---|---|---|
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-001 — the five `world` families verbatim | The `world` namespace is copied by key and shape; the canonicalizer sorts set-arrays only, never a pair's inner order (§3) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-002/003 — store sources, derive targets; the MetSys write-only adapter | No derived key exists in the schema; the adapter writes the Dictionary from the sources after restore, before `restore_complete` (§2, §6) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-004 — the namespace registry (v1 = `world`; `cache` registered-but-absent) | `register_namespace(owner, shape, migration_step)` + the `migration_step`↔`MIGRATIONS` composition rule; the version-aware payload allowlist (§6); the boot's owner+reader check (§3, §6, §7) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-005/006 — no transients; no floats | The schema type table admits `int|String|bool|Array|Dictionary` only; the normalization pass refuses a non-integral number (§6) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-007 — SYS-03 never writes a source at runtime | The runtime write ban from `restore_complete`; `TruthPort` is read-only; the port spy (AC-SAV-07) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-008/009 — the envelope; the canonical serialization | The fixed envelope order; the five canon rules; `game_version`/`saved_at_utc` outside the hash (§3) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-010 — the atomic write's six steps | The worker's six steps with the boolean-return discipline and the step-6 rollback (§5) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-011/016 — the slot model; the platform path policy | `SLOT_IDS`; the platform event set; the one `save_path()` helper; `user://saves/` (§10) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-012/014 — the snapshot; the worker thread and the shutdown path | The synchronous bounded **copy** (bytes off-thread, TR-SAV-012 verbatim); one `Thread`, the per-slot cancellable one-deep queue, the tick-boundary drain, the close-save's three guards (§5, §8) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-013 — the E4 freeze queue | The `FreezePort` predicate, `t_write`, coalescing, the `N_max` bound, the bounded-wait failure (§9) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-015 — the boot sweep and `.bak` promotion | The three-step sweep order, before any load (§11) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-017 — the telemetry | The GDD's 13-record set is consumed unchanged (this ADR adds **no** record); the records are emitted by the core and drained at the tick boundary (§5, §12); the rate limit is a config read |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-018/026 — the load order; the number-normalization pass | The nine steps; the pass below the hash; absence preserved; the envelope's version normalized too (§6) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-019 — `schema_version` and the migration table | `register_migration()`; contiguity boot check; one-step purity; the rename idiom; the synthetic harness (§7) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-020/021 — the refusal codes; the `.bak` fallback | The eleven codes as a stable API; the recovery-then-`OK` rule; the schema-ahead no-fallback rule (§6, §11) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-022 — the refusal path's ownership | SYS-03 publishes `load_result`; SYS-05 flows; SYS-24 renders; no UI call from the module (§6) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-023/024 — the absent-key defaults; the reconciliation handoff | Defaults at restore, after the hash; the epoch guard upstream of SYS-10; `restore_complete` before `load_complete` (§6, §8) |
| `design/gdd/save-serialization.md` | SYS-03 | TR-SAV-025 — the load's atomicity and budget | The staging dict + one swap; synchronous ≤ 2 KB; ≤ 1 ms dev assert (§6) |
| `design/gdd/save-serialization.md` | SYS-03 | AC-SAV-01…26 (26: 22 GUT · 2 LINT · 2 DEVICE; smoke 24) | The twin's 34 fixtures + the port spy + the static audits + the device ACs (§12, §13) |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-036 — bindings are device-local, never in a slot | No `controls` key exists in the schema; V-SAV-07's static audit (§3) |
| `design/gdd/dual-reality-state.md` | SYS-09 | TR-DR-015 / E4 — the save-during-freeze law | The queue's predicate and `t_write`; the post-flip capture by construction (§9) |
| `design/gdd/world-mutation-epochs.md` | SYS-10 | TR-WME-006 / F-WME-01 — the reconciliation contract | No pending-flip field; the epoch guard upstream; state (d) restored as-is; no schema bump (§6, §7) |
| `docs/architecture/adr-0001-input-architecture.md` | ADR-0001 | §3 freeze; §5 tick boundary | The queue's window and the completion drain consume both (§5, §9) |

**Counts consumed, not re-derived:** 26 TR-SAV · 4 F-SAV · 9 V-SAV · 26 ACs
(22 GUT + 2 LINT + 2 DEVICE + 0 PLAYTEST; smoke 24) · 2 knobs · 11 OQs (7
resolved, 4 carried: OQ-SAV-7/8/10/11). This ADR adds **no** TR, **no** formula and
**no** AC — it is a decision record, not a second design.

**V-invariant coverage** (all nine carried, none re-minted): V-SAV-01/04/07 by
AC-SAV-04/26's audits; V-SAV-02/08 by §7's boot checks; V-SAV-03/05 by
AC-SAV-05/07; V-SAV-06 by AC-SAV-20's no-clamp refusal; V-SAV-09 by AC-SAV-25 and
§6a's precedence.

## Related

- **GDD**: `design/gdd/save-serialization.md` — the laws, the formulas (F-SAV-01…04),
  the nine V-invariants, the 26 ACs, the twin's gate record.
- **Review log**: `design/gdd/reviews/sys03-save-serialization-review-log.md` — the
  authoring gate trail (CD APPROVED · 21 blockers repaired · spot-check #1 FAIL →
  #2 PASS · micro-check PASS).
- **Twin**: `tests/save-twin/save_twin.mjs` — 34/34 PASS (2026-11-14, re-run
  2026-11-15); the story-gated engine half is named in §12.
- **ADR-0001**: `docs/architecture/adr-0001-input-architecture.md` — §3 (freeze),
  §5 (tick boundary), and the probe-register pattern this ADR's §13 follows.
- **ADR-0003**: `docs/architecture/adr-0003-audio-core.md` — consumes SYS-05's
  `load_complete` (its `restored_epoch` payload) and SYS-03's ordering guarantee
  (`restore_complete` strictly before `load_complete`); see its §12 and obligation
  O-AUD-1.
- **Registry**: `save_contract`, `save_roundtrip_twin`, `epoch_mutation_reconciliation`
  (all `status: active`).
- **Carried**: **CR-SAV-01** — the close-save exit path's frozen-text reconciliation,
  in **four** clauses: AC-SAV-23's clause 1 gains "the close-save's commit that
  completes — including after `SAVE_JOIN_TIMEOUT_MS` — restores the suspension
  snapshot; where the commit is abandoned before its rename, interrupted before step
  5, or fails on the exit path, the fallback applies"; its clause (b) gains the
  matching "only when"; TR-SAV-014's "joined at shutdown" gains "…except on the
  abandonment path"; and clause (c)'s code-assertion is scoped to a process that
  survives to observe it (§5b). Filed here and batched for the user with
  CR-AUD-03/04; it changes no mechanism in this ADR.
