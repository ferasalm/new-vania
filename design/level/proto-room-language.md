# Proto Room Language — the Boss-Door Grammar, Mini-Boss Placement, the Changed-Place Pattern

> **Status**: DRAFT v1 (2026-11-16) — authored by level-designer on the prototype track (D-ORCH-15 pivot); validates at the v3 playtest, then informs the GDD resume.
> **Consumes (read, not amended)**: SYS-02 `design/gdd/room-world-structure.md` (the door/border laws, the room record, the load-lifetime law) · SYS-11 `design/gdd/seam-borders.md` (the seam admission test, the band, OQ-6) · SYS-32 `design/gdd/camera-framing.md` (the look-ahead, the hold laws) · SYS-13 `design/gdd/enemy-ai-telegraphs.md` (the telegraph doctrine, the shape families) · SYS-14 `design/gdd/grief-boss-framework.md` (the arena contract, the staging band) · SYS-10 `design/gdd/world-mutation-epochs.md` (the epoch write, the mutation vocabulary) · the art bible `design/art/art-bible.md` (P1–P3, the palette tables, the print layer).
> **User decisions it serves**: D-ORCH-15 (the prototype pivot) · D-ORCH-19 (Arnetria the Mirror Queen) · D-ORCH-20 (no fall death) · **D-ORCH-21** (longer multi-part scope; backtracking into CHANGED places; the Twine tree) · D-ORCH-22 (all packs licensed).
> **Boundary**: this is a **level-design document**. It owns no code, no scene files, no GDD edits, no registry rows. Every contract-adjacent item it needs is raised in **Open Questions** with an owner and a when — nothing here executes a contract change.

## 0. The problem (what the playtest flagged)

Prototype v1 played clean and said three things, all mine:

1. **The boss door was just a door.** The arena's threshold carried no promise — nothing on the approach said *a boss is behind this*, nothing distinguished it from the hub door's `LOCKED`, nothing would distinguish it from a hundred future doors. SYS-02 already owns the mechanics (a door is a locked border; the open is a committed arc; the open is world truth — TR-RWS-007/008). What was missing is the door's **presented language**: the taught visual + audio grammar that makes "boss ahead" legible before the fight, consistently, every time.
2. **The packs' mini-bosses are unplaced.** The library (`inbox/downloads/organized/art`, 24 packs, ~9.6k PNGs — D-ORCH-22 licensed) holds several boss-grade sprites with no home. The v2 brief wants mini-bosses with title cards. Placement needs rules, not vibes: where a mini-boss may stand, what it may teach, and what it must reuse from the door grammar.
3. **The scope is now multi-part with backtracking into CHANGED places (D-ORCH-21).** The flip (SYS-10's one epoch write) plus a longer arc means the player will re-walk familiar rooms that have changed between visits. Without a pattern, that becomes either (a) invisible (changes the player never notices) or (b) noise (every room screaming). The pattern needs a budget.

All three are the same discipline: **the room grammar must be legible at a glance and stable across the run** — the art bible's P1 (the silhouette is the memory; the palette is the lie) applied to doors, encounters, and time.

---

## 1. THE BOSS-DOOR LANGUAGE

### The law

**A boss door is a door that answers.** Every door in the game is one of three taught tiers; the tiers are the world grammar — never per-encounter set dressing. A player who has crossed one boss door knows what every future boss door means, and a player who has crossed three knows it from any single signal. The grammar is taught once at full power (the Denial arena's door — the first boss door in play order) and only ever repeated after that. If an encounter needs to feel special, the room behind the door carries the specialness; the door stays grammar.

Grounding: SYS-02's door laws are untouched — a boss door is a `DOOR` border, `LOCKED` → `OPEN` derived from world truth, the `OPEN` prompt (Class A), the committed arc `DOOR_OPEN_MS` 700 (V-RWS-13's ≤ 1200), the swap at the arc's midpoint behind the door frame, the open-forever law (nobody re-picks the lock). The grammar adds **zero mechanics**: no new collision, no new prompt machinery, no second arc. It is presentation (art + audio) over the existing border, plus one Class B word (`SEALED`) raised as an Open Question.

### The three tiers

| Tier | Border kind | Prompt (admitting / refusing) | The face | The frame | The mark | Audio | Accent |
|---|---|---|---|---|---|---|---|
| **Passage** | `PASSAGE` | none / none | no face — the opening shows the next room's light and material | bare cut; the wall's coursing simply ends | none | none | none |
| **Keyed door** | `DOOR` | `OPEN` / `LOCKED` (dimmed — SYS-02's hub law) | the closure slab: a visible barrier with a sliver of the beyond at its edges | the wall's own coursing returns around it; a 1-tile threshold plate on the floor | none — the plate is its mark | `door_key_click` (dry one-shot on open) | never |
| **Boss door** | `DOOR` | `OPEN` / `SEALED` | **full face — no sliver.** The room beyond is not shown; the door is a wall that admits | **2-tile dressed jamb + crown band** in the epoch's frame member (A `#9DAEB9` / B bone `#D9BC8F`) | the **sigil glyph** (once per jamb + once on the crown) | `door_seal_hum` (proximity loop) → `door_seal_exhale` (one-shot on the open arc) | the open arc only (below) |
| **Mini-boss door** (§2) | `DOOR` | `OPEN` / `SEALED` | slab with a **barred top quarter** — a slice of the beyond's light | **1-tile dressed jamb** + a narrower crown | one sigil, smaller, on the face | `door_seal_hum_small` (same family, +1 octave, −6 dB) | same exhale rule |

The tier read is value-first and survives grayscale (art bible P2): the face separates from the wall by ≥ 2 ramp steps; the dressed frame reads as *added weight* (the doorway grows, not glows); the refused mark reads by contour.

### The boss door's five elements

**1. The face — sealed, never absent.** The boss door's closed state is a full face: the doorway reads as *wall that has been addressed* — no gap, no sliver, no light from the beyond. This is the grammar's core distinction: a passage shows you the next room; a keyed door shows you a barrier with edges; a boss door shows you a decision. The face's material is the enclosing wall's current-epoch material with the frame's dressing — the door belongs to its truth (in A it is a stenciled bulkhead plate; in B it is a banded gothic leaf: **same geometry, wrong world**, the isomorphism law at door scale). The face never animates while closed (stillness is the tell).

**2. The frame — the address.** The boss door's opening is dressed: jamb bands 2 tiles thick (32 px) on both sides plus a crown band across the top, rendered in the epoch's frame member (`PROV_A_FRAME` / `PROV_B_FRAME`) — the art bible's shape-carrier exemplar slot. Ordinary openings are bare cuts in the coursing; the boss doorway's dressing makes the doorway *heavier* than the wall around it. The 2-tile width is deliberate and load-bearing: SYS-32's look-ahead commit is `LOOKAHEAD_PX` 32 — **the dressed frame arrives exactly inside the eye's read window**, so the approach tell fires where the frame's attention already is. The dressing is symmetric and identical on every boss door (no per-boss variation — variation is meaning spent elsewhere).

**3. The sigil glyph — the mark of the answered door.** A small closed form (≤ 8×8 px at art scale), symmetric, readable as a single shape at 32 px: in truth A it renders as a **stenciled plate mark** (the print layer's diegetic ink — a stamped hazard/serial plate on the plate-face); in truth B the same contour renders as a **carved wax seal** (relief, value-only — the same glyph, pressed into the truth's material). The glyph appears once on each jamb and once on the crown (the mini door: once, on the face). The glyph is the door's only ornament; it is shape, not color — a colorblind read survives on contour and value. It says one thing: *this opening has an owner; passing it is an event.*

**4. The approach tell — three signals, one lesson.** On approach to any boss-grade door, three signals fire, each independently legible:
- **The threshold plate**: a 1-tile band of the frame tone laid across the floor at the door's mouth (both keyed and boss doors carry it; the boss door's plate is flush with its 2-tile jambs, so the plate + frame compose one gesture).
- **The dressed frame** in the look-ahead window (element 2's 32-px rhyme).
- **The door-note** (element 5) — heard *before* the frame renders, at a proximity reach of roughly two rooms.

The teach plan: door 1 (the Denial arena's) fires all three together and the player cannot miss the composite. Every later door repeats the same three. By the third boss door any single signal suffices — the test below (§1 Playtest checks) verifies the read.

**5. The audio door-note — named for the sound-designer.** Four cues, all SYS-04 designs against edges SYS-02 must publish (SYS-02's MVP audio list is closed; publication is an Open Question):

| Cue | Shape | When | Why this shape |
|---|---|---|---|
| `door_seal_hum` | a low, slow sub-loop (2 s, no pulse, no melody — a held breath under hearing) | while a boss door's face is CLOSED and the player is in proximity (fade window ≈ 2 rooms' distance; louder on approach, never a positional ping) | the closed door is *waiting*; the hum is the pressure without a pointing glow (P3-honest: audio carries what light may not) |
| `door_seal_exhale` | one-shot resolve, descending, ≤ 700 ms — the arc's own length | on the open ack, riding the committed arc | the door answers; the accent fill (below) is its visual twin |
| `door_key_click` | dry, short, mechanical one-shot | the keyed door's open arc | the ordinary lock is a click; the boss door is a breath — the contrast teaches tier by ear |
| `door_refusal_thud` | one heavy, dead knock-back (no ring, no rattle) | when a `SEALED` door refuses a press | the refusal is the absence of the exhale; the thud is the door declining to answer — paired with the hum *dimming for one beat* (an automation dip, not a new loop) |

Mini-boss doors reuse the family at reduced treatment: `door_seal_hum_small` (+1 octave, −6 dB) and the same `exhale`/`thud` at smaller weight. One note family, two sizes — the recognition survives the size reduction by ear.

### The states: ADMITTING and REFUSING

- **ADMITTING** — the door's unlock condition holds: prompt `OPEN`, the face unchanged, the hum steady. Opening runs SYS-02's ordinary arc; at the arc the **accent fill** fires (the grammar's one allowed color event, below) and `door_seal_exhale` plays.
- **REFUSING** — the door's condition does not hold yet: prompt **`SEALED`** (Class B, 6 chars — the boss-grade refusal word; the hub door keeps its own `LOCKED`), and the sigil glyph carries the **denied bar**: a single wide, flat horizontal bar struck across the glyph — value-only, contour-carried. The bar deliberately borrows SYS-13's **denied lean** (the wide flat extension family that reads *not now / step out*): the player already owns that shape's meaning from combat; the door speaks the same dialect. The refusal is otherwise silent and still — pressing it binds, the publisher refuses (SYS-02's Class B path: one telemetry record, no arc, no unlock; the reason is the answer), the hum dims one beat with the `thud`. No error flash, no shake, no accent — **the accent never appears on a refusal**; absence is the message.

**The accent fill (the grammar's one color event).** During the open arc only (≤ 700 ms), the sigil glyph's seam-line fills with **the current epoch's truth accent** — A: monitor cyan `#4FC8DC`; B: candlelight amber `#E8A94A` — a single continuous fill, not a flash (the ≤ 3 flashes/s law holds trivially). It is the door *answering*: the same geometry, the wrong world, and the truth's own voice signing the admission. The accents appear nowhere else in the door grammar — never as a persistent lit edge (a lit boss door is a pointing device; art bible P3 bans beckoning). The fill is truth-keyed like everything else: the event re-materializes with the epoch.

### The opened state

After the arc, the door is a passage forever (SYS-02's world-truth law). The grammar shows the history honestly: the face **parks** — the slab retracts into the crown's dressing and remains visible as furniture at the doorway's head (the parked slab is the door's *past tense*: on every later crossing the player reads "this was addressed"). The glyph stays; the hum stops (an open door has nothing to wait for). The denial arena's exit is its script's tail (SYS-14's), so its door re-presents on return as: parked slab, glyph, no hum.

### Mini-boss doors — same grammar, smaller treatment

The grammar re-appears at mini-boss doors with exactly these reductions (nothing else varies):

| Element | Boss door | Mini-boss door |
|---|---|---|
| Face | full face, no sliver | slab with a **barred top quarter** — one slice of the arena's light leaks over the door |
| Frame | 2-tile jamb + crown | 1-tile jamb + a narrower crown |
| Glyph | jamb pair + crown | one, smaller, on the face |
| Hum | `door_seal_hum` | `door_seal_hum_small` |
| Refusal | `SEALED` + the denied bar | identical (`SEALED` + the denied bar) |
| Accent fill | the open arc only | identical |
| Threshold plate | 1-tile band | identical |

The two-step the size reduction teaches: **a boss door shows no light; a mini door shows a slice.** Full concealment = the grief-boss (the lie's room admits no preview); a slice = the exam's room, previewed but not entered. The recognition test (below) asserts a cold player codes the mini door as "the same kind of door" from any one signal, without reading the glyph.

### What a boss door may never be (the anti-grammar)

- **Never red.** `PROV_SIGIL_RED` is the lord's reservation (the art bible §4.4); no door wears it. The one recorded exception, taught last and only after the baseline is owned: **the court's own door** may dress in earned red — a deviation that reads as *his door* precisely because every other door kept the grammar. Deviation-as-meaning requires the baseline; there is no baseline exception before the court.
- **Never per-boss themed.** No second grammar. The door does not preview the boss's palette, silhouette, or motif — the *room* and the *title card* do that. The grammar's stability is what lets later deviations mean something.
- **Never pulsing, never numbered, never nameplated.** No counter, no HP hint, no boss name on the door — the title card is the naming surface, not the door.
- **Never pointing.** No persistent lit edge, no glow, no beacon. The only color event in the grammar is the open arc's fill.

### Playtest checks (falsifiable)

- **The recognition read**: at one screen's distance, n ≥ 5 cold testers shown the boss door (closed) code ≥ 4/5 as "something important/final is behind this" (forced choice vs a passage and a keyed door), 0 coding it as "ordinary locked door".
- **The mini read**: the mini door codes ≥ 4/5 as "same kind of door, smaller" — the grammar's recognition survives the reduction.
- **The teach curve**: by the third boss-grade door in a session, ≥ 4/5 testers anticipate "a fight" from any single signal (plate / frame / hum) before the prompt reads.
- **The refusal read**: a refused press codes as "not yet" (not "broken") — 0 failure-catch tokens (`stuck/buggy/broken` — the F3 anti-code bar applies to doors too).

---

## 2. MINI-BOSS PLACEMENT RULES

### The doctrine: the exam, not the lesson

A mini-boss is a **skill exam standing between parts**. It never teaches a new verb — regular rooms and regular enemies teach verbs (SYS-13's ladder: the Husk's swat, the Spitter's orb, the Warden's poise). A mini-boss **combines verbs already taught under one pressure** and stamps them "passed" before the next part's threshold. This keeps the mini-boss from competing with the grief-boss (SYS-14's rig owns the lesson-fight) and keeps encounter density honest: the exam's difficulty is *composition*, never *novelty*.

The rules:

1. **One per part, minimum one, never adjacent.** Every part of the multi-part arc (the errand structure — one grief state per part) carries at least one mini-boss; no two mini-bosses within 3 room-crossings of each other (encounter-density breathing — the exam must be an event, not a gauntlet).
2. **The door precedes.** Every mini-boss stands behind a mini-boss-grade door (§1's grammar, smaller treatment). The card names what the door promised (§ Title cards).
3. **Exactly one siting role per mini-boss.** The four admitted siting classes:
   - **(a) The gate-guard** — behind the door that opens the route into the next part's threshold. The critical-path exam.
   - **(b) The changed-corridor guard** — placed in a familiar corridor that has *changed* between visits (the D-ORCH-21 payoff: the changed place's new sentence has a warden). See §3's ambush budget.
   - **(c) The key-guard** — on an optional route, guarding a shortcut/backtrack key or a rich optional cache. Never the only route forward.
   - **(d) The foreshadow** — sited so its silhouette rhymes the coming grief-boss (the halo echo). Teaches nothing new; its lesson is *attention*.
4. **The duel-room rule.** A mini-boss room is authored single-screen-ish: 30–40 tiles wide (480–640 px; the room-graph minimum is the floor), flat flow with at most 1–2 elevation changes, at most one interior hazard rect (or none — the fight is the threat), and the playable interior authored inside the thumb-band discipline as an authoring habit. **No camera hold machinery at this tier** — the arena hold is SYS-14's grief-boss law (TR-CAM-012/TR-GBF-017); a mini-boss lives in the ordinary follow, and the room's smallness *is* the staging (the room is the stage; the frame barely moves).
5. **The retreat law — no seal, reset by the world's own word.** No arena-seal machinery at this tier (the seal is SYS-14's authored drop, priced by SYS-07's kinematics). If the player retreats through the mini door mid-fight, SYS-02's room-lifetime law does the honest thing: the room's local state dies with the room (TR-RWS-011) — the exam resets, the door stands open both ways, and re-entry re-applies the fight. The world does not chase; it does not cheat; it simply re-deals.
6. **The persistence law — resolves once.** A mini-boss's defeat is **world truth** (the doors' law extended): it resolves exactly once; re-crossings are plain passages; the room's spawn list never re-applies a resolved mini-boss. *Contract-adjacent cost:* the save's five source families (TR-RWS-025) gain a `mini_bosses_resolved` family, and the spawn list needs an epoch/flag-keyed variant — raised in Open Questions (OQ-LD-2/3).
7. **The card rule — the door names, the card confirms.** The title card fires on the mini door's open-arc **completion** (the crossing lands on the arena anchor), never on aggro. What the door promised, the card names.

### The title-card treatment

The prototype already renders boss title cards; the grammar generalizes:

| Property | Grief-boss card (SYS-14's) | Mini-boss card |
|---|---|---|
| Type tier | headline **32** (the art bible's boss-name tier) | subhead **24** — one step down, same family |
| Content | the state's name (the rig's face) | the name only — never a tier, number, or subtitle |
| Dwell | the fight's own quiet (per SYS-14's beats) | **1200 ms**, then a 200 ms fade |
| The world | the fight's intro owns it | **no hold, no context** — gameplay continues; the enemy's first decision is cadence-gated until the card dismisses (an authored intro beat on the room's data, the SYS-14 `INTRO_BEAT_MS` pattern at this tier, never new machinery) |
| Color | per the art bible's print discipline | identical: bone/void ink, **never red**, no accents |
| Placement | the card's anchor (upper third, centered) | identical anchor |
| Re-fires | — | in full on first entry; after a reset (retreat law), a **400 ms hold** replaces the full card (re-attempts skip the ceremony, keep the mark) |

**Names are working placeholders** — the naming voice is the writer's (flagged OQ-LD-6); the treatment is this doc's.

### The four candidates

Sources are cited pack-root → file family; all promotion goes through the art bible's pack-normalization audit (the 16-px grid law, the placeholder rule — nearest existing tone, value band first) at the Aseprite canonical pass. D-ORCH-22 clears the licenses.

**MB-1 — THE BEAST** *(the gate-guard; Errand 1 → 2 threshold)*
Sprite source: `WereWolf` pack / `Legacy Collection\...\Gothicvania\Characters\WereWolf\` — `werewolf.ase`; idle 5 frames, run 6, jump 2, fall 2. Truth: B (the candlelit truth's beast — it arrives *with* the flip).
Lesson: **hold your read under a closing enemy.** The run is the pressure (closing speed the roster's regulars lack), the leap is the exam: an unclashable wide arc (SYS-13's **denied family** — *step out*) plus a pounce (vertical-lift — *meet it*). Composition exam of the dash read + the lean read, taught separately in Errand 1's rooms.
Siting: the **changed-corridor guard** — pre-flip the corridor it haunts is empty; post-flip the beast is the change's first warden (§3's pattern, its loudest single use).

**MB-2 — THE ANGEL** *(the foreshadow; Errand 2 — the church quarter)*
Sprite source: `gothicvania church files\...\Assets\SPRITES\angel\` — `angel.ase` (f-01..f-03; few frames = cheap to produce, telegraph carried by reframe + flash per the doctrine).
Lesson: **the counter's discipline under a grand telegraph.** Strict, slow, poise-complete (the Warden's `telegraph_active` law at exam scale): every strike is meetable-or-deniable and the counter-stance is the only efficient answer.
Siting: **(d) foreshadow** — at the church quarter's ascent, guarding the tower stair. The halo is the point: its silhouette pre-echoes Arnetria's ring and crown (SYS-14's halo; D-ORCH-19's mirror visor) — the player meets the *shape* of the coming goodbye before the woman wearing it. It fights fair and it is wrong the way the Denial is wrong: something sacred, repurposed.

**MB-3 — THE WATCHER** *(the changed-places guardian; Errand 3 — Bargaining, the backtracking era)*
Sprite source: `Night Moth Reaper Idle\Air\` — `Night Moth Reaper_Fly_Idle` (20-frame fly idle; the idle *is* the kit).
Lesson: **the air exam — reading a mover.** A hoverer: the fly-idle's reframes are its telegraphs (lean = the strike's shape family; the flash carries the band per the doctrine). Teaches striking a thing that does not stand still, under SYS-13's honest-window rules.
Siting: **(b) changed-corridor guard**, with a law of its own: **the Watcher never appears in a room's first visit.** It is the fauna of the difference itself — it manifests only in rooms that changed (placed by the same mutation sets that change the room). Truth-agnostic (`reality_variant: null` — it belongs to the change, not to either truth; the one creature that is the same in both worlds, which is exactly what makes it wrong). Meeting it *means* the room changed — a spatial tell with a body.

**MB-4 — THE ENFORCER** *(the key-guard; Errand 4 — Depression's region, the machine city)*
Sprite source: `cyberpunk city 2 files\Assets\Sprites\cop\` — idle 3 frames, run 10 frames.
Lesson: **the deflect exam under movement.** Ranged pressure (the orb language's lineage — the Spitter's charge orb scaled to exam pressure) plus the run-in punish when the deflect misses; composition exam of deflect + spacing.
Siting: **(c) key-guard** — on the approach to the city, guarding the shortcut key back to the part's threshold (the backtracking era's reward route). Truth: A (the demon-future's street authority — the register's "watchful" mood given a body).

**Alternates on the shelf** (recorded, unplaced): the **Shrieking Ghost** (`Gothicvania Swamp files\Sprites\Ghost\` — appear/chase/shriek/vanish; a phase-shifter — alternate for MB-3's slot if the Watcher's air exam reads too similar to the orb work); the **Spider** (`Gothicvania Swamp files\Sprites\Spider\` — crawler pressure, alternate for MB-1); the **Sword Fox** (`Magic-Cliffs-Gamekit\...\sprites\fox-sword\` — an agile duelist, alternate for MB-2's counter exam); the **Turret** (`cyberpunk-street-files\...eg-turreet\` — the static variant, alternate for MB-4's ranged exam); the **Sunny Dragon** (`Legacy Collection\...\Misc\Characters\sunny-dragon\` — a second air option).

**Errand 5 carries none.** The Acceptance approach has no mini-boss, no changed-place trick, no ambush: the last approach is the cleanest walk in the game — the grammar's final use is one boss door, and the goodbye deserves an honest road. (A part with no exam is a pacing decision, recorded so its absence is not read as an omission.)

### Pack-provenance and normalization notes

- All cited sprites live in `inbox/downloads/organized/art/` (the tracked `assets/art/` copies carry LICENSE records only — D-ORCH-22's sweep formalizes the license evidence per pack).
- Promotion law (unchanged, restated for this doc's consumers): every mini-boss sprite passes the art bible's pack-normalization audit — the 16-px grid, the shared outline discipline, saturation harmonization, the placeholder rule (owning pack's nearest existing tone, value band first) — before any palette claim; value-first legibility is re-verified at grayscale after the re-skin.
- Frame economy: the cited sources are animation-light (the Angel's 3 frames, the Watcher's single idle). The telegraph doctrine's shape-flash vocabulary carries the weight — reframe + flash + hold, never opacity pulses. This is the cheap way to make four exams from three idles, and it is doctrine-compliant by construction.

---

## 3. THE CHANGED-PLACE PATTERN (D-ORCH-21)

### The law: Same Bones, New Sentence

A familiar room may change between visits — that is the game's spine (the flip, the epoch, the tells). The pattern that keeps it legible:

> **The bones are the memory; the sentence is the change.** A changed room keeps every bone that names it, and may change exactly one *sentence* — what you can do there — spoken through those same bones.

Recognition first, change second, in that order, every time. The player's déjà vu is the product (art bible P1); the change only lands *because* the recognition landed first.

### What CHANGES between visits

Every change is drawn from machinery that already exists — the epoch's re-skin (SYS-09/10) and the mutation registry's closed vocabulary (SYS-02 TR-RWS-012/013; SYS-10's three effect types). The change classes, in escalation order:

| # | Class | What it is | Machinery | Loudness |
|---|---|---|---|---|
| 1 | **The re-skin** | the room's material re-resolves to the new epoch (steel → candlelight; the key-light's direction moves beside) | `truth_epoch` + the palette map (F-RWS-04) | quiet — zone-wide, ambient |
| 2 | **The opened wall** | a partition's collision derives open; a route that did not exist now does | `GATE_OPEN(gate_id)` | loud — the first crossing is a held arc |
| 3 | **The materialized zone** | an interior zone's own material rule applies where the enclosing wall's used to render | `ZONE_MATERIALIZE(zone_id)` | loud |
| 4 | **The exposed content** | an interactable's reach derives from the set's closure (a memory, a cache) | `INTERACT_EXPOSE(target_id)` | quiet-loud — the reward is the point |
| 5 | **The repopulation** | the room's spawn list reads differently after the change (new pressure, or an emptied room) | *needs machinery today* — spawn lists have no epoch key (OQ-LD-3) | loud |
| 6 | **The re-purpose** | the room's function changes: a combat room now hosts a cache terminal; a hazard closet now opens | composition of 2–4 above | loudest — budget one per part |
| 7 | **The pocket** | a room that did **not** change, inside changed surroundings — the pristine lie at room scale (the Denial arena's `epoch_pin: 0` is the type instance) | `epoch_pin` (V-RWS-17: at most one per zone) | inverse-loud — the unchanged room is the loudest statement of all |

A room's **epoch state** per SYS-10: a room never owns an epoch — the zone's `truth_epoch` is its state, plus its own `epoch_pin` (null = re-skins with the zone; pinned = holds its truth forever). A room's changed-ness is always measured **relative to the last visit**: the accounting is `(visit's epoch, mutation sets applied at that visit)` vs the current truth — never an absolute list (this is what keeps the pattern epoch-ladder-safe when the VS arc raises `max_epoch` past 1: a room crossed at epoch 0 and re-crossed at epoch 2 has changed twice; the loop budget in the next section counts *changes between visits*, not epochs).

### The seam's role (SYS-11)

The seam presentation is **epoch-invariant** — the liminal material does not re-skin (TR-DR-012); the corridor is the fixed point that makes every later two-truth crossing legible. What can change about a room's seam relationship:
- **Additive only**: a room may *newly adjoin* the liminal (a new seam-side placement — new segments in new rooms, the span/array contract is general). 
- **Never by mutation**: existing seam segments never re-skin, re-time, or re-route; no changed room ever renders seam material where it did not (the 2-second negative-identifiability bar, VR-SMB-09, would catch the wrongness — "unfinished/corrupted" reads).
- **The seam never closes or reacts** (TR-SMB-012's fetch-flag ruling): a changed place's pattern never uses the seam as a state machine.

### What NEVER changes (the recognition invariant)

The identity geometry — byte-identical by SYS-02's validated invariant (TR-RWS-012's geometry-identity fixture), honored by the art bible's absolute shared-geometry rule (the visual twin). Concretely, the bones list a changed room keeps:

1. **The arch rhythm and the doorway cuts** (openings' positions and sizes — the borders' `opening_rect`s are authored once; a mutation opens a *new* partition, it never re-cuts an existing opening).
2. **The floor level, the stair runs, the drop's depth** (traversal geometry, TR-RWS-023).
3. **The wall's coursing phase** (the coursing is phase-aligned to world y ≡ 0 mod 16 — the same masonry "grain" every visit).
4. **The hero shapes** (arches, the back wall, foreground furniture per the art bible's hero/support split) — silhouette-level.
5. **The anchors' spots and the bounds** (anchor safety is boot law, V-RWS-03; the bounds are the room's word, TR-RWS-006).
6. **The room's identity** (its `room_id`, its name, its place in the graph; the shared edges stay flush, V-RWS-16).

**The changed place never kills.** No new hazard is placed on a memorized stride without a full-screen-visible read — the telegraph doctrine is the world's law too (SYS-13's *shown, not landed* extends to the room's new sentence), and D-ORCH-20 removes the fall's lethality besides: the changed route must be readable at walk speed, and what gates it gates by *pressure* (a warden, a wall), never by a trapdoor. A changed function may *refuse* (SEALED, the denied bar); it may not *punish unseen*.

### The first-revisit law

- The player's **first re-entry** into any changed room happens on a route they chose — the carrot (a counter's missing item, a story's open question), never a forced corridor. The world answers the telling, not the walker (SYS-10's law, made spatial: the level never *marches* the player through a change).
- The **first crossing of a mutation-opened route is a held, framed arc** — SYS-02's reveal-arc law (TR-RWS-009) generalized as the pattern's presentation rule: every change class ≥ 2's first crossing gets the arc + a framing zone (SYS-32's input), shown not sprung. One arc per change, once: later crossings are plain walk-throughs.
- The **game's first changed room is the authored canonical reveal** (RM-03's Cistern — the Cold Corridor wing). Every later changed room is a quieter rhyme of it, never a louder one: escalation comes from *meaning* (what the change says), not from *volume* (how hard the room announces).

### THE PACING RULE — the loop budget

A **backtrack loop** = one outbound leg from a settled point (a cache, a hub, a part threshold) through ≥ 2 previously-visited rooms to a new threshold, and the return leg. The budget:

| Budget line | Rule |
|---|---|
| **Mechanical changes** | **exactly one** function-changed room per loop (classes 2–6). Never two — the change is an event, not an ambient condition. |
| **The bookend rule** | no two function-changed rooms adjacent on the graph; a changed room is bookended by ≥ 1 unchanged room on each side of its traversal. The unchanged rooms are the player's proof the world is still legible. |
| **The ratio** | across a loop's re-entered familiar rooms: **1 changed : 3 unchanged** (the recognition debt is paid before the next novelty is spent). |
| **The tell settle** | ≤ 2 tells per loop "settle" into afterlife (SYS-10's settled tell — the noticing is past; the walk-past is the reward). |
| **The ambush** | ≤ 1 mini-boss arrival per loop (MB-1's class-b siting); never in the loop's first re-entered room (let the recognition land before the warden does). |
| **The pocket** | **one per part** (not per loop) — the unchanged room amid change, used as the part's statement. At most one `epoch_pin` room per zone stands behind it (V-RWS-17's law is the machinery's mirror). |
| **The part arc** | across a part's loops, the change escalates: the flip's paint-only loop (class 1 only) → one-function loops → the re-purpose (class 6) as the part's late statement → the pocket as the part's close. Never regress — the epoch's monotonic law, made spatial. |

The rule of thumb for authoring: **if a loop cannot say its one change in one breath ("the beast is in the corridor now"), it has two changes and needs another loop.**

### The Twine handoff (spatial only)

The Twine story tree (D-ORCH-21) keys on exactly what the room data can answer — the pattern keeps it spatial:

- **Node id**: `room_id` + visit-state: `first` / `epoch_n` / `changed_<set_id>` / `pocket`. Every changed room's tree has **two text states minimum** — the remembered voice (what the bones still say) and the changed voice (the new sentence) — and the branch keys are the triples the level data carries: `(room_id, truth_epoch, mutation sets applied)`.
- **The vocabulary is closed**: the Twine author picks from the change classes above; a change class the room data cannot answer does not exist in the tree. No new branch kind without a new mutation effect (a contract revision, never a silent edit).
- **The tells' text rule carries over** (SYS-10's TR-WME-008, generalized): changed-room text may dramatize in the house's own voice; it never inventories the change, never confirms the noticing, never varies by an epoch-conditional *re-read*.

Worked instances: the **canonical** one is RM-03's reveal (authored, in-system: `GATE_OPEN` + `ZONE_MATERIALIZE` + `INTERACT_EXPOSE` — the pattern's type specimen). An **invented production** one, vocabulary-clean: the **Courtyard's perch** (M2 long taken) — post-flip revisit: same bones (the perch, the one-way floor, the pit's mouth), the one-way drop now descends into a **materialized crawlspace** (`ZONE_MATERIALIZE`) holding the errand's cache terminal (`INTERACT_EXPOSE`): the drop you feared becomes the way down — the room's sentence flips from "the perch you lost" to "the cellar you found," spoken entirely through bones you already knew.

---

## OPEN QUESTIONS (I cannot decide these — owner + when)

| # | Question | Owner | When |
|---|---|---|---|
| OQ-LD-1 | **`SEALED` as a second Class B label** (the boss/mini door's refusal word; ≤ 8 chars, V-RWS-10-compatible). Needs SYS-01's label registry admission, SYS-24's render, and SYS-02's label fixture update. The prototype validates the word first (v3). | game-designer (with SYS-01/SYS-24's owners) | At the GDD resume, before the first production door story |
| OQ-LD-2 | **Mini-boss defeat persistence** — a `mini_bosses_resolved` truth-flag family joining SYS-03's five save source families (TR-RWS-025), or an equivalent registered-flag route with no schema growth. | game-designer + technical-director (schema cost) | At the GDD resume, with SYS-03's authoring |
| OQ-LD-3 | **Epoch/flag-keyed spawn lists** — the repopulation change class needs either a 4th mutation effect type (`SPAWN_SET(...)`, a contract revision to SYS-10's closed 3-type vocabulary) or double-authored per-epoch spawn lists in room data. | game-designer + systems-designer | At the multi-part zone-plan authoring (SYS-02's next touch) |
| OQ-LD-4 | **Mini-boss archetype registrations** — tier/hp/poise/strike rows for MB-1..MB-4 on SYS-13's registry (my lesson + shape-family notes are level-design intent, not authored values). | systems-designer + game-designer | Per part, at each part's plan authoring |
| OQ-LD-5 | **The title card's contract home** — my recommendation: mini-boss cards are non-blocking (no SYS-05 context; an authored intro beat on room data). SYS-24 renders; SYS-05 rules whether any context is owed. | game-designer + ux-designer | At the GDD resume |
| OQ-LD-6 | **Mini-boss names** — working names in §2 are placeholders; the naming voice is the writer's. | writer + narrative-director | At the part-plan authoring |
| OQ-LD-7 | **The door-note edges** — `door_seal_hum` / `door_seal_exhale` / `door_key_click` / `door_refusal_thud` (+ the `_small` variants) need SYS-02 to publish the edges (the MVP audio list is closed) and SYS-04 to design against them; the prototype SFX plan lane can validate placeholders. | game-designer (edge publication) + audio-director (design) | SYS-02's next doc touch / SYS-04's authoring |
| OQ-LD-8 | **Which mini-bosses are canonical for which parts** — §2 proposes MB-1..MB-4 with siting classes; the user picks the canon. | user (creative director) | At the part-plan approval |
| OQ-LD-9 | **The changed-place pattern's contract landing** — §3 is a pattern, not a rule set in any GDD; its budget lines (the loop budget, the bookend rule) should ride SYS-02's room-data authoring guidance at the multi-part plan. | game-designer | At the multi-part zone-plan authoring |

---

## SYS-11 OQ-6 — THE WING FIXTURES LIST (owned here, per SYS-11's OQ table)

SYS-11 OQ-6's fixture half is mine (co-owned with technical-artist; the south-termination note's SYS-09 rider half rides SYS-09's next touch). The ruling:

**1. The MVP fixture set is `[]` — and that is the design, not an omission.** The wing ships austere: coursing is the only texture, the ramp is the only light, the grief tint's single admitted voice sits at M4. The corridor's honesty *is* its plainness (the anti-code bar — "unfinished/corrupted" — is kept honest by the coursing continuity and the sourceless plane, not by props). No fixture ships at MVP.

**2. The admission policy for any future seam-room's fixtures.** A fixture is a **decoupled, value-only decal** inside the wing's fill; it is admitted only if all hold:
1. Zero collision fields (SYS-11's zero-collision law, TR-SMB-001, is absolute — fixtures are decals, never geometry).
2. Non-interactive, non-breakable, no interaction volume (TR-SMB-012's hidden-passage probe stays clean).
3. Rendered only in the four ramp members + their derived course shades — no new hue, never the grief tint, never the accents.
4. ≤ 2 cells per fixture; ≤ 2 fixtures per seam-room; ≥ 3 tiles from M4's anchor and never on its 1-tile ring.
5. Never on the band or the north row (the frame columns carry the offset law alone, VR-SMB-04).
6. Joins `fixtures[]` in the `SeamBorderContract` → the placement hash + the boot check (a moved/removed fixture is a boot failure — SYS-11's recorded rule).
7. Any admitted tint's alpha is 0 at fixtures (P3's mask excludes them).
8. Passes the negative 2-second read: a fixture may never create a door/portal/loading/unfinished read.

**3. The admitted fixture classes (named — for future seam-rooms only; nothing else qualifies):**
- **(a) The settled course-break** — a 1–2 cell interruption of the coursing phase: the masons' mark made stone. The corridor is older than the argument between the truths; one deliberate irregularity is the oldest thing in the room, and the only texture the austerity law can afford.
- **(b) The undersupport shadow** — a two-cell darker course at the fill's lower edge (the bridge's mass suggested under the floor plane), value-only, within ramp members.

Not admitted, ever: props (statuary, furniture, debris), light sources (a torch in a sourceless corridor is a pointing device and a second light model — the ramp's exclusivity, VR-SMB-02, dies with it), bevels/cracks/carvings (the coursing grammar's ban), anything animated.

**4. The south termination (the spatial ruling, for SYS-09's rider).** The wing's south edge is RM-03's south bound itself. The terminal `PROV_LIM_LIGHT` plane runs **flush into the bound wall**: the floor is continuous to the wall — no step, no ledge lip, no exit notch, no lit strip; M4 stands against the south wall on the LIGHT plane's last course. The wing has exactly one opening — the north mouth through the band. **The corridor is a vault, not a crossing.** The entry is the only way in; the memory is the only reason to be there; the room's word ends at the wall it has always ended at.

---

## Appendix — the cited pack inventory (filename-level, no images opened)

| Pack root (`inbox/downloads/organized/art/…`) | Cited sources |
|---|---|
| `WereWolf` / `Legacy Collection\...\Gothicvania\Characters\WereWolf\` | `werewolf.ase` · idle 5 / run 6 / jump 2 / fall 2 (+ spritesheets) |
| `gothicvania church files\…\Assets\SPRITES\angel\` | `angel.ase` · f-01..f-03 |
| `Night Moth Reaper Idle\Air\` | `Night Moth Reaper_Fly_Idle` · 20-frame sq sequence |
| `cyberpunk city 2 files\Assets\Sprites\cop\` | idle 3 / run 10 |
| `Gothicvania Swamp files\Sprites\Ghost\` (alt) | `Ghost.ase` · Flying 1–4 (+ Legacy Collection's ghost-appear/chase/shriek/vanish sheets) |
| `Gothicvania Swamp files\Sprites\Spider\` (alt) | `spider.ase` · walk 1–4 |
| `Magic-Cliffs-Gamekit\Assets\Enemies Files\sprites\fox-sword\` (alt) | fox-sword 1–8 (+ `fox` 1–8) |
| `cyberpunk-street-files\…\eg-turreet\` (alt) | the turret sprite family |
| `Legacy Collection\...\Misc\Characters\sunny-dragon\` (alt) | `sunny-dragon-fly` sheet |

Image guardrail honored: pack exploration was filename/metadata-only; no pack image was opened this session.
