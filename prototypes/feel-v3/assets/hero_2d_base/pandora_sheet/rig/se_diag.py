"""se_diag.py -- locate the uncovered pixel in the SE segmentation.

Prints where parts_se fails to tile base_se_112x80.png, with the part claims
around it, plus per-part counts and contested-pixel pair counts.
"""
import numpy as np
from PIL import Image
from pathlib import Path
from collections import defaultdict

RIG = Path(__file__).resolve().parent
PARTS = ('hair_back', 'cape', 'body', 'lower')
W, H = 112, 80

arr = np.array(Image.open(RIG / 'base_se_112x80.png').convert('RGBA'))
alpha = arr[:, :, 3] > 0

claims = defaultdict(list)
for n in PARTS:
    p = np.array(Image.open(RIG / 'parts_se' / (n + '.png')).convert('RGBA'))
    m = p[:, :, 3] > 0
    for y, x in zip(*np.where(m)):
        claims[(int(x), int(y))].append(n)
    print('%-10s opaque=%d' % (n, int(m.sum())))

cov = np.zeros((H, W), bool)
for (x, y) in claims:
    cov[y, x] = True

missing = alpha & ~cov
print('total base opaque=%d covered=%d missing=%d'
      % (int(alpha.sum()), int(cov.sum()), int(missing.sum())))
for y, x in zip(*np.where(missing)):
    x, y = int(x), int(y)
    print('missing px (%d,%d) rgb=%s' % (x, y, tuple(int(v) for v in arr[y, x][:3])))
    for dy in range(-2, 3):
        cells = []
        for dx in range(-2, 3):
            c = claims.get((x + dx, y + dy), [])
            cells.append(','.join(c) if c else '.')
        print('  y%-3d %s' % (y + dy, ' '.join('%11s' % c for c in cells)))

pairs = defaultdict(int)
for v in claims.values():
    if len(v) > 1:
        pairs[tuple(sorted(set(v)))] += 1
print('contested pairs:', {('+'.join(k)): v for k, v in sorted(pairs.items())})
