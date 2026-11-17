"""extract_ref2.py -- reference sheet extraction, v2 (correct).

Rows: 52 y-bands anchored on the leftmost-column bands found in v1 (solid
~96px pitch). Frames: raw x-runs of content inside each row's band (frames
are packed with variable spacing, NOT fixed columns). Wide runs (palette
block, showcase art, merged trails) are dropped by width; tiny debris by
height. Rebuilds ref_lib/ completely.
"""
import json
import os
import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, 'complete-sprites-reference.png')
OUT = os.path.join(BASE, 'ref_lib')
for d in ('cells', 'ascii'):
    os.makedirs(os.path.join(OUT, d), exist_ok=True)

im = Image.open(SRC).convert('RGB')
a = np.array(im)
Hh, Ww = a.shape[:2]
green = (a[:, :, 0] == 0) & (a[:, :, 1] == 255) & (a[:, :, 2] == 0)
teal = (a[:, :, 0] == 0) & (a[:, :, 1] == 128) & (a[:, :, 2] == 128)
content = ~green & ~teal

# row anchors: the col==0 cells from v1's rows.json
with open(os.path.join(OUT, 'rows.json')) as fh:
    v1 = json.load(fh)
seeds = []
for entry in v1:
    c0 = [c for c in entry['cells'] if c['col'] == 0]
    if not c0:
        raise SystemExit('row %d has no col-0 seed' % entry['row'])
    seeds.append((c0[0]['y'][0], c0[0]['y'][1]))
assert len(seeds) == 52

CLS = [('O', lambda r, g, b: r + g + b < 40),
       ('C', lambda r, g, b: g > 110 and b > 110 and r < 110),
       ('S', lambda r, g, b: r > 140 and r > g and g >= b - 10),
       ('H', lambda r, g, b: r > 95 and g > 95 and b > 95 and abs(r - g) < 30 and abs(g - b) < 40)]


def cls_letter(p):
    r, g, b = int(p[0]), int(p[1]), int(p[2])
    for ch, f in CLS:
        if f(r, g, b):
            return ch
    return 'D'


def cell_ascii(img, step=2):
    px = img.load()
    w, h = img.size
    out = []
    for y in range(0, h, step):
        line = []
        for x in range(0, w, step):
            votes = {}
            for dy in range(step):
                for dx in range(step):
                    if x + dx < w and y + dy < h:
                        p = px[x + dx, y + dy]
                        if p[3] > 0:
                            v = cls_letter(p)
                            votes[v] = votes.get(v, 0) + 1
            line.append(max(votes, key=votes.get) if votes else '.')
        out.append(''.join(line))
    return out


data = []
total = 0
for i, (sy0, sy1) in enumerate(seeds):
    lo = sy0 - 18
    hi = sy1 + 18
    if i > 0:
        lo = max(lo, seeds[i - 1][1] + 1)
    if i < 51:
        hi = min(hi, seeds[i + 1][0] - 1)
    band = content[lo:hi + 1]
    cols = band.any(axis=0)
    runs = []
    s = None
    for x in range(Ww):
        if cols[x] and s is None:
            s = x
        elif not cols[x] and s is not None:
            runs.append([s, x - 1])
            s = None
    if s is not None:
        runs.append([s, Ww - 1])
    merged = []
    for r in runs:
        if merged and r[0] - merged[-1][1] <= 3:
            merged[-1][1] = r[1]
        else:
            merged.append(r)
    frames = []
    for rx0, rx1 in merged:
        w = rx1 - rx0 + 1
        if w < 10 or w > 80:          # debris or palette/showcase/merged junk
            continue
        sub = band[:, rx0:rx1 + 1]
        yr = np.where(sub.any(axis=1))[0]
        h = int(yr.max() - yr.min() + 1)
        if h < 20:
            continue
        frames.append({'x': [int(rx0), int(rx1)],
                       'y': [int(lo + yr.min()), int(lo + yr.max())]})
    frames.sort(key=lambda f: f['x'][0])
    entry = {'row': i, 'y': [int(min(f['y'][0] for f in frames)) if frames else lo,
                             int(max(f['y'][1] for f in frames)) if frames else hi],
             'cells': []}
    crops = []
    for fi, f in enumerate(frames):
        img = im.crop((f['x'][0], f['y'][0], f['x'][1] + 1, f['y'][1] + 1)).convert('RGBA')
        bg = Image.new('RGBA', img.size, (0, 255, 0, 255))
        p = img.load()
        q = bg.load()
        for y in range(img.size[1]):
            for x in range(img.size[0]):
                if p[x, y][3] > 0:
                    q[x, y] = (p[x, y][0], p[x, y][1], p[x, y][2], 255)
        fp = os.path.join(OUT, 'cells', 'r%02d_f%02d.png' % (i, fi))
        bg.convert('RGB').save(fp)
        crops.append(bg)
        entry['cells'].append({'x': f['x'], 'y': f['y'], 'col': fi,
                               'file': os.path.relpath(fp, BASE)})
    data.append(entry)
    total += len(frames)
    # montage
    if crops:
        mh = max(c.size[1] for c in crops)
        mw = sum(c.size[0] + 2 for c in crops) + 2
        montage = Image.new('RGB', (mw, mh + 2), (0, 255, 0))
        ox = 2
        for c in crops:
            montage.paste(c.convert('RGB'), (ox, 1))
            ox += c.size[0] + 2
        montage.save(os.path.join(OUT, 'row_%02d.png' % i))
        grids = [cell_ascii(c) for c in crops]
        hh = max(len(g) for g in grids)
        lines = ['ROW %d  y=%d..%d  frames=%d' % (i, entry['y'][0], entry['y'][1], len(crops))]
        for y in range(hh):
            lines.append(' '.join(g[y] if y < len(g) else ' ' * len(g[0]) for g in grids))
        with open(os.path.join(OUT, 'ascii', 'r%02d.txt' % i), 'w') as fh:
            fh.write('\n'.join(lines) + '\n')
    print('row %2d y%4d-%4d frames=%d widths=%s' % (
        i, entry['y'][0], entry['y'][1], len(frames),
        [f['x'][1] - f['x'][0] + 1 for f in frames]))

with open(os.path.join(OUT, 'rows.json'), 'w') as fh:
    json.dump(data, fh, indent=1)
print('TOTAL frames:', total)
