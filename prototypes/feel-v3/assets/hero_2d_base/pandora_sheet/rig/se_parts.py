"""se_parts.py -- segment the SE (south-east 3/4) idle sprite into parts.

Parts for the SE idle (fewer parts = fewer seams that can tear):
  hair_back : ponytail flow + crown/side redundancy bands (sways)
  cape      : left tattered tails + right tail (x61-66, y53-63) (sways)
  body      : head hair/face/hood + torso + both arms (breath-lifted whole)
  lower     : hips + legs + boots (static)

Contested seam pixels are written to MULTIPLE parts (redundant seams) so a
moving part reveals the part behind it instead of a hole; craft.prepare_parts
keeps that redundancy and BFS-fixes any uncovered pixel.
Every pixel comes from the user's sprite; nothing is drawn.
"""
import numpy as np
from PIL import Image
from pathlib import Path

RIG = Path(__file__).resolve().parent
BASE = RIG / 'base_se_112x80.png'
OUT = RIG / 'parts_se'
W, H = 112, 80

PARTS = ('hair_back', 'cape', 'body', 'lower')


def classify(arr):
    rgb = arr[:, :, :3].astype(int)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    cls = np.full((H, W), 'dark', dtype=object)
    cls[(r + g + b) < 40] = 'outline'
    cls[(g > 110) & (b > 110) & (r < 110)] = 'cyan'
    cls[(r > 140) & (r > g) & (g >= b - 10)] = 'skin'
    cls[(r > 95) & (g > 95) & (b > 95) & (abs(r - g) < 30) & (abs(g - b) < 40)] = 'hair'
    return cls


def main():
    base = Image.open(BASE).convert('RGBA')
    arr = np.array(base)
    alpha = arr[:, :, 3] > 0
    cls = classify(arr)
    yy = np.arange(H)[:, None].repeat(W, 1)
    xx = np.arange(W)[None, :].repeat(H, 0)
    y, x = yy, xx

    hair = (cls == 'hair') & alpha
    dark = ((cls == 'dark') | (cls == 'outline')) & alpha
    cyan = (cls == 'cyan') & alpha
    skin = (cls == 'skin') & alpha

    # redundancy bands: pixels claimed by BOTH sides of a moving seam
    crown_band = hair & (y >= 9) & (y <= 25) & (x >= 44) & (x <= 52)
    neck_band = dark & (y >= 12) & (y <= 22) & (x >= 44) & (x <= 46)

    cape = dark & (
        ((x <= 46) & (y >= 36) & (y <= 58)) |          # left tails (upper)
        ((x <= 52) & (y >= 43) & (y <= 58)) |          # left tails (lower, wider)
        ((x >= 61) & (x <= 66) & (y >= 53) & (y <= 63))  # right tattered tail
    )
    cape &= ~neck_band

    parts = {n: np.zeros((H, W, 4), np.uint8) for n in PARTS}

    def put(n, m):
        parts[n][m] = arr[m]

    # --- hair_back: ponytail flow, strand over far arm, bands
    put('hair_back', hair & ((y >= 12) & (x <= 49)))
    put('hair_back', hair & (y >= 26) & (x <= 52))     # strand over far arm
    put('hair_back', crown_band)
    put('hair_back', dark & (x <= 46) & (y <= 35))     # ponytail outline zone
    put('hair_back', neck_band)

    # --- body: head (crown/bangs/face/hood) + torso + both arms
    put('body', hair & ((y <= 11) | ((x >= 50) & (y <= 25))))
    put('body', crown_band)
    put('body', neck_band)
    put('body', skin)                                   # face + upper arms
    put('body', dark & (y <= 17) & (x >= 47))           # hood / face outline
    put('body', dark & (y >= 18) & (y <= 47) & (x >= 47) & ~cape)
    put('body', cyan & (y <= 47))                       # V emblem, eye, gauntlet trim

    # --- cape
    put('cape', cape)

    # --- lower: hips + legs + boots (static); hip rows contested with body
    put('lower', dark & (y >= 43) & (x >= 53) & ~cape)
    put('lower', cyan & (y >= 43))                      # leg + boot seams
    put('lower', hair & (y >= 48))                       # leg highlight grays
    # (hair-classified light grays below y48 are leg highlights -- e.g. the
    # px (55,68) that was the one uncovered pixel; the ponytail never
    # reaches below y35, so geometrically these belong to the legs)

    OUT.mkdir(exist_ok=True)
    for n, im in parts.items():
        Image.fromarray(im, 'RGBA').save(OUT / f'{n}.png')

    # coverage + exactness proof
    cov = np.zeros((H, W), bool)
    for n in parts:
        cov |= parts[n][:, :, 3] > 0
    missing = alpha & ~cov
    print('missing pixels:', int(missing.sum()))
    comp = np.zeros((H, W, 4), np.uint8)
    for n in ('hair_back', 'lower', 'cape', 'body'):
        m = parts[n][:, :, 3] > 0
        comp[m] = parts[n][m]
    same = (comp == arr).all(axis=2) | (arr[:, :, 3] == 0)
    print('composite exact:', bool(same.all()), 'diff px:', int((~same).sum()))
    for n in parts:
        m = parts[n][:, :, 3] > 0
        print('  %-10s opaque=%d' % (n, int(m.sum())))


if __name__ == '__main__':
    main()
