# Renders and checks the map sheets, then fills map.tmpl.md -> map.md (design aid only).
# map.tmpl.md holds the prose with {{PRE}}, {{POST}}, {{AFTER}} placeholders: edit prose THERE, never in map.md.
# Usage: python mapgen2.py   (prints 'ok <chars>' when the overlap and exit checks pass; exits with the errors otherwise)
# L/R exits carry a cell ROW offset, U/D a cell COLUMN offset.
# Kinds: = door, ~ low tunnel, o hole, L lever-locked, B boss door, X sealed door, : one-way shutter.
import os

CW, CH = 7, 2
HERE = os.path.dirname(os.path.abspath(__file__))


def sheet(rooms, exits):
    errs, occ, ex = [], {}, {}
    for rid, (x, y, w, h, lab) in rooms.items():
        for cx in range(x, x + w):
            for cy in range(y, y + h):
                if (cx, cy) in occ:
                    errs.append(f"overlap {rid}/{occ[(cx, cy)]}")
                occ[(cx, cy)] = rid
    for rid, side, off, tgt, kind in exits:
        x, y, w, h, _ = rooms[rid]
        cell, opp = {"L": ((x - 1, y + off), "R"), "R": ((x + w, y + off), "L"),
                     "U": ((x + off, y - 1), "D"), "D": ((x + off, y + h), "U")}[side]
        if occ.get(cell) != tgt:
            errs.append(f"{rid} {side}{off} -> {tgt}: cell {cell} holds {occ.get(cell)}")
            continue
        tx, ty = rooms[tgt][0], rooms[tgt][1]
        ex[(rid, side, off)] = (tgt, opp, cell[1] - ty if opp in "LR" else cell[0] - tx, kind)
    for (rid, side, off), (tgt, opp, toff, kind) in ex.items():
        if ex.get((tgt, opp, toff), (None,))[0] != rid:
            errs.append(f"one-sided exit {rid} {side}{off} -> {tgt}")
    if errs:
        raise SystemExit("\n".join(errs))
    W = max(r[0] + r[2] for r in rooms.values())
    H = max(r[1] + r[3] for r in rooms.values())
    can = [[" "] * (W * CW + 1) for _ in range(H * CH + 1)]
    for x, y, w, h, lab in rooms.values():
        x0, y0, x1, y1 = x * CW, y * CH, (x + w) * CW, (y + h) * CH
        for i in range(x0, x1 + 1):
            for j in (y0, y1):
                can[j][i] = "+" if can[j][i] == "+" or i in (x0, x1) else "-"
        for j in range(y0 + 1, y1):
            for i in (x0, x1):
                can[j][i] = "+" if can[j][i] == "+" else "|"
        for k, ch in enumerate(lab[: w * CW - 1]):
            can[y0 + 1][x0 + 1 + k] = ch
    for (rid, side, off), (tgt, opp, toff, kind) in ex.items():
        x, y, w, h, _ = rooms[rid]
        if side in "LR":
            can[(y + off) * CH + 1][x * CW if side == "L" else (x + w) * CW] = kind
        else:
            j = y * CH if side == "U" else (y + h) * CH
            i = (x + off) * CW + CW // 2
            can[j][i] = can[j][i + 1] = kind
    return "\n".join("".join(r).rstrip() for r in can)


pre = {
    "OR": (0, 2, 2, 1, "OR organ"), "HZ": (2, 2, 4, 1, "HZ $         #bars"),
    "WL": (4, 1, 1, 1, "WL lev"), "VA": (6, 2, 1, 1, "VA *"), "SH": (6, 3, 1, 2, "SH"),
    "CH": (7, 4, 3, 1, "CH @ start"), "SC": (9, 2, 1, 1, "SC $?"), "LB": (10, 2, 2, 3, "LB lever $"),
    "S2": (12, 2, 1, 1, "S2 *"), "LA": (13, 1, 3, 2, "LA"), "KN": (13, 0, 1, 1, "KN !"),
    "HW": (16, 2, 2, 1, "HW"), "PB": (18, 2, 1, 1, "PB !"), "GA": (17, 3, 3, 1, "GA  crabs  $"),
    "OW": (16, 1, 1, 1, "OW !"),
}
pre_exits = [
    ("OR", "R", 0, "HZ", "~"), ("HZ", "L", 0, "OR", "~"), ("HZ", "R", 0, "VA", "="), ("VA", "L", 0, "HZ", "="),
    ("HZ", "U", 2, "WL", "o"), ("WL", "D", 0, "HZ", "o"), ("VA", "D", 0, "SH", "o"), ("SH", "U", 0, "VA", "o"),
    ("SH", "R", 1, "CH", "L"), ("CH", "L", 0, "SH", "L"), ("CH", "R", 0, "LB", "="), ("LB", "L", 2, "CH", "="),
    ("SC", "R", 0, "LB", "="), ("LB", "L", 0, "SC", "="), ("LB", "R", 0, "S2", "="), ("S2", "L", 0, "LB", "="),
    ("S2", "R", 0, "LA", "="), ("LA", "L", 1, "S2", "="), ("LA", "U", 0, "KN", "o"), ("KN", "D", 0, "LA", "o"),
    ("LA", "R", 1, "HW", "="), ("HW", "L", 0, "LA", "="), ("HW", "R", 0, "PB", "B"), ("PB", "L", 0, "HW", "B"),
    ("HW", "D", 1, "GA", "o"), ("GA", "U", 0, "HW", "o"),
    ("LA", "R", 0, "OW", "B"), ("OW", "L", 0, "LA", "B"),
]
post = {
    "SC~": (0, 1, 1, 1, "SC~c3$"), "LB~": (1, 0, 2, 3, "LB~"), "HZ~": (3, 0, 4, 1, "HZ~ flames"),
    "BI": (4, 1, 1, 1, "BI c2"), "CH~": (3, 2, 3, 1, "CH~"), "LA~": (6, 1, 3, 2, "LA~"),
    "KN~": (7, 3, 1, 2, "KN~ c1"), "OR~": (7, 0, 2, 1, "OR~ @"), "VA~": (9, 0, 1, 1, "VA~"),
    "SH~": (9, 1, 1, 2, "SH~"), "AR": (10, 0, 2, 2, "AR  !!"),
}
post_exits = [
    ("OR~", "R", 0, "VA~", "="), ("VA~", "L", 0, "OR~", "="), ("VA~", "R", 0, "AR", "X"), ("AR", "L", 0, "VA~", "X"),
    ("VA~", "D", 0, "SH~", "o"), ("SH~", "U", 0, "VA~", "o"), ("SH~", "L", 1, "LA~", "="), ("LA~", "R", 1, "SH~", "="),
    ("LA~", "D", 1, "KN~", "o"), ("KN~", "U", 0, "LA~", "o"), ("LA~", "L", 1, "CH~", "="), ("CH~", "R", 0, "LA~", "="),
    ("CH~", "U", 1, "BI", "o"), ("BI", "D", 0, "CH~", "o"), ("CH~", "L", 0, "LB~", "="), ("LB~", "R", 2, "CH~", "="),
    ("LB~", "L", 1, "SC~", "~"), ("SC~", "R", 0, "LB~", "~"), ("LB~", "R", 0, "HZ~", "="), ("HZ~", "L", 0, "LB~", "="),
    ("HZ~", "R", 0, "OR~", ":"), ("OR~", "L", 0, "HZ~", ":"),
]
after = dict(pre, AR=(7, 2, 2, 2, "AR (visor)"))
after_exits = pre_exits + [("VA", "R", 0, "AR", "="), ("AR", "L", 0, "VA", "=")]

text = open(os.path.join(HERE, "map.tmpl.md"), encoding="utf-8").read()
text = text.replace("{{PRE}}", sheet(pre, pre_exits)).replace("{{POST}}", sheet(post, post_exits))
text = text.replace("{{AFTER}}", sheet(after, after_exits))
open(os.path.join(HERE, "map.md"), "w", encoding="utf-8", newline="\n").write(text)
print("ok", len(text))
