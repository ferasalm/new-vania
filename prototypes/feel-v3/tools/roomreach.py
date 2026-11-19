# PROTOTYPE - NOT FOR PRODUCTION
"""Can she get there? Grid model of her moves in every room (TILE 16).
jump rises 4 tiles (67.7 px), wall jump 3 more (57.7 px, once per air), sideways 6 tiles in a jump,
floor-hole pop 3 tiles. Body = 3 tiles. Crawl = 1 tile. '=' holds her from above only.
usage: python roomreach.py <feel-v3 dir> [--closed] [--nogrip] [rooms...]"""
import sys, os, glob
from collections import deque
root = sys.argv[1]; args = sys.argv[2:]
GATES_OPEN = '--closed' not in args; GRIP = '--nogrip' not in args
only = [a for a in args if not a.startswith('--')]
R, D, R2, D2, RPOP, DFALL = 4, 6, 3, 4, 3, 6

def analyse(rid):
    lines = open(os.path.join(root, 'rooms', rid + '.txt'), encoding='utf-8').read().split('\n')
    head = dict(kv.split('=', 1) for kv in lines[0].split(',') if '=' in kv)
    g = [l for l in lines[1:] if l]
    H = len(g); W = max(len(r) for r in g); g = [r.ljust(W, '#') for r in g]
    solid = set('#B') | (set() if GATES_OPEN else set('|%:'))
    def c(x, y):
        if x < 0 or x >= W: return 'E'
        if y < 0: return '^' if g[0][x] == '^' else '#'
        if y >= H: return 'v' if g[H - 1][x] == 'v' else '#'
        return g[y][x]
    def free(x, y): ch = c(x, y); return ch != 'E' and ch not in solid
    def body(x, y): return free(x, y) and free(x, y - 1) and free(x, y - 2)
    def sup(x, y): ch = c(x, y + 1); return ch in solid or ch in '=v' or (ch == ':' and x in (0, W - 1))
    exits = set()
    cache = {}
    def memo(key, fn):
        global_ex = set(exits)
        if key in cache:
            r, ex = cache[key]; exits.update(ex); return r
        exits.clear(); r = fn(); ex = set(exits)
        cache[key] = (r, ex); exits.clear(); exits.update(global_ex | ex); return r
    def edge_exit(x, y):
        if x in (0, W - 1):
            ch = g[min(max(y, 0), H - 1)][x]
            side = 'left' if x == 0 else 'right'
            if ch in 'DX<>:': exits.add(side)
            elif ch == '.' and head.get(side): exits.add(side)
            elif ch == '.': exits.add('LEAK-' + side)
    def fall(x, y): return memo(('f', x, y), lambda: _fall(x, y))
    def _fall(x, y):
        out, seen, q = [], set(), deque([(x, y, 0)])
        while q:
            ax, ay, d = q.popleft()
            if (ax, ay, d) in seen: continue
            seen.add((ax, ay, d)); edge_exit(ax, ay)
            if ay >= H: exits.add('down'); continue
            if sup(ax, ay): out.append((ax, ay)); continue
            if c(ax, ay + 1) not in solid: q.append((ax, ay + 1, d))
            if d < DFALL:
                for nx in (ax - 1, ax + 1):
                    if body(nx, ay): q.append((nx, ay, d + 1))
        return out
    def air(x, y, rise, side, grip): return memo(('a', x, y, rise, side, grip), lambda: _air(x, y, rise, side, grip))
    def _air(x, y, rise, side, grip):
        res, seen, q = [], set(), deque([(x, y, 0, 0)])
        while q:
            ax, ay, r, d = q.popleft()
            if (ax, ay, r, d) in seen: continue
            seen.add((ax, ay, r, d)); res.append((ax, ay)); edge_exit(ax, ay)
            if ay <= -1: exits.add('up'); continue
            if r < rise and body(ax, ay - 1): q.append((ax, ay - 1, r + 1, d))
            if d < side:
                for nx in (ax - 1, ax + 1):
                    if body(nx, ay): q.append((nx, ay, r, d + 1))
        if grip:
            more = []
            for ax, ay in set(res):
                if not free(ax - 1, ay - 1) or not free(ax + 1, ay - 1):
                    more += air(ax, ay, R2, D2, False)
            res = res + more
        return list(set(res))
    stand, crawl = set(), set()
    def explore(starts):
        q = deque(starts)
        while q:
            k, x, y = q.popleft()
            if k == 's':
                if (x, y) in stand: continue
                stand.add((x, y))
            else:
                if (x, y) in crawl: continue
                crawl.add((x, y))
            edge_exit(x, y)
            for nx in (x - 1, x + 1):
                if body(nx, y):
                    for p in fall(nx, y): q.append(('s',) + p)
                elif free(nx, y) and sup(nx, y): q.append(('c', nx, y))
            if k == 'c': continue
            if c(x, y + 1) == 'v': exits.add('down')
            if c(x, y + 1) == '=':
                for p in fall(x, y + 1): q.append(('s',) + p)
            for ax, ay in air(x, y, R, D, GRIP):
                for p in fall(ax, ay): q.append(('s',) + p)
    entries = []
    for y in range(H):
        for x in (0, W - 1):
            if g[y][x] in 'DX<>' and (y + 1 >= H or g[y + 1][x] not in 'DX<>'):
                entries.append((g[y][x] + '@%d,%d' % (x, y), [('s' if body(x, y) else 'c', x, y)]))
    for x in range(W):
        if g[0][x] == '^' and free(x, 1): entries.append(('^@%d' % x, [('s',) + p for p in fall(x, 0)]))
        if g[H - 1][x] == 'v':
            entries.append(('v@%d' % x, [('s',) + p for a in air(x, H - 1, RPOP, 5, GRIP) for p in fall(*a)]))
    for y in range(H):
        for x in range(W):
            if g[y][x] in 'PK': entries.append((g[y][x] + '@%d,%d' % (x, y), [('s',) + p for p in fall(x, y)]))
    probs, allst = [], set()
    for name, st in entries:
        stand.clear(); crawl.clear(); exits.clear()
        explore(st)
        allst |= stand
        ex = sorted(exits)
        if not [e for e in ex if not e.startswith('LEAK')]: probs.append('TRAPPED entering ' + name)
        for e in ex:
            if e.startswith('LEAK'): probs.append('open edge with no exit (%s) reached from %s' % (e[5:], name))
        for want in ('left', 'right', 'up', 'down'):
            if head.get(want) and want not in ex and name[0] in 'DX<>^vPK':
                probs.append('from %s she cannot reach the %s exit (%s)' % (name, want, head[want]))
    for y in range(H):
        for x in range(W):
            ch = g[y][x]
            if ch.isdigit() or ch in 'MT':
                if not any((sx, sy) in allst for sx in (x - 1, x, x + 1) for sy in (y - 1, y, y + 1)):
                    probs.append('mark %s at %d,%d unreachable' % (ch, x, y))
    return sorted(set(probs))

rooms = only or sorted(os.path.basename(f)[:-4] for f in glob.glob(os.path.join(root, 'rooms', '*.txt')))
for rid in rooms:
    try: p = analyse(rid)
    except Exception as e: p = ['ERROR %r' % e]
    print(('ok    ' if not p else 'CHECK ') + rid)
    for line in p: print('        ' + line)
