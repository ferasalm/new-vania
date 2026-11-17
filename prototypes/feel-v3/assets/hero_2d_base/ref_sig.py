"""ref_sig.py -- compact numeric signature per reference cell for triage.

For every row/frame of complete-sprites-reference.png prints one line:
  size, mass, centroid, top/bottom, face cluster (topmost big skin cluster),
  other skin clusters (hands/feet), hair cluster, and an identity group id
  (frames whose bottom-center-anchored class-map are identical share a group).
Also prints aligned (bottom-anchored) mask XOR diff vs the previous frame --
the activity measure used to spot cycles vs holds.

Writes ref_lib/sig.txt. Read-only w.r.t. the source sheet.
"""
import hashlib
import json
import os
import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(BASE, 'ref_lib')
A = np.array(Image.open(os.path.join(BASE, 'complete-sprites-reference.png')).convert('RGB'))

rows = json.load(open(os.path.join(OUT, 'rows.json')))

CANVAS_W, CANVAS_H = 80, 72


def classify(a):
    r = a[:, :, 0].astype(int)
    g = a[:, :, 1].astype(int)
    b = a[:, :, 2].astype(int)
    content = ~((r == 0) & (g == 255) & (b == 0)) & ~((r == 0) & (g == 128) & (b == 128))
    skin = content & (r > 140) & (r > g) & (g >= b - 10)
    hair = content & (r > 95) & (g > 95) & (b > 95) & (np.abs(r - g) < 30) & (np.abs(g - b) < 40)
    outline = content & (r + g + b < 40)
    cls = np.zeros(a.shape[:2], np.uint8)      # 0 empty,1 outline,2 dark,3 skin,4 hair
    cls[content] = 2
    cls[outline] = 1
    cls[skin] = 3
    cls[hair] = 4
    return content, cls


def clusters(mask, min_size=4, limit=4):
    """Largest connected components of a mask: (size, cy, cx) list."""
    seen = np.zeros_like(mask, bool)
    out = []
    ys, xs = np.where(mask)
    for y, x in zip(ys, xs):
        if seen[y, x]:
            continue
        pts = 0
        sy = sx = 0
        stack = [(y, x)]
        seen[y, x] = True
        while stack:
            py, px = stack.pop()
            pts += 1
            sy += py
            sx += px
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = py + dy, px + dx
                    if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] \
                       and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if pts >= min_size:
            out.append((pts, sy // pts, sx // pts))
    out.sort(reverse=True)
    return out[:limit]


lines = []
for entry in rows:
    ri = entry['row']
    lines.append('ROW %2d  y=%d..%d  frames=%d' % (ri, entry['y'][0], entry['y'][1],
                                                   len(entry['cells'])))
    prev_canvas = None
    groups = {}
    for fi, cell in enumerate(entry['cells']):
        x0, x1 = cell['x']
        y0, y1 = cell['y']
        a = A[y0:y1 + 1, x0:x1 + 1]
        content, cls = classify(a)
        ys, xs = np.where(content)
        h = int(ys.max() - ys.min() + 1)
        w = int(xs.max() - xs.min() + 1)
        mass = int(content.sum())
        cx, cy = xs.mean(), ys.mean()
        top, bot = int(ys.min()), int(ys.max())
        sk = clusters(cls == 3)
        hr = clusters(cls == 4)
        # bottom-center anchored canvas for alignment + identity
        canvas = np.zeros((CANVAS_H, CANVAS_W), np.uint8)
        oy = CANVAS_H - h - 1
        ox = CANVAS_W // 2 - w // 2
        canvas[oy:oy + h, ox:ox + w][ys - ys.min(), xs - xs.min()] = cls[ys, xs]
        gid = hashlib.md5(canvas.tobytes()).hexdigest()[:4]
        groups.setdefault(gid, []).append(fi)
        d = -1
        if prev_canvas is not None:
            d = int((canvas != prev_canvas).sum())
        prev_canvas = canvas
        face = '(%d,%d)' % sk[0][1:] if sk else '-'
        hands = '|'.join('(%d,%d)' % c[1:] for c in sk[1:3]) or '-'
        hairc = '(%d,%d)' % hr[0][1:] if hr else '-'
        lines.append(' f%d %2dx%2d m%4d top%2d bot%2d cy%2d face%s sk:%s hair%s cx%2d d%5d =%s'
                      % (fi, w, h, mass, top, bot, cy, face, hands, hairc, cx, d, gid))
    ident = ' '.join('=' + g + ':' + ','.join(map(str, f)) for g, f in groups.items()
                     if len(f) > 1)
    lines.append('   groups: ' + (ident or 'all distinct'))

open(os.path.join(OUT, 'sig.txt'), 'w').write('\n'.join(lines) + '\n')
print('wrote ref_lib/sig.txt lines=%d' % len(lines))
