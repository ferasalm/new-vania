# Q6 audit: find ceiling traps and too-high jumps in the library and lab.
# Plain words: for every spot she can stand on, is there room for her head plus a
# little spare (36 px tall + 8 px spare = 44 px)? And is every climb step no more
# than 80% of her best jump (68 px, so 54 px)?
# usage: python tests_quick/q6_audit.py [room ids...]   (default: library lab)
import sys, os

TILE = 16
STAND = 36.0            # her standing height (player.gd BODY = 12x36)
HEAD_SPARE = 8.0
CLEAR = STAND + HEAD_SPARE          # 44 px of air needed above a platform
JUMP_APEX = 325.0 * 325.0 / (2 * 780.0)   # 67.7 px, from tuning.json
JUMP_LIMIT = 0.8 * JUMP_APEX              # 54.2 px: no climb step above this

BLOCKER = set('#B%|:')   # things that stop her body; '=' and 'v' are one-way

def load(rid):
    path = os.path.join('rooms', rid + '.txt')
    lines = open(path, encoding='utf-8').read().split('\n')
    head = dict(kv.split('=', 1) for kv in lines[0].split(',') if '=' in kv)
    g = [l for l in lines[1:] if l.strip()]
    W = max(len(r) for r in g)
    g = [r.ljust(W, '#') for r in g]
    return head, g

def cell(g, x, y):
    if x < 0 or x >= len(g[0]): return 'E'
    if y < 0: return '^' if g[0][x] == '^' else '#'
    if y >= len(g): return 'v' if g[-1][x] == 'v' else '#'
    return g[y][x]

def free(g, x, y): return cell(g, x, y) not in BLOCKER and cell(g, x, y) != 'E'
def body(g, x, y): return free(g, x, y) and free(g, x, y - 1) and free(g, x, y - 2)
def sup(g, x, y): return cell(g, x, y + 1) in BLOCKER or cell(g, x, y + 1) in '=v'

def audit(rid):
    head, g = load(rid)
    H, W = len(g), len(g[0])
    print('== %s (%dx%d)  clear>=%g px, jump step<=%g px (apex %g)' % (rid, W, H, CLEAR, JUMP_LIMIT, JUMP_APEX))
    # 1. ceiling clearance on every standable spot (holes in the floor/ceiling
    #    are not platforms: skip cells that are themselves '^' or 'v')
    bad_clear = []
    stand = set()
    for y in range(H):
        for x in range(W):
            if cell(g, x, y) in '^v':
                continue
            if body(g, x, y) and sup(g, x, y):
                stand.add((x, y))
                # surface = bottom of cell y; find lowest blocker above
                yy = y - 3
                while yy >= 0 and free(g, x, yy): yy -= 1
                if yy < 0:
                    top = 0 if g[0][x] != '^' else -16
                else:
                    top = (yy + 1) * TILE
                space = (y + 1) * TILE - top
                if space < CLEAR:
                    bad_clear.append((x, y, space))
    if bad_clear:
        for x, y, s in bad_clear:
            print('   CLEARANCE: stand cell (%d,%d) has only %g px above (need %g)' % (x, y, s, CLEAR))
    else:
        print('   clearance ok on all %d stand cells' % len(stand))
    # 2. group stand cells into platforms, list climbs between near platforms.
    #    a hop is only real if her head has room for it: the rise is capped by
    #    the air above the platform she jumps FROM.
    plats = {}
    headroom = {}
    for (x, y) in stand:
        surf = y + 1  # platform row (the row that holds her up)
        plats.setdefault(surf, set()).add(x)
    for surf, xs in plats.items():
        ys = surf - 1
        yy = ys - 3
        while yy >= 0 and free(g, list(xs)[0], yy): yy -= 1
        top = (yy + 1) * TILE if yy >= 0 else (0 if g[0][list(xs)[0]] != '^' else -16)
        headroom[surf] = surf * TILE - top
    rows = sorted(plats)
    for i, r2 in enumerate(rows):
        for r1 in rows[i + 1:]:
            rise = (r1 - r2) * TILE
            if rise <= 0 or rise > JUMP_APEX + 4: continue
            if rise > headroom.get(r1, JUMP_APEX): continue   # ceiling above the takeoff caps the hop: she cannot attempt it
            xs2, xs1 = plats[r2], plats[r1]
            # near horizontally? within a jump's sideways reach (6 tiles)
            near = [abs(a - b) for a in xs2 for b in xs1 if abs(a - b) <= 7]
            if near:
                tag = 'TOO HIGH' if rise > JUMP_LIMIT else 'ok'
                print('   JUMP %s: row %d (top %d) -> row %d (top %d) rise %d px, dx up to %d' %
                      (tag, r2, r2 * TILE, r1, r1 * TILE, rise, max(near)))
    if not bad_clear:
        pass

for rid in (sys.argv[1:] or ['library', 'lab']):
    audit(rid)
