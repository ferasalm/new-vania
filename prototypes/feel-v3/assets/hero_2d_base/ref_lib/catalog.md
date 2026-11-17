# Reference Sheet Catalog — complete-sprites-reference.png

52 rows (row 0 = header/palette row), 307 frames total, sprite heights ~40-65px.
Character: brown hair, purple/blue coat, front 3/4 stance, ~46px tall, faces LEFT.
Usage rule: pose structure/timing only. NEVER copy pixels.

Identified by step-2 ASCII + numeric signatures (ref_lib/sig.txt, via ref_sig.py).
Confidence: (H) high, (M) medium, (L) low — ALL rows still get a user visual
check against ref_lib/row_XX.png montages before clip production.

| Row | y | Frames | Widths | Identification | Conf |
|-----|------|--------|--------|----------------|------|
| 0 | 0-95 | 4 | 21 | Header: character beside palette block; near-identical 4f idle copy | M |
| 1 | 98-143 | 6 | 21-22 | IDLE (front 3/4): 1px sway, foot shuffle variants, holds | H |
| 2 | 194-239 | 6 | 19-28 | BEND / PICK UP: 3 stand frames, tilt, full bend (hands to ground) | M |
| 3 | 291-335 | 6 | 27-33 | LEAP / DIVE: diagonal stretched poses, head up, feet trailing | M |
| 4 | 386-431 | 6 | 31-33 | FLIP / ACROBATIC: wide stances, stretch, inverted peak (f6) | M |
| 5 | 483-530 | 6 | 25-29 | HIGH KICK: balance arm raised, kick rises, held pointe f5-6 | M |
| 6 | 580-625 | 6 | 27-29 | STRAIN / PUSH-SHIFT: sustained bent pose w/ 1px shifts, stand at end | L |
| 7 | 676-726 | 6 | 27-41 | PRONE SEQUENCE: diagonal fall, flat spread (f2), roll head-left (f3), stand | L |
| 8 | 803-840 | 6 | 28-37 | ARMS-RAISED REACH: both arms up, chest skin clusters, sit-down end | L |
| 9 | 898-956 | 6 | 25-33 | AMBIGUOUS: big round mass w/ face center, possible two-figure frames | L |
| 10 | 1024-1071 | 9 | 28-30 | AMBIGUOUS: small figure atop big mass, then near-identical holds | L |
| 11 | 1120-1169 | 7 | 29-37 | Stand holds x3 -> wide stance -> progressive deep lean right (chains into r12) | L |
| 12 | 1248-1295 | 6 | 32-49 | 3 identical stands -> shared lean frame (r11 f4) -> wide arms-spread poses | L |
| 13 | 1344-1391 | 6 | 46-49 | ARMED STANCE: 3 near-identical pairs, held item right, micro-sway | M |
| 14 | 1443-1503 | 5 | 33-39 | SOMERSAULT/ROLL: inverted bend -> tuck x2 -> crouch w/ extension (shares frame w/ r33) | M |
| 15 | 1568-1631 | 6 | 39-40 | ITEM INTERACT: bend -> stand-hold x4 identical -> bend | L-M |
| 16 | 1696-1743 | 9 | 30-49 | CRAWL: short crouch-walks -> tuck ball x3 -> horizontal crawl (last frame opens r17) | M |
| 17 | 1792-1839 | 9 | 28-49 | CRAWL cont.: horizontal -> hands-planted cycle x4 -> rise x2 | M |
| 18 | 1898-1935 | 6 | 37-38 | DEEP BEND activity (scrub/crawl-idle): 2 variants + held x3 | L |
| 19 | 1984-2049 | 6 | 31-36 | RISE from bend -> tall lean/reach poses (chains 18->19->20) | L |
| 20 | 2112-2177 | 6 | 31-49 | Lean -> WIDE spread poses x3 (49px) -> hand-off frame | L |
| 21 | 2240-2303 | 6 | 31-46 | Left-facing holds x3 -> deep duck/bend x2 (chains from r20) | L-M |
| 22 | 2368-2431 | 5 | 39 | Stand w/ hands clasped front, settle (chains into r23) | L |
| 23 | 2496-2560 | 7 | 32-48 | FALL DOWN: stand x2 -> tall -> crouch ball -> lying flat | M-L |
| 24 | 2626-2671 | 8 | 20-56 | LIE FLAT x4 -> GET UP -> idle stance x4 | M-H |
| 25 | 2721-2783 | 6 | 20-26 | Bent stands -> kick up into HANDSTAND (inverted f4-5, hair at bottom) | M-L |
| 26 | 2848-2911 | 4 | 28-30 | HANDSTAND hold: inverted, micro-balance shifts | M |
| 27 | 2976-3055 | 4 | 23-26 | HANDSTAND variant: leg movement mid-hold | M |
| 28 | 3139-3202 | 5 | 29-39 | RISE from kneel: tall bent x2 -> wide mid x2 -> stand | L-M |
| 29 | 3268-3327 | 6 | 36-37 | SNEAK / CROUCH-WALK cycle (hands planted) | M-L |
| 30 | 3396-3441 | 6 | 23-50 | Crouch -> narrow -> wide flung-back spreads (fall/knockback) | L-M |
| 31 | 3491-3537 | 6 | 26-50 | HURT/SHUDDER: flung -> bent recoil -> stand x2 | L-M |
| 32 | 3584-3631 | 6 | 34-44 | DUCK (head down) x2 -> stretch up x3 | L |
| 33 | 3683-3743 | 6 | 27-43 | SOMERSAULT/FLIP + recovery (inverted x3, shares frame w/ r14) | M-H |
| 34 | 3811-3870 | 5 | 24-28 | THROW / LIFT OVERHEAD: wind-up -> arm-up tall x3 | L-M |
| 35 | 3946-3999 | 5 | 31-38 | SIT/KNEEL down-up cycle | L-M |
| 36 | 4070-4127 | 6 | 29-36 | Stand -> gesturing x4 -> lean-left slump | L |
| 37 | 4193-4254 | 5 | 24-28 | CLIMB/REACH-UP: stretched tall, hands left | L-M |
| 38 | 4323-4369 | 6 | 22-34 | Stand micro-shifts x4 -> arms-wide x2 | L |
| 39 | 4418-4463 | 6 | 21-34 | COMPOSE/WAKE: wide -> bent pair -> normal pair -> stand | L |
| 40 | 4512-4560 | 7 | 26-27 | SIT DOWN: progressive fold to seated, hand up | M-L |
| 41 | 4608-4655 | 8 | 25-36 | SEATED gestures x4 -> rise to stand x4 (continues r40) | M-L |
| 42 | 4711-4751 | 4 | 38-50 | LIE DOWN / FLAT ON BACK | M-H |
| 43 | 4803-4847 | 7 | 21-40 | GET UP from lying -> stand -> stretch bends (continues r42) | M-L |
| 44 | 4901-4943 | 6 | 27-34 | Progressive lean-left (peek), holds | L |
| 45 | 4997-5039 | 6 | 27-32 | Lean recovers -> arm-up stretch x4 | L |
| 46 | 5092-5135 | 6 | 28-32 | ARM SWING / exercise cycle | L |
| 47 | 5186-5231 | 6 | 21-36 | PUSH/SHOVE or shudder: bend -> straighten -> repeat | L-M |
| 48 | 5283-5327 | 6 | 26-42 | PULL/CARRY/LIFT: hands raised, shorter stance | L |
| 49 | 5378-5423 | 6 | 27-33 | Head-turn/hair-toss + hand-to-face | L |
| 50 | 5475-5519 | 6 | 30-34 | Ground interaction: hand to floor x4 | L |
| 51 | 5571-5615 | 2 | 24-31 | Two-frame: hand-up stand -> stand-at-ease | L |

## Structural findings (verified via ref_sig.py identity hashes)

- Rows CHAIN across boundaries via shared frames: 11->12, 16->17, 18->19->20->21,
  22->23, 30<->43, 31->39->40, 43->47, 49->50. Several "rows" are one long
  animation split by the sheet's layout.
- Reused pose anchors: =dc44 stand (r12), =cbcf stand-at-ease (r31/r39/r40),
  the 21x46 idle stance returns in r24 f4-6 after getting up.
- Orientation: the reference faces LEFT (face cluster sits in the left third
  of the idle bbox). Pandora faces right — mirror the pose language.
- **NO walk or run cycle exists anywhere in this sheet.** The library is an
  emote/interaction/action set (idle, acrobatics, crawl, handstands, lying,
  sitting, item interactions, falls). Runtime run16 (and crouch-attack,
  air-attack, backdash) have no direct template row and must be extended from
  the stance/pose language of nearby rows.
- Handstand family: rows 25 (entry) -> 26 (hold) -> 27 (variant).
  Lie/get-up family: r42 (lie) -> r43 (wake/get up) -> r44-46 (recovery bends).
  Sit family: r40 (sit down) -> r41 (seated -> rise).

## Runtime contract mapping (candidates, pending user verification)

- idle6: r1 — SUPERSEDED: idle_se already built from the user's own SE sprite.
- jump4: r3 (leap); land1: r23 crouch frames; crouch5: r32 duck (or r16 entry).
- hurt2: r31; dead4: r23 fall + r42 lying (r24 = getting back up, not for dead).
- cast5: r34 (arm overhead); attack chains: r13/r11-12 armed stances (no clean
  weapon-swing row exists — extend from r5 kick + r4 flip energy).
- run16, crouchatk, crouchatk2, airatk, airatk2, backdash4: no template rows.

Review pack for the user: ref_lib/row_00.png .. row_51.png (1x montages).
