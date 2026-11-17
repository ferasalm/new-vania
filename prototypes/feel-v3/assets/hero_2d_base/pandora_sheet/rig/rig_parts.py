"""Segment the user's side-view Pandora sprite into animation parts.

Writes one full-canvas RGBA image per part plus a composite proof and pivots.
No drawing: every pixel comes from the user's sprite.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
BASE = ROOT / 'base_112x80.png'
OUT = ROOT / 'parts'
W, H = 112, 80

HAIR = {(213, 214, 232), (145, 145, 170), (111, 112, 141),
        (128, 126, 154), (178, 179, 203), (191, 192, 215)}
SKIN = {(225, 163, 130), (168, 107, 100), (198, 122, 108)}
CYAN = {(14, 199, 188), (16, 219, 210), (23, 157, 155), (17, 123, 134)}
DARK = {(71, 76, 93), (23, 9, 50), (27, 39, 54), (44, 53, 71),
        (35, 42, 57), (53, 77, 86), (65, 59, 99), (28, 16, 64)}
OUTLINE = {(0, 0, 0)}

PIVOTS = {
    'pelvis': (56, 45), 'chest': (56, 29), 'neck': (56, 24), 'head': (57, 15),
    'shoulder_n': (59, 29), 'elbow_n': (61, 36), 'hand_n': (62, 43),
    'hip_n': (58, 46), 'knee_n': (59, 61), 'ankle_n': (59, 71),
    'shoulder_f': (53, 29), 'elbow_f': (54, 36), 'hand_f': (53, 43),
    'hip_f': (54, 46), 'knee_f': (53, 61), 'ankle_f': (53, 71),
}


def classify(arr):
    rgb = arr[:, :, :3].astype(int)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    cls = np.full((H, W), 'dark', dtype=object)
    cls[(r + g + b) < 40] = 'outline'
    cls[(g > 110) & (b > 110) & (r < 110)] = 'cyan'
    cls[(r > 140) & (g > 80) & (g < 200) & (b > 60) & (b < 180) & (r > g) & (g >= b - 10)] = 'skin'
    cls[(r > 95) & (g > 95) & (b > 95) & (abs(r - g) < 30) & (abs(g - b) < 40)] = 'hair'
    return cls


def main():
    base = Image.open(BASE).convert('RGBA')
    arr = np.array(base)
    alpha = arr[:, :, 3] > 0
    cls = classify(arr)
    # local coordinates: sprite starts at x=41
    xs = np.arange(W)[None, :].repeat(H, axis=0)
    ys = np.arange(H)[:, None].repeat(W, axis=1)
    lx = xs - 41

    parts = {name: np.zeros((H, W, 4), np.uint8) for name in
             ('hair_back', 'cape', 'head', 'torso', 'arm_n', 'leg_n', 'leg_f')}

    def put(name, mask):
        parts[name][mask] = arr[mask]

    # Hair: everything silver outside the face; bangs go with the head.
    hair = (cls == 'hair') & alpha
    head_hair = hair & (lx >= 10) & (ys <= 20)
    put('hair_back', hair & ~head_hair)
    put('head', head_hair)

    # Skin: face goes to head, the rest is the near upper arm.
    skin = (cls == 'skin') & alpha
    put('head', skin & (ys <= 22))
    put('arm_n', skin & (ys > 22))

    # Head dark/outline: hood and face outline.
    head_dark = alpha & (ys <= 22) & (lx >= 10)
    put('head', (cls == 'dark') & head_dark)
    put('head', (cls == 'outline') & head_dark)

    # Cape: dark mass left of the body and below the shoulders.
    cape = alpha & (cls == 'dark') & (lx < 12) & (ys >= 28) & (ys <= 72)
    put('cape', cape)

    # Near arm: right-side skin/dark/outline below the head.
    arm_region = alpha & (lx >= 18) & (ys >= 22) & (ys <= 47)
    put('arm_n', (cls == 'dark') & arm_region)
    put('arm_n', (cls == 'outline') & arm_region)

    # Torso: central dark/cyan between the shoulders and hips.
    torso_region = alpha & (lx >= 8) & (lx <= 21) & (ys >= 18) & (ys <= 47)
    put('torso', (cls == 'dark') & torso_region)
    put('torso', (cls == 'cyan') & torso_region)

    # Legs: split at x=17 below the hips; cyan seams follow their leg.
    leg_region = alpha & (ys >= 46) & (ys <= 76)
    put('leg_n', (cls == 'dark') & leg_region & (lx >= 17))
    put('leg_n', (cls == 'cyan') & leg_region & (lx >= 17))
    put('leg_f', (cls == 'dark') & leg_region & (lx >= 8) & (lx < 17))
    put('leg_f', (cls == 'cyan') & leg_region & (lx >= 8) & (lx < 17))

    # Outlines in the leg/torso/cape regions follow the nearest filled part.
    leg_outline = alpha & (cls == 'outline') & leg_region
    put('leg_n', leg_outline & (lx >= 17))
    put('leg_f', leg_outline & (lx >= 8) & (lx < 17))
    put('cape', leg_outline & (lx < 8))
    torso_outline = alpha & (cls == 'outline') & torso_region & (ys < 46)
    put('torso', torso_outline & (lx < 18))
    put('arm_n', torso_outline & (lx >= 18))
    put('cape', alpha & (cls == 'outline') & (lx < 12) & (ys >= 28) & (ys <= 72))

    OUT.mkdir(parents=True, exist_ok=True)
    for name, image in parts.items():
        Image.fromarray(image, 'RGBA').save(OUT / f'{name}.png')

    # Any remaining opaque pixel joins the nearest logical part by region.
    comp_mask = np.zeros((H, W), bool)
    for name in parts:
        comp_mask |= parts[name][:, :, 3] > 0
    missing = alpha & ~comp_mask
    for y, x in zip(*np.where(missing)):
        r, g, b = (int(v) for v in arr[y, x, :3])
        if r > 95 and g > 95 and b > 95 and abs(r - g) < 30 and abs(g - b) < 40:
            target = 'hair_back'
        elif y <= 22:
            target = 'head' if x - 41 >= 10 else 'hair_back'
        elif x - 41 < 8 and y <= 34:
            target = 'hair_back'
        elif x - 41 < 12 and y >= 28:
            target = 'cape'
        elif x - 41 >= 18 and y <= 47:
            target = 'arm_n'
        elif y >= 46:
            target = 'leg_n' if x - 41 >= 17 else ('leg_f' if x - 41 >= 8 else 'cape')
        else:
            target = 'torso'
        parts[target][y, x] = arr[y, x]

    # Composite in z-order; verify it reproduces the base.
    order = ('hair_back', 'cape', 'leg_f', 'torso', 'leg_n', 'arm_n', 'head')
    comp = np.zeros_like(arr)
    for name in order:
        mask = parts[name][:, :, 3] > 0
        comp[mask] = parts[name][mask]
    Image.fromarray(comp, 'RGBA').save(OUT / 'composite.png')
    bg = Image.new('RGBA', (W, H), (24, 29, 38, 255))
    bg.alpha_composite(Image.fromarray(comp, 'RGBA'))
    bg.resize((W * 4, H * 4), Image.Resampling.NEAREST).save(OUT / 'composite_4x.png')

    missing = alpha & ~(comp[:, :, 3] > 0)
    print('missing pixels', int(missing.sum()))
    for name, image in parts.items():
        m = image[:, :, 3] > 0
        if m.any():
            yy, xx = np.where(m)
            print(name, int(m.sum()), 'bbox', (int(xx.min()), int(yy.min()), int(xx.max()), int(yy.max())))
    (OUT / 'pivots.json').write_text(json.dumps(PIVOTS, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main()
