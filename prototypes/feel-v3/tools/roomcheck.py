# PROTOTYPE - NOT FOR PRODUCTION
import glob, os, sys
SOLID = set('#B|%:')
def load(f):
    lines = open(f, encoding='utf-8').read().split('\n')
    return lines[0], [l for l in lines[1:] if l]
def solid(g, x, y):
    if y < 0 or y >= len(g) or x < 0 or x >= len(g[y]): return True
    return g[y][x] in SOLID
issues = []
for f in sorted(glob.glob(sys.argv[1] + '/rooms/*.txt')):
    rid = os.path.basename(f)[:-4]
    head, g = load(f)
    W = len(g[0]); H = len(g)
    if any(len(r) != W for r in g): issues.append(f'{rid}: ragged rows {sorted(set(len(r) for r in g))}')
    for y in range(H):
        for x in (0, W - 1):
            ch = g[y][x]
            inner = 1 if x == 0 else W - 2
            if ch in 'DX':
                # door: she stands at the inner cell with feet on row y+1 top: rows y, y-1, y-2 must be clear at the edge and inner cells
                blocked = [(xx, yy) for yy in (y, y - 1, y - 2) for xx in (x, inner) if (xx, yy) != (x, y) and solid(g, xx, yy)]
                if blocked: issues.append(f'{rid}: door {ch} at ({x},{y}) head blocked at {blocked}')
                if not (solid(g, inner, y + 1) or g[y+1][inner] == '='): issues.append(f'{rid}: door at ({x},{y}) has no floor under the inner cell')
            if ch in '<>' and (y + 1 >= H or g[y + 1][x] != ch):
                h = 0; yy = y
                while yy >= 0 and g[yy][x] == ch: h += 1; yy -= 1
                kind = 'TUNNEL(slide)' if h * 16 < 36 else 'tall'
                print(f'   {rid}: open edge {ch} rows {y-h+1}-{y} h={h} {kind}')
    # floor passages: count columns where the walkable height above a floor is < 3 (crawl) or < 1
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if not solid(g, x, y) and solid(g, x, y + 1):
                clear = 0; yy = y
                while yy >= 0 and not solid(g, x, yy): clear += 1; yy -= 1
                if clear < 3:
                    issues.append(f'{rid}: low spot ({x},{y}) clear={clear}')
    print(f'{rid}: {W}x{H} head={head}')
print('\n'.join(issues))
