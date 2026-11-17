"""detail_ascii.py -- step-1 ASCII render of reference rows for pose reading.

Usage: python detail_ascii.py <row> [<row> ...]
Row 0 special: header band y0..95, palette block excluded by width filter.
"""
import json
import os
import sys
import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, 'complete-sprites-reference.png')
OUT = os.path.join(BASE, 'ref_lib')

im = Image.open(SRC).convert('RGB')
a = np.array(im)
Hh, Ww = a.shape[:2]
green = (a[:, :, 0] == 0) & (a[:, :, 1] == 255) & (a[:, :, 2] == 0)
teal = (a[:, :, 0] == 0) & (a[:, :, 1] == 128) & (a[:, :, 2] == 128)
content = ~green & ~teal

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


with open(os.path.join(OUT, 'rows.json')) as fh:
    rows = json.load(fh)

for arg in sys.argv[1:]:
    ri = int(arg)
    if ri == 0:
        lo, hi = 0, 95
    else:
        entry = rows[ri]
        lo = entry['y'][0]
        hi = entry['y'][1]
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
        if w < 10 or w > 80:
            continue
        sub = band[:, rx0:rx1 + 1]
        yr = np.where(sub.any(axis=1))[0]
        if yr.max() - yr.min() + 1 < 20:
            continue
        frames.append((rx0, rx1, int(yr.min()), int(yr.max())))
    print('ROW %d  y%d..%d  %d frames' % (ri, lo, hi, len(frames)))
    grids = []
    for (rx0, rx1, ry0, ry1) in frames:
        sub = a[lo + ry0:lo + ry1 + 1, rx0:rx1 + 1]
        mask = content[lo + ry0:lo + ry1 + 1, rx0:rx1 + 1]
        grid = []
        for y in range(sub.shape[0]):
            line = []
            for x in range(sub.shape[1]):
                if mask[y, x]:
                    line.append(cls_letter(sub[y, x]))
                else:
                    line.append('.')
            grid.append(''.join(line))
        grids.append(grid)
    hh = max(len(g) for g in grids)
    for y in range(hh):
        print(' '.join(g[y] if y < len(g) else ' ' * len(g[0]) for g in grids))
    print()
