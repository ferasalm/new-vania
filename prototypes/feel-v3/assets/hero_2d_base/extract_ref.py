"""extract_ref.py -- extract the reference sheet's rows/cells for production.

Method: sprites stack vertically inside fixed column slots (~90px spacing).
Within one column slot, each frame is a clean vertical band. Rows = bands
aligned across columns (anchored to the densest column, nearest-y assignment).

Writes ref_lib/:
  rows.json          row -> cells (x/y boxes, column, frame order)
  cells/rXX_fYY.png  1x crop of every frame
  ascii/rXX.txt      per-row ASCII contact sheet (step=2, class letters)
  row_XX.png         per-row 1x montage (for human review)
"""
import json
import os
import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, 'complete-sprites-reference.png')
OUT = os.path.join(BASE, 'ref_lib')
os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, 'cells'), exist_ok=True)
os.makedirs(os.path.join(OUT, 'ascii'), exist_ok=True)

im = Image.open(SRC).convert('RGB')
a = np.array(im)
Hh, Ww = a.shape[:2]
green = (a[:, :, 0] == 0) & (a[:, :, 1] == 255) & (a[:, :, 2] == 0)
teal = (a[:, :, 0] == 0) & (a[:, :, 1] == 128) & (a[:, :, 2] == 128)
content = ~green & ~teal

# ---- column centers from x-density peaks (smoothed) -----------------------
xdens = content.sum(axis=0)
xs = np.convolve(xdens, np.ones(31) / 31, 'same')
peaks = []
for x in range(4, Ww - 4):
    if xs[x] >= xs[x - 4] and xs[x] >= xs[x + 4] and xs[x] > 25:
        if not peaks or x - peaks[-1] > 40:
            peaks.append(x)
        elif xs[x] > xs[peaks[-1]]:
            peaks[-1] = x
print('columns:', peaks)

# ---- per-column vertical bands (each band = one frame) --------------------
all_bands = []
for j, cx in enumerate(peaks):
    x0 = max(0, cx - 45)
    x1 = min(Ww, cx + 45)
    col = content[:, x0:x1]
    has = col.any(axis=1)
    runs = []
    s = None
    for y in range(Hh):
        if has[y] and s is None:
            s = y
        elif not has[y] and s is not None:
            runs.append((s, y - 1))
            s = None
    if s is not None:
        runs.append((s, Hh - 1))
    for (ry0, ry1) in runs:
        h = ry1 - ry0 + 1
        if not (24 <= h <= 96):
            continue
        sub = col[ry0:ry1 + 1]
        xr = np.where(sub.any(axis=0))[0]
        w = int(xr.max() - xr.min() + 1)
        if w < 10:
            continue
        all_bands.append(dict(col=j, x0=int(x0 + xr.min()),
                              x1=int(x0 + xr.max()), y0=int(ry0), y1=int(ry1)))

# drop bands whose box overlaps a bigger band in the same column (trails etc.)
by_col = {}
for b in all_bands:
    by_col.setdefault(b['col'], []).append(b)
kept = []
for j, bands in by_col.items():
    bands.sort(key=lambda b: b['y0'])
    for b in bands:
        dup = False
        for o in kept:
            if o['col'] == j and not (b['y1'] < o['y0'] - 2 or b['y0'] > o['y1'] + 2):
                ov = (min(b['y1'], o['y1']) - max(b['y0'], o['y0']) + 1)
                if ov > 0.6 * (b['y1'] - b['y0'] + 1):
                    dup = True
                    break
        if not dup:
            kept.append(b)
all_bands = kept
for j, bands in by_col.items():
    print('col %d (x~%d): %d frames' % (j, peaks[j], len(bands)))

# ---- rows: anchor on the densest column, assign nearest --------------------
anchor_col = max(by_col, key=lambda j: len(by_col[j]))
anchors = sorted(by_col[anchor_col], key=lambda b: b['y0'])
print('anchor col', anchor_col, 'rows', len(anchors))
rows = [[b] for b in anchors]
for b in all_bands:
    if b['col'] == anchor_col:
        continue
    yc = (b['y0'] + b['y1']) / 2
    best, bd = None, 1e9
    for ri, r in enumerate(rows):
        ryc = (r[0]['y0'] + r[0]['y1']) / 2
        d = abs(yc - ryc)
        if d < bd:
            best, bd = ri, d
    if bd <= 42:
        rows[best].append(b)
    else:
        rows.append([b])
rows.sort(key=lambda r: min(b['y0'] for b in r))

# ---- write outputs ----------------------------------------------------------
CLS = {'O': lambda r, g, b: r + g + b < 40,
       'C': lambda r, g, b: g > 110 and b > 110 and r < 110,
       'S': lambda r, g, b: r > 140 and r > g and g >= b - 10,
       'H': lambda r, g, b: r > 95 and g > 95 and b > 95 and abs(r - g) < 30 and abs(g - b) < 40}


def cls_letter(p):
    r, g, b = int(p[0]), int(p[1]), int(p[2])
    for ch, f in CLS.items():
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
for ri, r in enumerate(rows):
    r.sort(key=lambda b: b['x0'])
    row_y0 = min(b['y0'] for b in r)
    row_y1 = max(b['y1'] for b in r)
    entry = {'row': ri, 'y': [row_y0, row_y1], 'cells': []}
    # crops
    crops = []
    for fi, b in enumerate(r):
        img = im.crop((b['x0'], b['y0'], b['x1'] + 1, b['y1'] + 1)).convert('RGBA')
        bg = Image.new('RGBA', img.size, (0, 255, 0, 255))
        p = img.load()
        q = bg.load()
        for y in range(img.size[1]):
            for x in range(img.size[0]):
                if p[x, y][3] > 0:
                    q[x, y] = (p[x, y][0], p[x, y][1], p[x, y][2], 255)
        fp = os.path.join(OUT, 'cells', 'r%02d_f%02d.png' % (ri, fi))
        bg.convert('RGB').save(fp)
        crops.append(bg)
        entry['cells'].append({'x': [b['x0'], b['x1']], 'y': [b['y0'], b['y1']],
                               'col': b['col'], 'file': os.path.relpath(fp, BASE)})
    data.append(entry)
    # montage
    mh = max(c.size[1] for c in crops)
    mw = sum(c.size[0] + 2 for c in crops) + 2
    montage = Image.new('RGB', (mw, mh + 2), (0, 255, 0))
    ox = 2
    for c in crops:
        montage.paste(c.convert('RGB'), (ox, 1))
        ox += c.size[0] + 2
    montage.save(os.path.join(OUT, 'row_%02d.png' % ri))
    # ascii
    lines = []
    hh = max(len(cell_ascii(c)) for c in crops)
    grids = [cell_ascii(c) for c in crops]
    for y in range(hh):
        parts = []
        for g in grids:
            parts.append(g[y] if y < len(g) else ' ' * len(g[0]))
        lines.append(' '.join(parts))
    with open(os.path.join(OUT, 'ascii', 'r%02d.txt' % ri), 'w') as fh:
        fh.write('ROW %d  y=%d..%d  frames=%d\n' % (ri, row_y0, row_y1, len(r)))
        fh.write('\n'.join(lines))
        fh.write('\n')
    print('row %2d: y%4d-%4d frames=%d widths=%s' % (
        ri, row_y0, row_y1, len(r), [b['x1'] - b['x0'] + 1 for b in r]))

with open(os.path.join(OUT, 'rows.json'), 'w') as fh:
    json.dump(data, fh, indent=1)
print('total rows:', len(rows), 'total frames:', sum(len(r) for r in rows))
