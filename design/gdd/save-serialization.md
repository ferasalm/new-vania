# Save & Serialization

> **Status**: **APPROVED (2026-11-14 — lane SYS-03).** Gate trail: the authoring gate — the **real-file round-trip twin, 32/32 PASS** (`tests/save-twin/save_twin.mjs`; the format-contract half, the engine half story-gated — OQ-SAV-1 (a)) · **CD-GDD-ALIGN APPROVED** (0 blockers, 7 recommendations applied) · the three-seat review **NEEDS REVISION** (creative 1 + technical 8 + QA 12) → all 21 blockers repaired in-session → **qa-lead spot-check #1 FAIL** (6 bookkeeping defects) → all repaired → **spot-check #2 PASS** → **final micro-check PASS** (zero blockers; the document is not reopened). Review record: `design/gdd/reviews/sys03-save-serialization-review-log.md`. Counts: **26 TR-SAV / 4 F-SAV / 9 V-SAV / 26 ACs (22 GUT + 2 LINT + 2 DEVICE + 0 PLAYTEST; smoke 24)**. The engine-path twin + the Save & Serialization ADR are the two named story-gated obligations.
> **Author**: lead-programmer + systems-designer (lane SYS-03, authoring session)
> **Last Updated**: 2026-11-14
> **Implements Pillar**: "One World, Two Truths" — the persistence half: the world's truth outlives the session, and the file is a record of it, never a repair of it.
> **Contracts**: SYS-02 `design/gdd/room-world-structure.md` (APPROVED 2026-11-13) — **the five source families consumed verbatim (TR-RWS-025)**: `doors_opened` · `truth_flags` · `truth_epoch` · `memories_collected` · `cells_discovered`; store sources, derive targets; MetSys's save Dictionary is a **written derived target**, never an independent path; room-local transients are never sources (V-RWS-15). SYS-09 `design/gdd/dual-reality-state.md` (landed 2026-11-14) — **the E4 save-policy law consumed verbatim (TR-DR-015 + the E1–E7 edge table)**: in-window saves queue to the first unfrozen tick and capture the post-flip state; a mid-choreography snapshot is never written; a deferral-gap save persists `{epoch A, flag set}`. SYS-10 `design/gdd/world-mutation-epochs.md` (APPROVED 2026-11-14) — **the reconciliation contract consumed verbatim (TR-WME-006 + F-WME-01)**: no pending-flip field, the condition derived at load, absent-key-unset, out-of-range epochs hand off to SYS-03's refusal path, SYS-10 adds nothing to the schema. SYS-01 `design/gdd/input-control-mapping.md` (APPROVED 2026-11-12) — TR-INP-036's explicit non-dependency: bindings persist device-local to `user://controls.cfg`, **never inside a save slot**. ADR-0001 (Accepted 2026-11-12) — §5's tick-boundary pipeline (the snapshot lands on a tick) and §3's freeze law (the E4 queue's window). Registry: `dual_truth_model`, `flip_trigger_contract`, `epoch_mutation_reconciliation` (all `status: active`).

## Overview

Save & Serialization is the game's **single persistence boundary**: one schema, one file format, one write path, one load path, and one refusal path. Every persistent system in the project reads or writes through it, and none of them owns a second one. It is Foundation (design order #11) with **no upstream authoring dependencies** — and it is the project's named bottleneck: SYS-05, SYS-10, SYS-15, SYS-20 and SYS-25 all wait on this contract.

**What it owns.** The envelope (`schema_version` + the migration chain + the integrity hash), the serialization of SYS-02's five `world` source families **verbatim** (it never renames, retypes, or re-derives them), the atomic write (temp + rename, a backup per slot), the slot model and the autosave/manual split, the **save-during-freeze queue** (E4's law: a request inside the flip window is held to the first unfrozen tick, so the snapshot captures the post-flip state by construction), the **load reconciliation handoff** to SYS-10 (restore the sources, guard the epoch's range, publish `restore_complete` strictly before SYS-05's `load_complete`), the **corrupted-save refusal path** (named codes, never a silent clamp, never a repair write), and the persistence telemetry.

**What it does not own.** The truth (SYS-02's model; SYS-10's one τ0 store), the flip (SYS-09's sequencer, SYS-10's write), the cache fiction and the designation counter (SYS-15's `cache` namespace), the memories' content (SYS-20 reads `memories_collected`), the map's policy (SYS-25 reads `cells_discovered`), the bindings (SYS-01, device-local by law), and every player-facing surface (the "MEMORY CACHED" print and the save indicator are SYS-15/SYS-24's presentations of SYS-03's completion record).

**The one-line contract.** *Store sources, derive targets — and the file is evidence.* A save contains only the facts no other fact can reconstruct; everything else (border states, zone-gate openings, materials, reachability) is re-derived at load from those facts. The serializer never invents state, never repairs it, and never guesses: an absent key reads as its conservative default, an out-of-range value is refused loudly, and a newer-than-known schema is refused rather than degraded. The world you return to is the world you left — or the game tells you, by name, that it cannot prove that.

**MVP posture (the pinned decisions, 2026-11-14).** Canonical JSON + SHA-256 (OQ-SAV-3); **1 autosave slot + 1 manual slot**, the slot count a registered constant rather than a knob (OQ-SAV-2); **no autosave timer** — the autosave writes on the cache station's ack and on the app's close request (OQ-SAV-4); one dedicated worker thread with a one-deep queue (OQ-SAV-9); forward-only schema at `schema_version` 1 with zero registered migrations (the machinery ships on day one; the fixtures prove it with test-only synthetic versions); no encryption and no anti-cheat (the security audit may request it later — this GDD records the abstention); the write never blocks the game thread; the snapshot is bounded constant work and therefore **does not join the gameplay-tick envelope** (the SYS-02/SYS-09/SYS-10 not-join precedent — SYS-03 prices event budgets instead).

→ *Implementation patterns (the writer's thread shape, the file's byte layout, the migration table's registration API) are ADR raw material for the planned **Save & Serialization ADR**; this GDD stays at the behavior level.*

## Player Fantasy

### The named fantasy — The House Remembers You Exactly

*"You come back, and nothing has moved."* The door you opened is open. The log you read is read. The world that turned while you were away is still turned — and it turned **because** you left it mid-turn, not despite it. The save is not a checkpoint and not a rewind; it is a **record**, and the house keeps it perfectly. Nothing in this game ever says "your progress has been saved" in a menu voice; the only voice is the terminal's print, and the only promise is that what it wrote is what you get.

The fantasy has a colder edge, and SYS-03 is what makes it true rather than decorative: a save is a **copy of a state**, and the copy is exact. The game's horror — that she is a reconstruction, that what wakes at the cache is a version of her — is only credible if the machinery underneath is honest to the bit. A save system that quietly clamped a value or repaired a contradiction would be the first lie the game tells, and it would be told in the one channel the player is meant to trust without thinking.

### Anchor moments

1. **The print.** "MEMORY CACHED" appears, and the world is safe. The player never learns a serializer exists — they learn a terminal does. (The print is SYS-15's presentation of SYS-03's `save_completed` record; SYS-03 owns the record, not the words.)
2. **The return.** A player quits mid-zone and comes back to a world that is *exactly* as left: the door's flag set, the log's flag set, the epoch still B, the discovered cells still discovered, the memories still taken. Nothing is re-derived from a guess, and nothing is missing.
3. **The pending turn.** A player saves in the gap between the log's close and the flip's raise — the world still A, the trigger already set. They quit. They return. The world turns under them at the first playable tick, exactly as it would have. The save did not freeze the moment; it preserved the **pending** truth, and the flip completed in the new session as the same logical flip.
4. **The refusal.** A file is damaged, or was written by a build that knows a newer schema. The game says so — by name — and does not touch the file. The house does not lie about what it remembers, and it does not "fix" a memory to make it loadable.

### The honesty clause

**The save never invents, never repairs, never clamps, never guesses.** Five clauses, each a test:

- **Absent is unset.** A family key missing from a restored save reads as its conservative default (`[]`, `{}`, or a false flag) — never as `true`, never as a guess. The one exception is `truth_epoch`: the truth is not defaultable, so its absence is a refusal, not a zero.
- **Out of range is refused.** An epoch outside `[0, max_epoch]` is never clamped into range; clamping is a repair write, and a repair write is the system lying about the past.
- **A contradiction is reported, not resolved.** The impossible combination (epoch 1 with the trigger flag unset) is SYS-10's integrity violation to report and SYS-03's to restore as-is; the save stays playable and the truth stands. SYS-03 does not "fix" it into consistency.
- **A newer schema is not degraded.** A file whose `schema_version` exceeds the build's is refused; the file is preserved byte-identical and the slot is read-only for the session. There is no downgrade writer, ever.
- **A failed write is not a silent success.** The write is temp + rename; a save that did not land is reported as failed with a code, and the previous good file is still the previous good file.

### Language law

- **Record**, never *checkpoint* — a checkpoint implies a place to return to; this system has no rewind.
- **Restore**, never *rewind* — the state is reconstructed forward from facts, not rolled back.
- **Refuse**, never *repair* — the refusal path is a first-class outcome with named codes, not an error handler.
- **Derive**, never *cache* — the derived targets (border states, gate openings, materials, MetSys's Dictionary) are recomputed at load; nothing derived is ever stored.
- **Slot** is the file; **cache station** is the fiction (SYS-15's noun). SYS-03 never speaks of "sanctuaries" and SYS-15 never speaks of "slots" to the player.

### Success signature

The player never thinks about saving, and QA can prove the round-trip **bit-exactly**: a written state, closed, reloaded from disk, and hashed back to itself. The twin's four fixtures (pre-flip, deferral-gap, post-flip, corrupted) are the proof, and their verdict is part of this GDD's gate record. A corrupted file produces a **named refusal**, never a silent reset to a new game.

## Detailed Design

### Core Rules

#### C1 · The source contract

**TR-SAV-001 — The five `world` families, consumed verbatim.** The save's `world` namespace contains exactly SYS-02's five families, with SYS-02's names and SYS-02's shapes. SYS-03 renames nothing, retypes nothing, and reorders nothing semantically (the family arrays are **sets**; canonical order is the hash's business, not the schema's).

| Family | Shape | Domain | Bound (SYS-02's registries) | Writer (not SYS-03) |
|---|---|---|---|---|
| `doors_opened` | `[border_id…]` | the ack-set door ids | ≤ 128 (the border registry) | SYS-02, at the door's ack |
| `truth_flags` | `{name: bool…}` | the registered truth table; **one flag at MVP** (`sanctum_log_read`) | 1 | SYS-02, at the Reading's close |
| `truth_epoch` | `int` | `[0, max_epoch]`; `max_epoch` 1 at MVP; monotone non-decreasing | 1 value | SYS-10's one τ0 store |
| `memories_collected` | `[id…]` | the taken memory ids | ≤ 4 | SYS-02, at the memory's ack |
| `cells_discovered` | `[cell_coord…]` | MetSys cell coords (one room = one cell) | ≤ 6 | SYS-02, at the discovery |

*Test: the source-list fixture (all five round-trip — AC-SAV-01); the shape audit (no rename, no retype — AC-SAV-02).*

**TR-SAV-002 — Store sources, derive targets.** The save stores **only** the five families (plus registered namespaces). Every derived quantity is recomputed at load. The derived-target table is the completeness proof:

| Derived target | Derived from | Owner of the derivation | Stored? |
|---|---|---|---|
| border states (LOCKED / OPEN) | `doors_opened` + the room data's authored default | SYS-02 | **No** |
| zone-gate openings | `truth_epoch` + the mutation registry (`gate_open = epoch ≥ to_epoch` — F-RWS-04) | SYS-02 | **No** |
| room materials | `truth_epoch` + `epoch_pin` + the palette map | SYS-09 | **No** |
| M4's reachability | `truth_epoch` + `INTERACT_EXPOSE` | SYS-02 / SYS-10 | **No** |
| MetSys's save Dictionary | `cells_discovered` + `doors_opened` + `memories_collected` (the stored object ids) | **SYS-03's adapter (write-only)** | **No** |
| the memories counter | `memories_collected` | SYS-20 | **No** |
| the pause room-grid | `cells_discovered` | SYS-25 | **No** |

*Test: the derivation fixture — the border and gate states re-derive from the epoch + the door ids with the save containing no such key (AC-SAV-02); the static grep for the seven names in the schema module (V-SAV-03).*

**TR-SAV-003 — The MetSys adapter's write-only boundary.** MetSys's own save Dictionary is a **derived target**. The adapter writes the discovery set and the **stored object ids** into MetSys's Dictionary **after** the sources are restored and **before** `restore_complete` publishes. The stored object ids derive from `memories_collected` through the registered **1:1 map** (memory id ≡ MetSys storable id; an unmapped id is a boot lint failure; absent → empty). The Dictionary is **never read as truth**: a Dictionary that disagrees with the restored sources is overwritten, and one telemetry record is emitted (a diagnostic, not a repair). The addon's own save path is called by the adapter only; nothing else in the project may invoke it.

*Test: the adapter audit (the Dictionary is written from the sources; a disagreeing Dictionary is overwritten + one telemetry record; the addon's save path has exactly one call site — AC-SAV-03).*

**TR-SAV-004 — The namespace registry.** The payload is a set of **namespaces**, each with exactly one owner and a registered shape:

- **`world`** — SYS-02's five families. **A sixth key inside `world` is a contract revision** (TR-RWS-025), not an extension; the boot lint V-SAV-01 fails on it.
- **`cache`** — SYS-15's (the designation counter + cache activation). **Registered in the registry, ABSENT from the v1 payload.** "Registered" means the mechanism knows the namespace, its owner, and its reader; "absent" means a v1 file has no `cache` key and a v1 reader defaults it to the new-game state. **The v1→v2 bump adds the key** at SYS-15's authoring — the bump is the shape change, which is why it must be a bump and not a silent write.
- A future namespace follows the same rule: one named owner, a declared shape, a registered migration step, at least one reader.

SYS-03 publishes `register_namespace(owner, shape, migration_step)`; the boot validates that every registered namespace has an owner and at least one reader (V-SAV-08). The payload-key allowlist is **version-aware**: at v1 it is `{world}` — a v1 file carrying a `cache` key is `REFUSE_UNKNOWN_KEY` (the writer claimed v1 and wrote a v2 shape).

*Test: a sixth `world` key fails the boot (AC-SAV-04); an ownerless namespace fails the boot; the `cache` namespace exists and reads empty (AC-SAV-04).*

**TR-SAV-005 — No room-local transients.** Enemy state, hazard state, room-script state, the border ARC, the flip's choreography state, the freeze state, and the tell state are **never** save sources (V-RWS-15 consumed; TR-DR-007's "tells are stateless" consumed; TR-DR-014's not-do list consumed). The static audit greps the schema module for those symbol families.

*Test: the transient audit — zero hits (AC-SAV-05).*

**TR-SAV-006 — No floats in the save.** The payload's value domain is `int | string | bool | array | dict`. A float is a schema violation: the dev boot assert fails, and a file containing one is refused (`REFUSE_FLOAT`). *Why:* a text format cannot round-trip a float canonically, and no persistent quantity in this game is fractional. A future system that needs one stores an integer in a named unit (ms, not seconds) and the unit is part of the key's name.

*Test: a float in the payload → `REFUSE_FLOAT` (AC-SAV-06); the canonicalizer throws on a non-integer number (the twin).*

**TR-SAV-007 — The source writers are not SYS-03's.** SYS-03 **serializes** the store; it never writes a source at runtime. The writers are named in TR-SAV-001's table (SYS-02's acks and the Reading's close; SYS-10's one τ0 store). SYS-03's only write to the store is the **restore itself** — the store's initialization at load, which is complete before `restore_complete` publishes. The runtime write ban holds from `restore_complete` onward.

*Test: the write-ban grep — zero SYS-03 write calls to a source outside the restore path (AC-SAV-07); the port spy (the AC-DR-18 pattern).*

#### C2 · The write path

**TR-SAV-008 — The envelope.** The file is one JSON object with a fixed key order:

```
{"schema_version":1,
 "game_version":"0.1.0",
 "saved_at_utc":"2026-11-14T12:00:00Z",
 "state_hash":"<64 lowercase hex>",
 "payload":{"world":{…}}}
```

- `schema_version` — int ≥ 1; **the only gate**; **hashed** (it is part of the record, not metadata — TR-SAV-009).
- `state_hash` — SHA-256 over `{schema_version, payload}` (F-SAV-01).
- `game_version`, `saved_at_utc` — **informational**; never gate anything; **not hashed** (a re-save of an unchanged state hashes identically).
- `payload` — the namespace dict; **at v1 it contains `world` only** (the `cache` namespace is registered but absent — TR-SAV-004).

*Test: the version is hashed — a downgrade edit (`99 → 1`) yields `REFUSE_HASH_MISMATCH`, not a gate bypass (AC-SAV-22).*

**TR-SAV-009 — The canonical serialization.** The canonical form is both the hash's input and the file's payload bytes:

1. Object keys sorted by byte order, at every level.
2. **Only the three outer family arrays are sets**, sorted by their element's canonical string (`doors_opened`, `memories_collected`, `cells_discovered`). **A coordinate pair's inner order is data** — sorting `[[1,0]]` to `[[0,1]]` would silently turn one discovered cell into another (the twin's `CANON-pair`).
3. Integers in decimal, no leading zeros, no exponent form. **No floats** (TR-SAV-006).
4. Strings JSON-escaped per the standard; booleans `true`/`false`; no `null` (an absent key is the only "nothing").
5. No insignificant whitespace inside the payload.

*Why it matters:* the canonical form makes the hash independent of insertion order and of the order the game happened to collect facts in, and it makes a re-save of an unchanged state byte-identical in its payload.

*Test: key-order and array-order independence — two payloads with shuffled orders hash identically (AC-SAV-08; the twin's `CANON-order`).*

**TR-SAV-010 — The atomic write.** Six steps, on the worker thread:

1. Serialize the snapshot to bytes.
2. Write the bytes to `<slot>.tmp`; flush; close.
3. **Verify the temp's own hash** by re-reading it (cheap at ≤ 2 KB; catches a short write before the rotation).
4. If `<slot>.sav` exists, rename it to `<slot>.bak` (replacing an older `.bak`).
5. Rename `<slot>.tmp` → `<slot>.sav`. **This rename is the commit point.**
6. Re-read `<slot>.sav`, verify its hash, and emit `save_completed` (or `save_failed(code)`).

**A step-6 failure is post-commit.** The new bytes are at `<slot>.sav` and the previous generation is at `<slot>.bak`; there is **no rollback** — the writer never repairs. The next load's integrity path decides: valid new bytes load (the new state), invalid ones fall to the `.bak` (the previous state). A step-3 failure is pre-commit: the previous `.sav` is untouched.

A failure at steps 1–3 leaves the previous `.sav` untouched. A failure at step 5 leaves `<slot>.sav` missing and `<slot>.bak` present — **the boot sweep promotes the `.bak`** (TR-SAV-015). A torn file is unreachable by construction: the file that exists is always a file that was fully written and verified.

**The file-level-recovery distinction (a law, stated once):** promoting a `.bak` restores the *last good bytes*; it invents no state and is therefore permitted. A **state-level** repair (clamping, defaulting a contradiction, re-deriving a stored value) is forbidden everywhere.

*Test: a fault injected at each of the six steps — the previous `.sav` intact or the `.bak` recovers; never a torn file (AC-SAV-09; the twin's `WRITE-fail`).*

**TR-SAV-011 — The slot model.** Two slots at MVP, registered constants (not knobs):

| Slot id | Written by | Trigger |
|---|---|---|
| `auto` | the game | every cache-station ack (SYS-15's diegetic save) **and** the app's suspension/close event — desktop quit, Android `onStop`, iOS `NOTIFICATION_APPLICATION_PAUSED` (an **event**, never a timer; the ≤ 2 KB write fits the platform's suspension window) |
| `manual_1` | the player | an explicit save action at a cache station |

Each slot has `<slot>.sav` + `<slot>.bak` under `user://saves/`. **No timer-based autosave exists** (OQ-SAV-4); a periodic autosave would be a new cadence knob and a new perf surface, and the cache station already gives the game a diegetic save point. The suspension/close event is the **event** answer to the mobile kill path: on iOS the most common exit is a background-kill, and a station-only trigger would silently lose everything since the last station — which would make the Player Fantasy's anchor 2 platform-conditional. The event set is `{station ack, desktop quit, Android onStop, iOS application-paused}`; adding a fifth is a decision, not a config edit. **The manual slot's near-null decision texture at MVP is intentional** — one station type means `manual_1` and `auto` hold near-identical states, which is safety redundancy, not a choice; the texture arrives when stations multiply (VS). The slot ids are `SLOT_IDS = [&"auto", &"manual_1"]`; adding a third is a code change with a migration review, not a config edit.

*Test: the slot fixture — both slots write, load, and back up independently; the close request writes `auto` (AC-SAV-10, AC-SAV-23).*

**TR-SAV-012 — The snapshot.** The snapshot is taken **synchronously on the game thread at `t_write`**: a deep copy of the `world` namespace plus every registered namespace's current values. Its cost is bounded constant — the arrays are bounded by SYS-02's registries (128 borders, 1 flag, 4 memories, 6 cells), so the copy is ≤ ~150 elements — and the dev assert prices it at **≤ 0.5 ms**. The bytes are produced and written **off-thread** (TR-SAV-014). The snapshot is taken **once per request**; a re-request after a failure is a new request with a new snapshot.

*Test: the snapshot-bound fixture (a maximal store copies in ≤ 0.5 ms — the dev assert); the once-per-request fixture (AC-SAV-10).*

**TR-SAV-013 — The E4 freeze queue (SYS-09's law, SYS-03's implementation).** The law is SYS-09's; the implementation is a **snapshot-timing law**:

- **The request** is an intent record `(slot_id, cause, requested_tick)`. It is not a write.
- **The eligibility predicate:** `writable(t) ≡ flip_sources_active(t) = ∅`, where `flip_sources_active` reads **SYS-29's `FreezeState` publication** — the base `&"truth_flip"` source plus every admitted `&"truth_flip_ext_n"`. This is exactly E2→E6's window.
- **The snapshot tick:** `t_write = min { t ≥ t_req : writable(t) }` (F-SAV-03).
- **Why the post-flip state is captured by construction:** for a **queued** save, the τ0 store precedes E4 and E6 (`freeze_close`) follows E4, so any `t_write` at or after the window's close is strictly after τ0. **No read race exists**, and no "read the epoch twice" defence is needed. (A `t_write` *before* the window is the ordinary pre-flip case — it is before τ0, which is correct.)
- **A mid-choreography snapshot is never written:** the snapshot only runs at an eligible tick; the dev assert `¬flip_sources_active(t_snapshot)` is V-SAV-05.
- **The abort case** (consumed from TR-WME-004): the flip aborts → `freeze_open` fires, E3/E3b/E4 never do, the force-release closes the window at the force-release boundary → the queued save executes at the first unfrozen tick and captures **`{epoch 0, flag set}`** — the deferral-gap state (b).
- **The deferral gap** (before E1): not in the freeze window at all → the save executes at its request tick and captures **`{epoch 0, flag set}`** too. **Same state, different mechanism**; the twin asserts the *state*, never the path.
- **The [E1, E2) gap** (after `flip_begin` at R, before `freeze_open` at τ0): the flag is already set and the epoch is not — the save executes and captures **state (b)**, which is correct (it is *not* a pre-flip state (a) save; the trigger has fired).
- **The unreadable freeze publication** (a boot-order defect): the predicate reads **true** for at most `N_max` ticks, then the request fails with `SAVE_FAILED_FREEZE_UNAVAILABLE` — a bounded wait, never an unbounded hang (F-SAV-03).
- **Queue depth:** one pending request per slot; a second request for the same slot **coalesces** (latest wins, one telemetry record); requests for different slots queue independently. The queue is bounded by the slot count and preallocated.
- **A request during the loading context** is refused at the request (SYS-05's gate); SYS-03 asserts the refusal.

*Test: a request at tick 100 inside a window closing at 118 → `t_write` 118 and the snapshot carries epoch 1; the abort case and the deferral gap both restore as `{0, flag set}` (AC-SAV-11; the twin's `REC-b`).*

**TR-SAV-014 — The worker thread and the shutdown path.** One dedicated `Thread`, created at boot and joined at shutdown; a **one-deep job queue** (the in-flight write plus at most one pending per slot). The completion is a result record drained at the next tick boundary. **The game thread never waits on the worker during gameplay** — a write in flight never blocks a second request (it queues). **The one legal exception:** on the close request the close-save is written **synchronously** (there is no frame to miss; the file is ≤ 2 KB; the dev assert bound is `SAVE_JOIN_TIMEOUT_MS` 250 ms). **The close-save and the freeze:** if `flip_sources_active` is non-empty at the close request, the close-save is **skipped** — a synchronous snapshot there would capture the mid-choreography state that V-SAV-05 and E4 forbid — and the last station autosave is the fallback (one telemetry record). A close-save that cannot land is not a failure the player sees.

*Test: a frame-time probe during a save shows no game-thread stall (AC-SAV-12); the close-save lands on a device (AC-SAV-23).*

**TR-SAV-015 — The boot sweep and the `.bak` promotion.** At boot, per slot: if `<slot>.sav` is missing and `<slot>.bak` exists → **promote the `.bak`** to `.sav` (a file-level recovery, TR-SAV-010's distinction); if `<slot>.tmp` exists → **delete it** (an incomplete write). Both emit a telemetry record (`bak_promoted`, `tmp_swept`). A slot with neither file is `EMPTY` — the first boot, not an error.

*Test: the sweep fixture — the orphaned `.tmp` is deleted; the `.bak` is promoted; the loaded state is the last good one (AC-SAV-13; the twin's `WRITE-fail`).*

**TR-SAV-016 — The platform path policy.** Every save lives under `user://saves/`. No absolute paths, no `res://` writes, no `OS.get_user_data_dir()` string assembly outside the one path helper. Godot maps `user://` per platform (the app's data directory); a reinstall clears it, which is the platform contract, not a bug. Cloud backup follows the platform default at MVP; the exclusion switch is recorded for the release checklist (OQ-SAV-8). A read-only or full storage volume yields the **save-path** failure code `SAVE_FAILED_PERMISSION` / `SAVE_FAILED_DISK_FULL` (the save-failure vocabulary — TR-SAV-020's sibling table): the session runs, the surface reports that saving is unavailable, and the game does not crash. **One vocabulary per path:** `SAVE_FAILED_*` is the write path; `REFUSE_*` is the load path; a read-only volume on load is `REFUSE_UNREADABLE`, on save is `SAVE_FAILED_PERMISSION`.

*Test: the device path probe — the save survives a relaunch on iOS and Android and the file sits under the app's data dir (AC-SAV-14); the read-only fixture (AC-SAV-14).*

**TR-SAV-017 — The telemetry.** The record set (rate-limited on repeats by `SAVE_TELEMETRY_RATE_LIMIT_MS`): `save_requested(slot, cause, tick)` · `save_queued(slot, reason=freeze)` · `save_completed(slot, tick, bytes, hash)` · `save_failed(slot, code)` · `load_started(slot)` · `load_migrated(slot, from, to)` · `load_refused(slot, code)` · `restore_complete(slot, tick)` · `bak_promoted(slot)` · `bak_loaded(slot)` · `tmp_swept(slot)` · `namespace_registered(name, owner)` · `adapter_overwrote(slot)`. **No telemetry record carries a save value** — ids and counts only, never the state itself.

*Test: the telemetry audit — every record fires once per event, the rate limit holds, and no record's payload contains a family value (AC-SAV-12).*

#### C3 · The load path and the schema

**TR-SAV-018 — The load order (nine steps, the order is the law).**

1. **Read** the file (or the `.bak` — TR-SAV-021).
2. **Parse** the envelope. A parse failure is `REFUSE_TRUNCATED`.
3. **Normalize** the numbers against the schema's declared types (TR-SAV-026) — Godot's JSON yields floats, so this is the step that makes the hash computable.
4. **Hash check** over `{schema_version, payload}` — **integrity before interpretation**. A mismatch is `REFUSE_HASH_MISMATCH`; a tampered version is caught here, not at the gate.
5. **Version gate** (F-SAV-02): equal → step 7; older → step 6; newer or invalid → refused.
6. **Migrate** one step at a time (TR-SAV-019).
7. **Post-migration validation**: shape, types, the unknown-key policy, the epoch range.
8. **Restore** into a **staging dict**, then swap it into the store in one call. A failure mid-build leaves the store **untouched**. Then the MetSys adapter writes its Dictionary (TR-SAV-003).
9. **Publish `restore_complete(slot, tick)`** — strictly before SYS-05's `load_complete` (TR-SAV-024).

*Test: the order fixture — a truncated file yields `REFUSE_TRUNCATED` (not `REFUSE_HASH_MISMATCH`); a valid v99 file yields `REFUSE_SCHEMA_AHEAD`; a downgrade edit yields `REFUSE_HASH_MISMATCH` (AC-SAV-15, AC-SAV-22).*

**TR-SAV-019 — `schema_version` and the migration table.**

- `CURRENT_SCHEMA_VERSION = 1` at MVP. `MIGRATIONS = {}` — **zero registered steps**; the machinery ships on day one (TR-RWS-025's "migration from day one") and the fixtures prove it with test-only synthetic versions.
- **Forward-only, one step at a time.** Each `M_n : payload@n → payload@n+1` is a pure function. A chain is `migrate(v) = M_{CURRENT−1} ∘ … ∘ M_v`.
- **Contiguity:** `MIGRATIONS[n]` must exist for every `1 ≤ n < CURRENT`. **A gap fails the boot** (V-SAV-02) — a chain with a hole is not a chain.
- **What bumps the version:** any change to the payload's **shape** — a key added, removed, renamed, or retyped; a namespace registered. A change to a value's **legal range** that leaves the shape intact does **not** bump (it is validated, not migrated).
- **SYS-10 adds nothing → no bump, no migration** (TR-WME-006 verbatim).
- **A migration may add a key only with its conservative default** (absent/unset/empty) — never a guessed value. The absent-key-unset law applies to migrated payloads too.
- **The rename case** (TR-WME-006's "the rename case rides SYS-03's `schema_version` migration"): a rename is `put(new_key, pop(old_key))` — **the value moves; only a genuinely NEW key takes the conservative default.** Losing a set flag to a default would silently cancel the pending flip (TR-SAV-024 (b)) — the exact failure the migration exists to prevent. The twin proves the shape with a test-only `v1 → v2` that renames `sanctum_log_read` → `sanctum_log_consumed` (a hypothetical; **never shipped**).
- **The chain's test domain.** The chain function is exercised **below the gate** by a synthetic `CURRENT = 3` harness (steps 1 and 2 registered); a `v0` file is a **refusal fixture** (AC-SAV-17), never a migration input — F-SAV-02 refuses it before the chain is reachable.

*Test: the two-step chain composes; a contiguity gap fails the boot; the rename preserves the value (AC-SAV-16; the twin's `MIG-*`).*

**TR-SAV-020 — The refusal codes (the closed vocabulary at MVP).**

| Code | Trigger | File preserved | Slot state |
|---|---|---|---|
| `REFUSE_ABSENT` | no file at the slot | n/a | `EMPTY` |
| `REFUSE_UNREADABLE` | IO error / permission | yes | read-only¹ |
| `REFUSE_TRUNCATED` | parse failure | yes | read-only¹ |
| `REFUSE_HASH_MISMATCH` | the computed hash ≠ the envelope's | yes | read-only¹ |
| `REFUSE_SCHEMA_AHEAD` | `schema_version > CURRENT` | yes | **read-only for the session** |
| `REFUSE_SCHEMA_INVALID` | `schema_version < 1` or non-int | yes | read-only¹ |
| `REFUSE_UNKNOWN_KEY` | a key not in the schema at its version | yes | read-only¹ |
| `REFUSE_MISSING_EPOCH` | `truth_epoch` absent | yes | read-only¹ |
| `REFUSE_EPOCH_RANGE` | `truth_epoch ∉ [0, max_epoch]` | yes | read-only¹ |
| `REFUSE_TYPE` | a value's type is wrong | yes | read-only¹ |
| `REFUSE_FLOAT` | a float anywhere | yes | read-only¹ |

¹ **All codes except `REFUSE_ABSENT` and `REFUSE_SCHEMA_AHEAD` are read-only only until the `.bak` recovers the load** (TR-SAV-021) — then the slot returns to `OK`. `REFUSE_SCHEMA_AHEAD` is read-only unconditionally (the `.bak` is never attempted).

`REFUSE_ABSENT` is **not a failure** — it is the first boot. Every other code is a refusal: the file is preserved **byte-identical** and the slot is **read-only for the session**, with **one exception**: when the `.bak` recovers the load (TR-SAV-021), the slot returns to `OK` and may be written again (the recovery is a file-level restore, not a refusal). A refusal is **terminal for the session's slot** — no retry loop, no auto-overwrite.

**The save-failure vocabulary (the write path's sibling — one vocabulary per path).**

| Code | Trigger | The `.sav` after |
|---|---|---|
| `SAVE_FAILED_DISK_FULL` | the temp write fails on space | the previous `.sav`, intact |
| `SAVE_FAILED_PERMISSION` | the storage is read-only / denied | the previous `.sav`, intact |
| `SAVE_FAILED_VERIFY` | the temp's hash (step 3, **pre-commit**) or the read-back's (step 6, **post-commit**) mismatches | step 3 → the previous `.sav`, intact · step 6 → the new `.sav` in place but unverified, the `.bak` holding the previous generation — **the next load's integrity path decides** (the writer never rolls back) |
| `SAVE_FAILED_FREEZE_UNAVAILABLE` | the freeze publication is unreadable past `N_max` | the previous `.sav`, intact |
| `SAVE_FAILED_RENAME` | step 5's rename fails | `.sav` missing, `.bak` present → the boot sweep recovers |
| `SAVE_FAILED_UNKNOWN` | an unclassified IO error | the previous `.sav`, intact |

*Test: the refusal matrix — each code's fixture, and the file's bytes identical after the attempt (AC-SAV-17); the save-failure matrix (AC-SAV-09).*

**TR-SAV-021 — The `.bak` fallback.** On a primary failure other than `REFUSE_ABSENT` and `REFUSE_SCHEMA_AHEAD`, the load retries the `.bak`. If the `.bak` loads, **the verified `.bak` is promoted to `<slot>.sav` before the slot returns to `OK`** (a file-level recovery — the same operation as the boot sweep). Without the promotion the corrupt primary would sit at `.sav` and the next write would rotate it over the good `.bak`, so a failed commit would leave two bad files. The session continues from the recovered state, one telemetry record (`bak_loaded`) is emitted, and the surface reports that the previous save was recovered. If the `.bak` also fails → the refusal (the primary's code is reported; the `.bak`'s code is telemetry). A `REFUSE_SCHEMA_AHEAD` primary does **not** try the `.bak` — the `.bak` is older and would silently downgrade the session, which is exactly the lie the refusal exists to prevent.

*Test: the primary corrupt → the `.bak` loads; both corrupt → the refusal; a schema-ahead primary → no `.bak` attempt (AC-SAV-18).*

**TR-SAV-022 — The refusal path's ownership.** SYS-03 publishes `load_result ∈ {restored, refused(code), absent}` with the slot id and the code; **SYS-05 owns the flow** (what the player may do next); **SYS-24 renders the surface**. SYS-03 never displays anything, never writes a string the player reads, and never decides a navigation. The code strings are a stable API (`REFUSE_*`), not display text.

*Test: the ownership grep — no UI call from the persistence module (AC-SAV-26's audit clause).*

**TR-SAV-023 — The absent-key defaults (the matrix).**

| Key absent | Default | Rationale |
|---|---|---|
| `doors_opened` | `[]` | no doors opened — the new-game default |
| `truth_flags` | `{}` → every registered flag **unset** | the predicate never guesses (F-WME-01) |
| `memories_collected` | `[]` | 0/N |
| `cells_discovered` | `[]` | no cells discovered |
| **`truth_epoch`** | **refuse** (`REFUSE_MISSING_EPOCH`) | the truth is **not defaultable** — a zero would be a repair write |

*Test: the absent-key matrix — the three arrays default to `[]`, `truth_flags` to `{}` with every registered flag unset, and the absent epoch refuses (AC-SAV-19; the twin's `ABS-defaults`). The defaults are applied at restore, never before the hash (TR-SAV-026 step 4).*

**TR-SAV-024 — The reconciliation handoff (SYS-03's half of TR-WME-006).** Five obligations:

1. **Restore the `world` namespace verbatim** — no rename, no retype, no re-derivation, no repair write.
2. **Guard the epoch's range before SYS-10 is called.** `truth_epoch ∈ [0, max_epoch]`, where `max_epoch` is **SYS-02's config**; the forward-version guard is SYS-03's and sits **upstream of SYS-10 entirely** (TR-WME-006(e)). Out of range → `REFUSE_EPOCH_RANGE`. **Never clamped.**
3. **Publish `restore_complete` strictly before SYS-05's `load_complete`** — the ordering that lets SYS-10 publish its flip request before the load-complete gate, so the re-fire never fires inside the loading context.
4. **Never write a pending-flip field.** The schema has no such key; a file carrying one is `REFUSE_UNKNOWN_KEY` (TR-SAV-020).
5. **Do not resolve the impossible combination.** Epoch 1 ∧ flag unset is restored **as-is**: SYS-10's dev assert + one telemetry record, truth B stands, the save stays playable. SYS-03 neither refuses it nor repairs it.

**The five per-state outcomes:**

| State | Restored | SYS-03 does | SYS-10 does |
|---|---|---|---|
| (a) epoch 0 ∧ flag unset | ordinary pre-threshold | restore; `restore_complete` | no request, no flip, no telemetry |
| (b) epoch 0 ∧ flag set | **deferral-gap** | restore; `restore_complete` | pending derives true; the request publishes before `load_complete`; the choreography re-fires at the first post-load tick; replay hash ≡ the fresh flip |
| (c) epoch 1 ∧ flag set | ordinary post-flip | restore; `restore_complete` | no re-fire; truth B renders from the epoch |
| (d) epoch 1 ∧ flag unset | integrity violation | **restore as-is** (no repair, no clamp, no refusal) | dev assert + telemetry; truth B stands; playable |
| (e) epoch out of range | — | **refuse** before SYS-10 is called | never reached |

*Test: the four restorable states + the refusal; `restore_complete` precedes `load_complete`; the out-of-range case never reaches SYS-10 (AC-SAV-20; the twin's `REC-*`).*

**TR-SAV-025 — The load's atomicity and its budget.** The restore builds a **staging dict** and swaps it into the store in one call; a failure at any point leaves the live store **untouched** (no half-restored world). The load runs **synchronously inside the loading context** (SYS-05's) — no worker thread is needed for a ≤ 2 KB read. SYS-03's own restore budget is **≤ 1 ms** (dev assert); SYS-10's reconcile budget (≤ 1 ms, TR-WME-011) is consumed as the handoff's bound.

*Test: a failure injected mid-restore leaves the store untouched (AC-SAV-21); the restore-budget dev assert fires on an injected slow fixture.*

**TR-SAV-026 — The number-normalization pass (the engine's JSON number model).** Godot 4's `JSON` class parses **every** JSON number as a float. A legitimately written `truth_epoch: 0` therefore re-parses as `0.0`, and `canon` — which refuses floats (TR-SAV-006) — could not recompute the hash: **every legitimate save would refuse at load.** The pass sits **between the parse and the canonicalization** (F-SAV-04 rows 0–2):

1. Walk the parsed payload against the **schema's declared types** — not heuristically — **and apply the same integral check to the envelope's `schema_version`** (it is parsed as a float too).
2. For each key declared `int`: accept the parsed number iff it is **integral** (`x = floor(x)`) and inside its declared range; **coerce it to int**. A non-integral number → `REFUSE_FLOAT`.
3. For each key declared non-integer (string/bool/array/dict): a number → `REFUSE_TYPE`.
4. **The absence is preserved through the hash.** A declared key absent stays absent in the normalized payload — materializing the defaults there would change the hash input and turn a valid sparse file into `REFUSE_HASH_MISMATCH`. **The defaults are applied at restore, after the hash** (TR-SAV-023). An undeclared key → `REFUSE_UNKNOWN_KEY` (the shape check); a `truth_flags` **name** not in the registered table → `REFUSE_UNKNOWN_KEY` (an unregistered flag is a schema violation, not a value).

**Why this is not a repair write:** it converts the engine's *representation* into the schema's *declared type*; it changes no value. A value the schema cannot represent exactly (a fraction) refuses. The pass is idempotent and total over the schema.

**The engine-half fixture (story-gated):** the engine twin must feed a real `JSON.parse_string` result through the pass and assert `typeof(value) == TYPE_INT` afterwards **and** the same hash as the reference twin. The reference twin cannot simulate the float-typed parse (JavaScript has one number type) — it tests the pass's refusal branch (a non-integral number) and the coercion's identity on integral values. **Engine-reference obligation:** `docs/engine-reference/godot/` records the JSON number model (the knowledge gap is real — the LLM cutoff precedes 4.4).

*Test: the normalization fixture — a non-integral number refuses, an integral value normalizes identically (AC-SAV-25); the engine fixture at the first story.*

### States and Transitions

Two machines and one slot-state record. The save machine is a **request pipeline**; the load machine is a **validation pipeline**; neither is a runtime mode of the game.

**The save-request machine.**

| State | Entry | Behavior | Exit |
|---|---|---|---|
| **IDLE** | default; after a completion | none | a request → **REQUESTED** |
| **REQUESTED** | the intent record | the context gate + the eligibility test (TR-SAV-013) | loading context → **REJECTED** · eligible → **SNAPSHOTTED** · not eligible → **QUEUED** |
| **REJECTED** | a request inside the loading context | one telemetry record; no snapshot | **IDLE** |
| **QUEUED** | `flip_sources_active` | wait; coalesce a same-slot request (latest wins) | eligible → **SNAPSHOTTED** |
| **SNAPSHOTTED** | `t_write` | the deep copy (TR-SAV-012); hand the bytes job to the worker | the worker accepts → **WRITING** |
| **WRITING** | the worker | serialize → hash → temp → verify → rotate → rename → verify | ok → **VERIFIED** · any failure → **FAILED** |
| **VERIFIED** | the read-back hash matches | emit `save_completed` | **IDLE** |
| **FAILED** | any step's failure | emit `save_failed(code)`; the previous `.sav` intact | **IDLE** |

**The load machine.**

| State | Entry | Behavior | Exit |
|---|---|---|---|
| **CLOSED** | default | none | a load request → **OPEN** |
| **OPEN** | the request | read the `.sav` (or the `.bak`) | bytes → **VALIDATE** · none → **REFUSED(ABSENT)** |
| **VALIDATE** | the bytes | parse + normalize + hash (TR-SAV-018 steps 2–4) | ok → **GATE** · fail → **REFUSED(code)** |
| **GATE** | the envelope | the version decision (F-SAV-02) | equal → **RESTORE** · older → **MIGRATE** · newer/invalid → **REFUSED** |
| **MIGRATE** | `v < CURRENT` | the chain (TR-SAV-019) | ok → **RESTORE** · fail → **REFUSED** |
| **RESTORE** | the validated payload | the staging build (post-migration validation on the migrated path) + the swap + the adapter write | ok → **RECONCILE** · fail → **REFUSED** |
| **RECONCILE** | `restore_complete` published | wait for SYS-10's reconcile and SYS-05's `load_complete` | `load_complete` → **CLOSED** |
| **REFUSED** | a code | preserve the file; publish `load_result`; the slot read-only | **CLOSED** |

**The slot-state record.** The edges are total: `EMPTY → OK` (the first successful write) · `OK → BAK_ONLY` (step 5's rename failed: `.sav` missing, `.bak` present) · `BAK_ONLY → OK` (the boot sweep promotes the `.bak`, or the next successful write) · `OK | BAK_ONLY → REFUSED_READ_ONLY` **only when both the primary and the `.bak` fail the load** — the terminal refusal. `EMPTY` is the first boot; `BAK_ONLY` is never observable by a *reader* (the sweep promotes it before the load), but it is observable by the **boot sweep** and by the slot-list metadata between the write failure and the next boot, which is why it is published.

**Transition laws.**

1. **One write in flight per slot; one load at a time globally.** A load never runs concurrently with a write to the same slot.
2. **The snapshot is taken once per request.** A re-request after a failure is a new request with a new snapshot.
3. **A refusal is terminal for the session's slot** — no retry loop, no auto-overwrite.
4. **`restore_complete` precedes `load_complete`.** The ordering is the reconciliation contract's load-bearing clause.
5. **The runtime write ban holds from `restore_complete` onward** (TR-SAV-007).
6. **The queue's bound is the proof of liveness:** `t_write ≤ t_req + N_max`, `N_max` = SYS-09's published worst-case hold (the base + the two admitted extension spans — F-SAV-03). A queue that cannot bound its wait is a hang; this one can, and the unreadable-publication path fails loudly (`SAVE_FAILED_FREEZE_UNAVAILABLE`) rather than waiting forever.

### Interactions with Other Systems

| Boundary | Flow | Contract | Missing-input failure path |
|---|---|---|---|
| **SYS-02 Room & World** | source → serializer (hard, read-only) | The five families (TR-RWS-025) + the ports (`TruthPort`, `MetSysPort`, `TelemetryPort`, `TuningPort`); the adapter's write-only Dictionary boundary (TR-SAV-003) | A family key absent → its conservative default (TR-SAV-023). An unreadable MetSys Dictionary → overwritten from the sources + telemetry; the load never fails on the addon's state. |
| **SYS-09 Dual-Reality** | policy (hard) | E4's law (TR-DR-015) + the E1–E7 edges; the freeze window is read from SYS-29's `FreezeState` | The freeze publication unavailable (a boot-order defect) → the dev assert; the save runs only when the source set is readable and empty (the conservative reading: an unreadable freeze state is treated as frozen). |
| **SYS-10 World Mutation** | handoff (hard) | `restore_complete(sources)` out; the epoch guard upstream; the (a)–(e) outcomes (TR-SAV-024) | An absent trigger flag → unset → pending false. An out-of-range epoch → refused **before** SYS-10 runs. State (d) → restored as-is; SYS-10 reports it. |
| **SYS-29 Juice & Feedback** | read-only service | The `FreezeState` publication (the queue's predicate) | See SYS-09's row — the same conservative reading. |
| **SYS-01 Input** | **none** (explicit non-dependency) | TR-INP-036: bindings persist to `user://controls.cfg`, never in a slot | n/a — the absence is the contract (V-SAV-07). |
| **SYS-05 Game Flow** | coordination (soft) | `load_result`, `save_completed`, `restore_complete` out; the loading context + `load_complete` in; the refusal flow's ownership (TR-SAV-022) | No save present → the `new_game` path (SYS-05's); `REFUSE_ABSENT` is published, not treated as an error. A refused save → SYS-05 routes to the refusal flow with SYS-03's code. |
| **SYS-15 Cache Stations** | namespace (soft) | The `cache` namespace (registered, empty at MVP — TR-SAV-004); `save_completed` for the print | An absent namespace → the conservative default (counter 0, no cache active). The shape is SYS-15's; the mechanism is SYS-03's. |
| **SYS-20 Memory Fragments** | read (soft) | `memories_collected` (SYS-02's family) | Absent → `[]` → 0/N. SYS-20 never writes the family (SYS-02's ack does). |
| **SYS-25 Map / Fog** | read (soft) | `cells_discovered` (SYS-02's family) | Absent → `[]` → the pause grid shows no discovered cells. SYS-25 owns the policy; the facts are SYS-02's. |
| **SYS-24 HUD / UI** | render (soft) | The refusal surface, the load-result surface, the slot-list metadata (TR-SAV-022, §I) | A missing code's display string → the generic "the save could not be read" line; the code is still telemetry. |

**Explicit non-dependencies (runtime):** SYS-06, SYS-07, SYS-08, SYS-11, SYS-12, SYS-13, SYS-14, SYS-18, SYS-19, SYS-21, SYS-22, SYS-23, SYS-26, SYS-27, SYS-28, SYS-30, SYS-31, SYS-32 — no save surface of any kind. **Two named exceptions to watch:** SYS-20 and SYS-29 are *consumers* (the boundary table above), and **SYS-16 (levels 1–5 + the gear layer) and SYS-17 (the Suture + quick slot + loadout) are MVP but not yet authored** — they will each need a registered namespace (`progress`, `inventory`) at their authoring, which is exactly what TR-SAV-004's mechanism exists for. Until then their state is session-only by construction, and **OQ-SAV-11 records the obligation** so it cannot be missed. SYS-03 reads no gameplay value, publishes none, and is never in a gameplay tick's critical path.

### Consumed-Contracts Ratification (SYS-03 side)

| Contract | SYS-03's ratification | Test |
|---|---|---|
| TR-RWS-025 (the five families) | Consumed **verbatim** — names, shapes, and the store/derive law; the MetSys Dictionary is a written derived target | TR-SAV-001/002/003; AC-SAV-01/02/03 |
| TR-RWS-026 (the ports) | The adapter uses `TruthPort`/`MetSysPort`/`TelemetryPort`/`TuningPort`; no MetSys symbol outside the adapter | TR-SAV-003; AC-SAV-03 |
| V-RWS-15 (the transient audit) | Consumed — no room-local state is a source | TR-SAV-005; AC-SAV-05 |
| TR-DR-015 + E4 (the save law) | Consumed **verbatim** — the window queue, the post-flip capture by construction, the deferral-gap persistence | TR-SAV-013; AC-SAV-11 |
| TR-DR-004 E1–E7 | The queue keys on E2→E6's window; no new freeze channel is minted | TR-SAV-013; AC-SAV-11 |
| TR-WME-006 + F-WME-01 | Consumed **verbatim** — no field, derived at load, absent-key-unset, out-of-range → the refusal, SYS-10 adds nothing to the schema | TR-SAV-023/024; AC-SAV-19/20 |
| TR-WME-011 (the reconcile budget) | Consumed as the handoff's bound (≤ 1 ms at load) | TR-SAV-025; AC-SAV-21 |
| TR-INP-036 (bindings device-local) | Consumed as an explicit non-dependency; a save may never carry a controls field | V-SAV-07; AC-SAV-05 |
| ADR-0001 §3 / §5 | The snapshot lands on a tick boundary; the freeze law bounds the queue | TR-SAV-012/013; AC-SAV-11/12 |
| The `epoch_mutation_reconciliation` registry entry | The reconciliation contract consumed; **the real-file twin is the authoring gate and it has run** | AC-SAV-24; §J's gate record |

## Formulas

Three laws govern SYS-03's formulas: **the record law** (the hash covers the record, including its version), **the gate law** (the version decision is total and ordered), and **the bounded-wait law** (the freeze queue's wait has a finite, derivable bound). SYS-03 converts no ms→ticks of its own: the freeze's duration is SYS-09's F-DR-02 family (consumed); SYS-03's budget figures are dev-assert measurement bounds, never timing contracts.

### Formula ledger — law vs knob

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-SAV-01 | `state_hash` | True law | the canonicalization rules; SHA-256; `schema_version` |
| F-SAV-02 | `schema_gate` | True law | `CURRENT_SCHEMA_VERSION`; the migration table |
| F-SAV-03 | `deferral_tick` | True law | SYS-29's `FreezeState`; SYS-09's `worst_case_hold_ticks` (F-DR-05/06) |
| F-SAV-04 | `integrity_verdict` | True law | the refusal-code order; `max_epoch` (SYS-02) |

#### F-SAV-01 · state_hash — the record's fingerprint (TR-SAV-008/009)

`state_hash = sha256_hex(canon({schema_version, payload}))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the schema version | `schema_version` | int | ≥ 1 | the envelope's version — **inside** the hash, so a version edit is a mismatch, not a gate bypass |
| the payload | `payload` | dict | the namespace registry at `v` | at v1: `{world: {…}}` — the `cache` namespace is **registered but absent** until v2 (TR-SAV-004) |
| the canonicalizer | `canon` | pure function | — | TR-SAV-009's five rules (sorted keys; sorted set-arrays; integer decimals; no floats; no null) |
| the result | `state_hash` | string | 64 lowercase hex | the envelope's `state_hash`; the twin's comparison key; the read-back verify's key |

**Output Range:** a 64-character hex digest, stable across runs, key orders, array orders, and `saved_at_utc`/`game_version` changes. **Worked examples** (the twin's real output):

| Fixture | Hash |
|---|---|
| `pre_flip` | `bf18d435e92b3c420ee909d2229e830cae4fbf97a9d4072b59848760d174a5e8` |
| `deferral_gap` | `e3f7a6a05783c3e441cbc6ceb3dc37271d5fb2c2d93799e31e79cb212188de1e` |
| `post_flip` | `05b1e48e3823ac3d444f6c5428b1365efca337e3cebf5673207114e51fdffe37` |

The `pre_flip` canonical payload: `{"world":{"cells_discovered":[[0,0],[0,1]],"doors_opened":["b1","b2"],"memories_collected":[],"truth_epoch":0,"truth_flags":{"sanctum_log_read":false}}}`.

**Rate law note:** no ms operand exists; the hash is pure integer/string arithmetic over the record.

#### F-SAV-02 · schema_gate — the version decision (TR-SAV-019)

`schema_gate(v, current) → {ACCEPT, MIGRATE, REFUSE_SCHEMA_INVALID, REFUSE_SCHEMA_AHEAD}`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the file's version | `v` | int | any | the envelope's `schema_version` |
| the build's version | `current` | int | ≥ 1 | `CURRENT_SCHEMA_VERSION` (1 at MVP) |
| the result | the decision | enum | 4 values | the load's next step |

**The decision (total, ordered):** `REFUSE_SCHEMA_INVALID` if `v` is not an integer or `v < 1` · `REFUSE_SCHEMA_AHEAD` if `v > current` · `ACCEPT` if `v = current` · `MIGRATE` if `1 ≤ v < current`.

**Output Range:** exactly one decision for every `(v, current)`. **Examples:** `(1,1)` → ACCEPT · `(1,3)` → MIGRATE · `(99,1)` → REFUSE_SCHEMA_AHEAD · `(0,1)` → REFUSE_SCHEMA_INVALID · `(1.5,1)` → REFUSE_SCHEMA_INVALID.

**Rate law note:** none — integer comparison.

#### F-SAV-03 · deferral_tick — the E4 queue's wait (TR-SAV-013)

`t_write = min { t ∈ ℕ : t ≥ t_req ∧ flip_sources_active(t) = ∅ }`, or `⊥` on the unreadable-publication path.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the request tick | `t_req` | int (tick) | ≥ 0 | the tick the intent was recorded |
| the active freeze sources | `flip_sources_active(t)` | set of source ids | ⊆ {`truth_flip`, `truth_flip_ext_1`, `truth_flip_ext_2`} | SYS-29's `FreezeState`: the flip-scoped sources active at `t`; **the empty set is the writable state** |
| the worst-case hold | `N_max` | int (tick) | ≥ 1 | **consumed from SYS-09** — `worst_case_hold_ticks`, the base hold plus the two admitted extension spans (F-DR-05/06's cap). 18 at the defaults; the extension spans are SYS-09's numbers |
| the snapshot tick | `t_write` | int (tick) or `⊥` | `t_req ≤ t_write ≤ t_req + N_max`, or `⊥` | the first unfrozen tick — where the snapshot reads the store |

**The bound is a consumption, not a derivation.** SYS-09 owns the freeze's ms→tick conversion (F-DR-02) and its extension arithmetic (F-DR-05); SYS-03 reads the published worst case and never re-derives it. **The bound is the liveness proof:** a queued save cannot wait longer than the longest legal flip hold (base + the two admitted extensions), so the queue is finite by construction. If `flip_sources_active` is unreadable — the publication is missing, a boot-order defect — the predicate reads **true** for at most `N_max` ticks; past that the request fails with `SAVE_FAILED_FREEZE_UNAVAILABLE` (a bounded wait, never an unbounded hang).

**Output Range:** a tick ≥ `t_req`, or `⊥` (the failure path). **Examples:** no freeze → `t_write = t_req`. A request at 100 inside a window closing at 118 → 118 (the snapshot then carries epoch 1 if the flip committed). A request at 100 with an admitted extension → the first tick after the last extension expires — **SYS-09's number, not SYS-03's**. Two requests at 100 and 110 in the same window → both become eligible at the window's close and coalesce latest-wins, so **the later request's snapshot survives** as the one write.

**Rate law note:** no ms operand appears in F-SAV-03's arithmetic — it is tick arithmetic over SYS-29's publication, and the ms→tick conversion of the freeze is SYS-09's F-DR-02 (consumed, never re-derived).

#### F-SAV-04 · integrity_verdict — the load's decision (TR-SAV-018/020/026)

`integrity_verdict(bytes) → {ACCEPT, MIGRATE, <refusal code>}`

**The ordered decision list — the order is the law.** Rows 0–2 are **mechanical**: they need no semantic interpretation, and they are the minimum that makes a hash computable.

| # | Test | Result on failure |
|---|---|---|
| 0 | the bytes parse as JSON; the envelope keys exist (`schema_version`, `state_hash`, `payload`); `state_hash` is a 64-hex string; `payload` is a dict | `REFUSE_TRUNCATED` |
| 1 | `schema_version` is an integer (after the normalization pass, TR-SAV-026) | `REFUSE_SCHEMA_INVALID` |
| 2 | every number in the payload is an integer in its schema-declared domain (the normalization pass, TR-SAV-026) | `REFUSE_FLOAT` / `REFUSE_TYPE` |
| 3 | `sha256_hex(canon({schema_version, payload})) = state_hash` | `REFUSE_HASH_MISMATCH` |
| 4 | `schema_gate(v, CURRENT)` is not a refusal | `REFUSE_SCHEMA_AHEAD` / `REFUSE_SCHEMA_INVALID` |
| 5 | every `world` key is registered **at `v`**; every payload key is a registered namespace **at `v`** | `REFUSE_UNKNOWN_KEY` |
| 6 | every value's type is in its domain | `REFUSE_TYPE` |
| 7 | `truth_epoch` is present | `REFUSE_MISSING_EPOCH` |
| 8 | `truth_epoch ∈ [0, max_epoch]` | `REFUSE_EPOCH_RANGE` |
| — | all pass | `ACCEPT`, or **`MIGRATE`** when row 4 returned MIGRATE |

**Why the mechanical scan precedes the hash:** a float, a non-integer version, or a missing `state_hash` cannot be canonicalized, so "integrity before interpretation" must mean *mechanical well-formedness first, semantic interpretation after*. Rows 0–2 are the minimum needed to compute a hash; row 3 is the integrity gate; rows 4–8 are the interpretation. **`MIGRATE` is an output, not a refusal** — a legitimately older file must pass this function and hand to TR-SAV-019's chain.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the file's bytes | `bytes` | byte string | any | the slot's `.sav` (or `.bak`) content |
| the parsed envelope | `env` | dict or `⊥` | — | the JSON parse's result; `⊥` on a parse failure |
| the schema's declared types | `schema@v` | type table | — | the per-key type/range table for the file's version (TR-SAV-026's input) |
| the restored epoch's ceiling | `max_epoch` | int | 1 at MVP | SYS-02's config — the range check's upper bound |
| the result | the decision | enum | `ACCEPT` · `MIGRATE` · 9 refusal codes | the load machine's next step |

**Output Range:** `ACCEPT` · `MIGRATE` · **nine** refusal codes. `REFUSE_ABSENT` and `REFUSE_UNREADABLE` are decided **before** bytes exist (TR-SAV-020) and are not outputs of this formula. **The order's work:** a truncated file is `REFUSE_TRUNCATED`, never `REFUSE_HASH_MISMATCH` (the hash cannot be computed); a version edit is `REFUSE_HASH_MISMATCH` (the version is hashed), so `REFUSE_SCHEMA_AHEAD` is reached only by a **legitimately written** newer file; a hand-edited epoch with a recomputed hash is `REFUSE_EPOCH_RANGE` (integrity is not authenticity — the no-clamp law is the last line). **Examples:** the twin's `COR-*` set — every negative fixture yields its named code and leaves the file byte-identical.

**Rate law note:** none.

### Validation Invariants

**The knob validation law (V-SAV).** Every invariant is validated at boot and on every live edit; a violation is a dev boot failure (or a CI failure for the static ones); production keeps the last good config. *(SYS-02's law consumed — restated because SYS-03's lints are its enforcement surface.)*

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V-SAV-01 | the `world` namespace has exactly the five keys; a sixth is a contract revision | dev boot failure (the schema lint) | the five-family law is SYS-02's published contract |
| V-SAV-02 | the migration table is contiguous: `MIGRATIONS[n]` exists for every `1 ≤ n < CURRENT` | dev boot failure | a chain with a hole is not a chain |
| V-SAV-03 | no derived target is a stored key: no border/gate/material/reachability/tell/pending-flip/freeze symbol in the schema module | CI grep + dev boot failure | the store-sources/derive-targets law |
| V-SAV-04 | every write goes through the temp+rename path; no direct overwrite of a `.sav` | CI grep | a torn file is unreachable only if the path is exclusive |
| V-SAV-05 | the snapshot runs only when `flip_sources_active` is empty; zero SYS-03 source writes after `restore_complete` | dev assert + runtime port spy | E4's law; the runtime write ban |
| V-SAV-06 | `truth_epoch ∈ [0, max_epoch]` at load; out of range refuses | the load's refusal (never a clamp) | the no-repair law |
| V-SAV-07 | no slot carries a `controls`/binding key | static audit + schema test | TR-INP-036's non-dependency |
| V-SAV-08 | every registered namespace has a named owner and ≥ 1 reader | dev boot failure | an ownerless namespace is a leak with no consumer |
| V-SAV-09 | every schema-declared integer key is normalized from the parsed number (TR-SAV-026); a non-integral value refuses | the load's refusal + the engine-half fixture | Godot's `JSON` yields a float for every number — without the pass, every legitimate save refuses |

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### The write

- **If the disk is full** → `save_failed(DISK_FULL)`; the previous `.sav` is intact; the surface reports that saving is unavailable. [The temp write fails before the rotation — the good file is never touched.]
- **If the storage is read-only** → `save_failed(PERMISSION)`; the session continues; the surface reports it once. [A save failure is never a crash and never a silent success.]
- **If the app is killed mid-write** → the `.sav` is the old file or the new one; the orphaned `.tmp` is swept at the next boot; the `.bak` holds the previous good state. [The rename is the commit point.]
- **If a second request arrives while a write is in flight** → it queues; one write in flight per slot. [No thread pool, no interleaving.]
- **If two requests for the same slot queue** → they coalesce (latest wins, one telemetry record). [A save is a snapshot of *now*; an older queued snapshot is never worth writing.]
- **If a request arrives during the loading context** → refused at the request (SYS-05's gate); a dev assert records it. [Saving a half-restored world is the one snapshot that must never exist.]
- **If a request arrives inside the flip window and the flip commits** → queued to the first unfrozen tick; the snapshot carries epoch 1. [E4's law; the τ0 store precedes E4.]
- **If a request arrives inside the flip window and the flip aborts** → queued to the first unfrozen tick; the snapshot carries `{epoch 0, flag set}`. [The deferral-gap state (b) — the pending flip survives the session.]
- **If a save happens during a deferral gap (before E1)** → it executes at its request tick and captures `{epoch 0, flag set}`. [The same state (b) by a different mechanism — the twin asserts the state, never the path.]
- **If the close request arrives while a write is in flight** → the in-flight write completes first; the close-save then writes synchronously within `SAVE_JOIN_TIMEOUT_MS`. [The one legal blocking path; there is no frame to miss.]
- **If the close-save fails** → nothing is shown (the app is closing); the last station autosave is the fallback; telemetry records it. [The player's last station ack is never more than one station behind.]
- **If the snapshot's arrays exceed their bounds** → impossible by SYS-02's registries; a dev assert fires. [A bound that can be exceeded is not a bound.]

### The load

- **If the slot is empty** → `REFUSE_ABSENT` — the first boot, not a failure; SYS-05's `new_game` path. [The absence of a save is a normal state.]
- **If the file is truncated** → `REFUSE_TRUNCATED`; the `.bak` is tried. [Parse before hash — a truncated file has no computable hash.]
- **If one payload byte is flipped** → `REFUSE_HASH_MISMATCH`; the `.bak` is tried. [Integrity before interpretation.]
- **If the file's version is newer than the build's** → `REFUSE_SCHEMA_AHEAD`; the file is preserved byte-identical; the slot is read-only; **no `.bak` attempt**. [A downgrade would be the silent lie the refusal exists to prevent.]
- **If the file's version is `0` or non-integer** → `REFUSE_SCHEMA_INVALID`. [A version below 1 was never written by any build.]
- **If the version is older but migratable** → the chain runs; a step's failure is a refusal and the **original file is preserved**. [The migration is in memory; the file is never rewritten by a load.]
- **If a key is not in the schema at its version** → `REFUSE_UNKNOWN_KEY`. [The file is evidence; an unknown key is a gated artifact or tampering.]
- **If `truth_epoch` is absent** → `REFUSE_MISSING_EPOCH`. [The truth is not defaultable.]
- **If `truth_epoch` is out of range** → `REFUSE_EPOCH_RANGE`; **never clamped**; SYS-10 is never called. [A clamp is a repair write.]
- **If a float appears** → `REFUSE_FLOAT`. [A text format cannot round-trip a float canonically.]
- **If the `.bak` is also corrupt** → the refusal (the primary's code is reported; the `.bak`'s is telemetry). [The last good state is gone; the file is preserved for diagnosis.]
- **If the `.sav` is missing and the `.bak` exists** → the boot sweep promotes the `.bak`; the load proceeds; `bak_promoted` + `bak_loaded` are recorded. [A file-level recovery, not a state repair.]
- **If the `.tmp` exists** → swept at boot. [An incomplete write is never read.]
- **If a restore fails mid-build** → the live store is untouched; the refusal publishes. [The staging swap is the atomicity.]
- **If the load is requested twice in one session** → the second is a fresh load machine pass; one load at a time globally. [No concurrent restores.]

### The reconciliation

- **If the save is state (a)** → ordinary restore; no request; no flip. [TR-WME-006 (a).]
- **If the save is state (b)** → the deferral gap; `restore_complete` publishes; SYS-10's request publishes before `load_complete`; the choreography re-fires at the first post-load tick. [The same logical flip completing — not a second flip.]
- **If the save is state (c)** → post-flip; no re-fire; truth B renders from the epoch. [Cross-session single-shot.]
- **If the save is state (d)** (epoch 1 ∧ flag unset) → restored **as-is**; SYS-10's dev assert + telemetry; truth B stands; playable. [SYS-03 does not repair a contradiction into consistency.]
- **If the save's epoch is out of range** → state (e); refused before SYS-10 is called. [The guard is upstream by design.]
- **If a save carries a `pending_flip` key** → `REFUSE_UNKNOWN_KEY`. [No such field exists; a file that has one was not written by this system.]
- **If `restore_complete` would publish after `load_complete`** → a dev assert; the ordering is a law, not a convention. [The re-fire must never fire inside the loading context.]

### The platform

- **If `user://` cannot be resolved** (a CI/dev harness case) → the twin uses a temp directory; the game always resolves `user://`. [The twin's path is its own; the game's path is never configurable.]
- **If the OS suspends the app mid-load** → the load restarts at the next boot; the staging swap means no partial restore ever became live. [The store is never half-written.]
- **If the player deletes the save from the OS** → the next boot is `REFUSE_ABSENT` — the first-boot path. [An external deletion is indistinguishable from a fresh install, and both are legal.]
- **If cloud backup restores an old file over a newer one** → the version gate + the hash decide; a valid older state loads; a valid newer state refuses on an older build. [The platform's backup is not a SYS-03 concern beyond the gate.]

## Dependencies

**Upstream authoring dependencies: none.** SYS-03 is Foundation, authored in the approved design order (#11) after SYS-02/SYS-09/SYS-10. Its runtime consumptions are contract consumptions of APPROVED GDDs, not authoring dependencies.

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream (runtime) | **SYS-02 Room & World** | **Hard** (read-only) | In: the five families, `max_epoch`, the ports (`TruthPort`, `MetSysPort`, `TelemetryPort`, `TuningPort`) · Out: the MetSys Dictionary (write-only, through the adapter) | APPROVED 2026-11-13 |
| Upstream (runtime) | **SYS-09 Dual-Reality** | **Hard** (policy) | In: E4's law, the E1–E7 edges · Out: nothing | Landed 2026-11-14 |
| Upstream (runtime) | **SYS-10 World Mutation** | **Hard** (contract) | In: the reconciliation contract (TR-WME-006/F-WME-01) · Out: `restore_complete(sources)` | APPROVED 2026-11-14 |
| Upstream (runtime) | **SYS-29 Juice & Feedback** | Soft (service) | In: the `FreezeState` publication (the queue's predicate) · Out: nothing | APPROVED 2026-11-13 |
| Upstream (runtime) | **ADR-0001** | Binding | §3 (the freeze), §5 (the tick boundary) | Accepted 2026-11-12 |
| Upstream (runtime) | **SYS-01 Input** | **None** (explicit) | TR-INP-036: bindings device-local, never in a slot | APPROVED 2026-11-12 |
| Downstream | **SYS-05 Game Flow** | Soft | Out: `load_result`, `save_completed`, `restore_complete` · In: the loading context, `load_complete`, the refusal flow | Not Started (the contract is published here) |
| Downstream | **SYS-15 Cache Stations** | Soft | Out: the `cache` namespace registration + the mechanism · In: the namespace's shape (at its authoring, a `v1→v2` bump) | Not Started |
| Downstream | **SYS-20 Memory Fragments** | Soft | Out: `memories_collected` (read) · In: nothing | Not Started |
| Downstream | **SYS-25 Map / Fog** | Soft | Out: `cells_discovered` (read) · In: nothing | Not Started |
| Downstream | **SYS-24 HUD / UI** | Soft | Out: the refusal/load-result surfaces + the slot-list metadata · In: nothing | Not Started |

**The ADR obligation.** The **Save & Serialization ADR** (owned by the ADR-DRAFT lane) carries: the writer's thread shape, the file's byte layout and canonicalization, the migration table's registration API, and the platform path helper. This GDD stays at the behavior level; the ADR is the implementation's binding record.

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) **SYS-03's row** gains the GDD path, the counts (26 TR / 4 F-SAV / 9 V-SAV / 26 ACs = 22 GUT + 2 LINT + 2 DEVICE + 0 PLAYTEST), the twin's verdict, and the gate trail; (2) **SYS-05's row** gains the `restore_complete`-before-`load_complete` ordering and the refusal-flow ownership; (3) **SYS-15's row** gains the `cache` namespace registration (a `v1→v2` bump at its authoring), the `save_completed` print input, and the **named gate: the death counter persists at MVP** — the bump cannot be silently dropped; (4) **SYS-20's row** gains "reads `memories_collected`; never writes it"; (5) **SYS-25's row** gains "reads `cells_discovered`; never writes it"; (6) **SYS-24's row** gains the refusal/load-result surfaces + the slot-list metadata; (7) **SYS-02's row** gains the adapter's write-only boundary + the namespace-registry note; (8) **SYS-01's row** gains the reciprocal TR-INP-036 confirmation; (9) **SYS-10's row** gains "the epoch-range guard sits upstream in SYS-03 (TR-WME-006(e) implemented)"; (10) **SYS-16's and SYS-17's rows** gain the persistence-namespace obligation (OQ-SAV-11) — their MVP state is session-only until they register.

## Tuning Knobs

SYS-03 is law-heavy by nature. Two knobs exist; everything else is listed as **not a knob** so nobody adds it later.

| Knob | Default | Safe range | Why the bounds | Rule |
|---|---|---|---|---|
| `SAVE_TELEMETRY_RATE_LIMIT_MS` | 1000 | 250–5000 | <250 floods the log on a retry loop; >5000 hides a genuine loop | the repeat-suppression window for identical records |
| `SAVE_JOIN_TIMEOUT_MS` | 250 | 100–1000 | the close-save's synchronous join is ≤ 2 KB of IO; a longer wait means the storage is wedged | **dev assert only** — never a player-facing timing contract |

**Not knobs** (documented so nobody adds them): the slot ids and count (`auto` + `manual_1` — a code change with a migration review) · the **backup depth** (exactly one `.bak` per slot; a depth-2 rotation needs `.bak2` naming, rotation and sweep — a future change, not a config edit) · `CURRENT_SCHEMA_VERSION` (a schema fact) · the hash algorithm and the canonicalization rules · the atomic-write order · the queue predicate (`flip_sources_active`) · the refusal-code and save-failure vocabularies · the absent-key matrix · the epoch guard · the no-floats law · the runtime write ban. Each is a contract, and a contract with a knob is not a contract.

## Visual/Audio Requirements

**SYS-03 owns no visual or audio surface.** This section records the abstention and the boundary, so the absence is a decision rather than an omission.

| Surface | Owner | SYS-03's input |
|---|---|---|
| The "MEMORY CACHED" print | SYS-15 (the fiction) / SYS-24 (the rendering) | `save_completed(slot, tick)` — the record, not the words |
| The save-in-progress indicator | SYS-24 | the save machine's state (a read-only publication) |
| The refusal surface's look | SYS-24 | the code + the slot (TR-SAV-022) |
| The load-result surface | SYS-24 | `load_result` |
| Any audio cue for saving | SYS-04 / SYS-15 | none — SYS-03 emits no audio event |

**Acceptance bars:** none owned. **Asset-spec route:** none — no asset is requested by this system.

## UI Requirements

SYS-03 publishes; SYS-05 flows; SYS-24 renders. The requirements below are what the published surface must carry — not how it looks.

**The refusal surface (the only screen SYS-03's behaviour forces).**

- **Must show:** a stable code's human sentence (never the raw `REFUSE_*` string), the slot, and the fact that the file was preserved.
- **Must offer exactly two actions for the refused slot:** start a new game, or quit. **No "retry"** (a refusal is terminal), **no "repair"**, **no auto-overwrite**. If the *other* slot holds a good save, loading it is a third, legal action — the two-slot model makes this reachable.
- **Must not:** delete, rename, or rewrite the refused file. **Scope:** a refusal binds the refused slot only — if `manual_1` is refused while `auto` holds a good save, the surface may offer `auto`; the navigation ruling is SYS-05's under OQ-SAV-7.
- **Accessibility:** a full-screen text surface; the screen reader announces the human sentence; no color-only distinction; the two actions are focus-ordered and each has a ≥ 48 dp hit target (the SYS-01 baseline consumed).

**The load-result surface.**

- **Must show:** the restored slot, its `saved_at_utc`, and — where SYS-15/SYS-25 choose to render them — **a diegetic truth indicator** (never a numeric "epoch badge": *epoch* is an internal noun the player never learns), the memories count, and the discovered-cell count. SYS-03 supplies the metadata; the presentation is theirs.
- **A `bak_loaded` result must be stated** ("recovered from the previous save") — a recovery the player is not told about is a silent repair by another name. **The post-load re-fire beat's presentation owner is SYS-09/SYS-15**: the player watches the world turn without having acted, and the beat must read as the world's own motion, never as a loading glitch — SYS-03 publishes the request's existence, never the presentation.

**The slot-list metadata (the publication SYS-24 may consume):**

`{slot_id, saved_at_utc, truth_epoch, memories_count, cells_count, schema_version, state ∈ {OK, BAK_ONLY, REFUSED_READ_ONLY, EMPTY}}`

**Ownership:** SYS-03 publishes the metadata and the codes; SYS-05 owns the navigation; SYS-24 owns the rendering. No persistence module may call a UI API (the ownership grep — AC-SAV-26's audit clause).

## Acceptance Criteria

**Gate partition:** 26 ACs = **22 `[GUT]`** + **2 `[LINT]`** + **2 `[DEVICE]`** + **0 `[PLAYTEST]`**.

**Why the `[PLAYTEST]` partition is zero (stated, not omitted):** SYS-03 owns no player-facing feel surface. The feel questions this system could raise — "does the return feel right?", "does the refusal read as honest?" — are SYS-15's print/flow and SYS-24's surface, and they are covered by those systems' own ACs. The one thing SYS-03 could prove with a human is "the player never notices the save", which is proven negatively by the absence of any surface, not by a probe.

### The source contract and the schema

- **AC-SAV-01** `[GUT]` *(TR-SAV-001/002)* — **GIVEN** the five-family fixture, **WHEN** the real-file round-trip runs (write → close → reload → hash), **THEN** the restored hash equals the written hash and every family's contents match exactly. *(The twin's `RT-*`.)*
- **AC-SAV-02** `[GUT]` *(TR-SAV-002)* — **GIVEN** the authored border/gate defaults and a restored save, **WHEN** the derivation fixture runs, **THEN** no border/gate/material/reachability key exists in the file, and the border and gate states re-derive from the epoch + the door ids to the authored values.
- **AC-SAV-03** `[GUT]` *(TR-SAV-003)* — **GIVEN** a MetSys Dictionary that disagrees with the restored sources, **WHEN** the adapter runs, **THEN** the Dictionary is overwritten from the sources (the discovery set, the door ids, and the `memories_collected` → storable-id map), one `adapter_overwrote` record is emitted, an unmapped memory id fails the boot lint, and the addon's own save path has exactly one call site.
- **AC-SAV-04** `[GUT]` *(TR-SAV-004, V-SAV-01/08)* — **GIVEN** the schema module, **WHEN** a sixth `world` key, an ownerless namespace, or a v1 file carrying a `cache` key is introduced, **THEN** the boot fails naming it (the first two) / the load refuses `REFUSE_UNKNOWN_KEY` (the third); **AND** the registry lists `cache` as registered-but-absent, a v1 reader defaults it to the new-game state, and every registration emits one `namespace_registered` record.
- **AC-SAV-05** `[LINT]` *(TR-SAV-005, TR-INP-036, V-SAV-03/07)* — **GIVEN** the schema and adapter modules, **WHEN** the transient and binding audits run, **THEN** zero transient symbols and zero binding keys are found.
- **AC-SAV-06** `[GUT]` *(TR-SAV-006)* — **GIVEN** a payload containing a non-integral number, **WHEN** the save path runs, **THEN** the dev boot assert fails; **AND WHEN** the load path runs on the same file, **THEN** it refuses with `REFUSE_FLOAT`. *(Two required assertions — the write side and the load side.)*
- **AC-SAV-07** `[GUT]` *(TR-SAV-007, V-SAV-05)* — **GIVEN** the persistence module's runtime, **WHEN** the port spy runs across a full save/load/reconcile cycle, **THEN** zero SYS-03 writes to a source occur outside the restore path.

### The write path

- **AC-SAV-08** `[GUT]` *(TR-SAV-009)* — **GIVEN** two payloads identical but for key and array insertion order, **WHEN** both are hashed, **THEN** the hashes are equal. *(The twin's `CANON-order`.)*
- **AC-SAV-09** `[GUT]` *(TR-SAV-010/016)* — **GIVEN** a fault injected at each of the six write steps **and** an injected read-only volume and a full disk, **WHEN** the write runs, **THEN** the previous `.sav` is intact or the `.bak` recovers, no torn file is ever readable, and the failure is reported with its `SAVE_FAILED_*` code. *(The twin's `WRITE-fail` covers steps 3–6; the step-1/2 faults and the IO injections are GUT fixtures.)*
- **AC-SAV-10** `[GUT]` *(TR-SAV-011/012)* — **GIVEN** both slots and a maximal store, **WHEN** each saves, **THEN** each slot writes, backs up, and reloads independently; the snapshot is taken once per request; the snapshot's copy is ≤ ~150 elements (the fixed-cost proxy — the wall-clock 0.5 ms is a non-gating probe).
- **AC-SAV-11** `[GUT]` *(TR-SAV-013, F-SAV-03)* — **GIVEN** a save request at tick 100 inside a flip window closing at 118, **WHEN** the queue resolves, **THEN** `t_write` is 118 and the snapshot carries epoch 1; **AND** the abort case and the deferral gap both restore as `{epoch 0, flag set}`; **AND** the [E1, E2) gap restores as state (b); **AND** a request inside the loading context is rejected with no snapshot and one telemetry record; **AND** two same-slot requests in one window produce one write (the later snapshot) and one `save_queued`; **AND** an unreadable freeze publication past `N_max` fails with `SAVE_FAILED_FREEZE_UNAVAILABLE`.
- **AC-SAV-12** `[GUT]` *(TR-SAV-014/017)* — **GIVEN** a save in flight during gameplay, **WHEN** the frame probe runs, **THEN** no gameplay frame exceeds 16.6 ms attributable to the save and the close-save completes within `SAVE_JOIN_TIMEOUT_MS`; **AND** one write is in flight per slot; **AND** the **save-path** records (`save_requested`, `save_queued`, `save_completed`, `save_failed`) fire once each with no family value, and identical repeats inside `SAVE_TELEMETRY_RATE_LIMIT_MS` are suppressed; the **load-path** and **boot-path** records are asserted by AC-SAV-15/17 and AC-SAV-13 respectively.
- **AC-SAV-13** `[GUT]` *(TR-SAV-015)* — **GIVEN** an orphaned `.tmp` and a `.sav`-missing/`.bak`-present slot, **WHEN** the boot sweep runs, **THEN** the `.tmp` is deleted, the `.bak` is promoted, `bak_promoted` + `tmp_swept` fire, and the loaded state is the last good one.
- **AC-SAV-14** `[DEVICE]` *(TR-SAV-016)* — **GIVEN** a real iOS and Android device, **WHEN** the game saves, relaunches, and loads, **THEN** the file sits under the app's data dir and the state restores. *(The read-only-volume case is a GUT injected-IO fixture under AC-SAV-09 — an app's data dir cannot be mounted read-only on a real device.)*

### The load path and the schema

- **AC-SAV-15** `[GUT]` *(TR-SAV-018/026, F-SAV-04)* — **GIVEN** the corrupted set, **WHEN** each loads, **THEN** the truncated file yields `REFUSE_TRUNCATED` (not `REFUSE_HASH_MISMATCH`), a non-integer version yields `REFUSE_SCHEMA_INVALID`, and the order is parse → normalize → hash → gate → shape → range.
- **AC-SAV-16** `[GUT]` *(TR-SAV-019, F-SAV-02)* — **GIVEN** the synthetic `CURRENT = 3` harness and its registered steps, **WHEN** the chain runs below the gate, **THEN** `v1→v3` composes, the rename **preserves the value** (`sanctum_log_read: true` → `sanctum_log_consumed: true`), and a contiguity gap fails the boot; **AND** a `v0` file is refused at the gate (AC-SAV-17's fixture), never migrated.
- **AC-SAV-17** `[GUT]` *(TR-SAV-020/022, F-SAV-04)* — **GIVEN** a named fixture for **every** code — `ABSENT`, `UNREADABLE`, `TRUNCATED`, `HASH_MISMATCH`, `SCHEMA_AHEAD`, `SCHEMA_INVALID`, `UNKNOWN_KEY` (including the `pending_flip` key), `MISSING_EPOCH`, `EPOCH_RANGE`, `TYPE`, `FLOAT` — **WHEN** each loads, **THEN** the named code is published, the file's bytes are identical afterwards, and the slot's expected state matches: `ABSENT` → `EMPTY`; a `.bak`-recoverable failure → `OK` after the recovery; a terminal failure (both files fail) → `REFUSED_READ_ONLY`.
- **AC-SAV-18** `[GUT]` *(TR-SAV-021)* — **GIVEN** a corrupt primary with a good `.bak`, **WHEN** the load runs, **THEN** the `.bak` loads, **the verified `.bak` is promoted to `.sav` before the slot returns to `OK`**, `bak_loaded` fires, and a subsequent failed write cannot leave two bad files; **AND** both files corrupt → the refusal reporting **the primary's code** (the `.bak`'s code is telemetry); **AND** a `REFUSE_SCHEMA_AHEAD` primary never attempts the `.bak`.
- **AC-SAV-19** `[GUT]` *(TR-SAV-023)* — **GIVEN** each absent-key fixture, **WHEN** the load runs, **THEN** the **three arrays** (`doors_opened`, `memories_collected`, `cells_discovered`) default to `[]`, `truth_flags` defaults to `{}` with every registered flag unset, and the absent `truth_epoch` refuses with `REFUSE_MISSING_EPOCH`. *(The twin's `ABS-defaults`.)*
- **AC-SAV-20** `[GUT]` *(TR-SAV-024)* — **GIVEN** the five states (a)–(e), **WHEN** each restores, **THEN** (a) restores with no request and no flip; (b) derives pending true, publishes the request **before `load_complete`**, and its replay hash equals the fresh flip's; (c) restores epoch 1 with no re-fire; (d) is restored as-is with SYS-10's assert and truth B standing; (e) is refused **before SYS-10 is called**; **AND** `restore_complete` precedes `load_complete` in every case.
- **AC-SAV-21** `[GUT]` *(TR-SAV-025)* — **GIVEN** a failure injected mid-restore, **WHEN** the load aborts, **THEN** the live store is untouched and the refusal publishes; **AND** a second concurrent load is rejected (one load at a time globally); the restore's cost is a non-gating ≤ 1 ms probe.
- **AC-SAV-22** `[GUT]` *(TR-SAV-008/009, F-SAV-01)* — **GIVEN** a valid v99 file edited to claim v1, **WHEN** it loads on a v1 build, **THEN** it refuses with `REFUSE_HASH_MISMATCH` (the version is hashed); **AND** a re-save of an unchanged state with a different `saved_at_utc` hashes identically. *(The twin's `COR-downgrade` + `RT-hash-stable`.)*

### The engine model, the twin, and the static audits

- **AC-SAV-23** `[DEVICE]` *(TR-SAV-011/014/016)* — **GIVEN** a real device, **WHEN** the app is backgrounded and terminated after a station ack (iOS) / quit (desktop) / stopped (Android), **THEN** the suspension/close-save lands where the platform delivers the event **and the restored state equals the state at the suspension** (including anything collected after the last station ack); **AND** the last committed station-save state is the fallback only when the event is not delivered or the close-save is skipped; **AND** if the platform delivers the event but the write fails (e.g. `SAVE_FAILED_DISK_FULL` / `SAVE_FAILED_PERMISSION`), the reported `SAVE_FAILED_*` code is asserted and the recovered state is **what the next load's integrity path resolves** — the committed bytes if they validate (the new state), otherwise the `.bak` (the previous good state; the writer never rolls back and never repairs) — the same failure law as AC-SAV-09: never a torn file, never a silent success; **AND** a close request arriving while a write is in flight completes the in-flight write first; **AND** a close request arriving while `flip_sources_active` is non-empty **skips** the close-save (no mid-choreography snapshot) and falls back to the last station autosave.
- **AC-SAV-24** `[GUT]` *(TR-SAV-001/008/009/018/019/023/024 — the `epoch_mutation_reconciliation` registry entry)* — **GIVEN** the four required fixtures (pre-flip, deferral-gap, post-flip, corrupted) plus the migration set, **WHEN** the **reference** real-file round-trip twin runs (write → close → reload → state-hash compare), **THEN** every fixture passes and the run's output is recorded in the gate record. **Label: reference twin only** — the engine-path twin is a **story-gated obligation** (the first SYS-03 implementation story) under the same fixtures, and that story's AC is scheduled at its authoring.
- **AC-SAV-25** `[GUT]` *(TR-SAV-026, V-SAV-09)* — **GIVEN** a parsed payload in which a schema-declared integer arrives as a non-integral number, **WHEN** the normalization pass runs, **THEN** it refuses `REFUSE_FLOAT`; **AND** an integral value normalizes identically (the hash is unchanged); **AND** the pass is idempotent. *(The reference twin tests the refusal and the identity; the engine fixture — a real `JSON.parse_string` result — is story-gated.)*
- **AC-SAV-26** `[LINT]` *(V-SAV-03/04/07, TR-SAV-016/022)* — **GIVEN** the persistence and adapter modules, **WHEN** the static audits run, **THEN** zero derived-target symbols are stored (V-SAV-03), every write goes through the temp+rename path (V-SAV-04), no slot carries a binding key (V-SAV-07), no persistence module calls a UI API, and every path string comes from the one path helper.

### Gate manifest

| Gate | ACs | Count |
|---|---|---|
| **Smoke (GUT + LINT)** | 01–13, 15–22, 24–26 | **24** |
| **Device** | 14, 23 | **2** |
| **Playtest** | — | **0** |
| **Total** | | **26** |

**The twin's gate record (the authoring gate).** `node tests/save-twin/save_twin.mjs` → **32/32 PASS** on 2026-11-14 (the format-contract half: canonicalization, the hash, the schema gate, the migration chain below the gate, the number-normalization pass, the integrity verdict, the absent-key defaults, F-WME-01, and the atomic write's six-step failure paths — all on real files). **The split, named honestly:** the engine half (Godot `FileAccess`/`JSON`, the number-normalization pass on a real parse, `user://`, the worker `Thread`) is a **story-gated obligation** under the same fixtures — the first SYS-03 implementation story must run the twin in-engine and attach its verdict to the story's evidence. The reason: the authoring worktree has no Godot binary, no `project.godot`, and an empty `src/` (OQ-SAV-1 option (a), user-approved 2026-11-14).

## Open Questions

| ID | Question | Status | Owner / when |
|---|---|---|---|
| **OQ-SAV-1** | The twin's execution vehicle | **RESOLVED 2026-11-14 (user)** — option (a): the Node reference twin at authoring (run: **32/32 PASS**, post-repair) + the engine-path twin at the first SYS-03 story, same fixtures | lead-programmer; the story gate |
| **OQ-SAV-2** | The slot model | **RESOLVED 2026-11-14 (user)** — `auto` + `manual_1`; the count is a registered constant, not a knob | lead-programmer |
| **OQ-SAV-3** | The file format | **RESOLVED 2026-11-14 (user)** — canonical JSON + SHA-256; no encryption at MVP | lead-programmer; the security audit may reopen |
| **OQ-SAV-4** | The autosave/manual split | **RESOLVED 2026-11-14 (user)** — no timer; `auto` writes on the station ack + the app's suspension/close **event**. **Refinement applied at the repair pass (flagged for the user's nod):** the event set is `{station ack, desktop quit, Android onStop, iOS application-paused}` — iOS's background-kill path is the most common exit on the primary platform, and a station-only trigger would make the Player Fantasy's anchor 2 platform-conditional. Still an event set, never a timer | lead-programmer; SYS-15 ratifies the station trigger at its authoring |
| **OQ-SAV-5** | The unknown-key policy | **RESOLVED** — strict refuse (`REFUSE_UNKNOWN_KEY`) | lead-programmer |
| **OQ-SAV-6** | The absent-`truth_epoch` policy | **RESOLVED** — refuse (`REFUSE_MISSING_EPOCH`); the truth is not defaultable | lead-programmer |
| **OQ-SAV-7** | The refusal UX's owner | **CARRIED** — SYS-03 publishes the code/state; SYS-05 owns the flow; SYS-24 renders. Ratify at SYS-05's and SYS-24's authoring | SYS-05 + SYS-24 |
| **OQ-SAV-8** | The platform path + cloud backup | **CARRIED** — `user://saves/`; the platform default at MVP; the exclusion switch is a release-checklist item; cross-check SYS-01's open Android `user://` auto-backup item so the two platform postures do not diverge | devops-engineer + technical-director |
| **OQ-SAV-9** | The write's threading model | **RESOLVED 2026-11-14 (user)** — one dedicated thread, a one-deep queue, the completion drained at a tick boundary | lead-programmer |
| **OQ-SAV-10** | The `cache` namespace's shape | **CARRIED** — SYS-03 ships the registration mechanism; `cache` is registered but **absent from v1**; SYS-15's authoring fills it and the key appears at the `v1→v2` bump | SYS-15 |
| **OQ-SAV-11** | **SYS-16 / SYS-17's persistence** — both are MVP (levels 1–5 + the gear layer; the Suture + quick slot + loadout) but not yet authored, and neither is a SYS-02 family. | **CARRIED** — each registers its own namespace (`progress`, `inventory`) at its authoring via TR-SAV-004's mechanism, with its own `vN→vN+1` bump. Until then their state is session-only **by construction**, and this row is the record that it must not be forgotten | SYS-16 + SYS-17, at their authoring (after SYS-07-REWORK) |
