"""Generate the full Pandora cutout sheet (15 clips, 77 frames, 112x80).

Imports the cutout rig from rig_anim.py. Every pixel comes from the user's
side-view sprite; poses are joint targets, not redrawn art.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import rig_anim as R  # noqa: E402

OUT = ROOT / 'sheet'
W, H = 112, 80
GROUND = 75

COUNTS = {
    'idle': 6, 'run': 16, 'jump': 4, 'land': 1, 'crouch': 5,
    'attack': 5, 'attack2': 5, 'crouchatk': 5, 'crouchatk2': 5,
    'airatk': 5, 'airatk2': 5, 'backdash': 4, 'hurt': 2, 'cast': 5, 'dead': 4,
}
ORDER = list(COUNTS)


def build_parts():
    parts = {
        'torso': R.load('torso'), 'head': R.load('head'), 'hair_back': R.load('hair_back'),
        'cape': R.load('cape'), 'arm_n': R.load('arm_n'), 'leg_n': R.load('leg_n'),
        'leg_f': R.load('leg_f'),
    }
    parts['arm_n_upper'], parts['arm_n_lower'] = R.split(parts['arm_n'], 36)
    parts['leg_n_upper'], parts['leg_n_lower'] = R.split(parts['leg_n'], 61)
    parts['leg_f_upper'], parts['leg_f_lower'] = R.split(parts['leg_f'], 61)
    parts['arm_f_upper'] = R.darken(R.shift(parts['arm_n_upper'], -5, 0))
    parts['arm_f_lower'] = R.darken(R.shift(parts['arm_n_lower'], -5, 0))
    return parts


def rot(p, pivot, deg):
    a = math.radians(deg)
    x, y = p[0] - pivot[0], p[1] - pivot[1]
    return (pivot[0] + x * math.cos(a) - y * math.sin(a),
            pivot[1] + x * math.sin(a) + y * math.cos(a))


def body(p, py, lean=0.0):
    """Set pelvis height and rotate the upper body around the source pelvis."""
    p['pelvis'] = (56.0, py)
    dy = py - 45.0
    for k in ('chest', 'neck', 'head', 'shoulder_n', 'shoulder_f'):
        q = rot(R.SRC[k], R.SRC['pelvis'], lean)
        p[k] = (q[0], q[1] + dy)
    p['hip_n'] = (58.0, py + 1)
    p['hip_f'] = (54.0, py + 1)


def legs(p, fn, ff):
    p['ankle_n'] = fn
    p['ankle_f'] = ff
    p['knee_n'] = R.ik2(p['hip_n'], fn, 15, 10, 1)
    p['knee_f'] = R.ik2(p['hip_f'], ff, 15, 10, -1)


def arms(p, hn, hf):
    p['hand_n'] = hn
    p['hand_f'] = hf
    p['elbow_n'] = R.ik2(p['shoulder_n'], hn, 7, 7, 1)
    p['elbow_f'] = R.ik2(p['shoulder_f'], hf, 7, 7, -1)


def stand(**kw):
    p = R.rest_pose()
    p.update(kw)
    return p


def interp(a, b, t):
    out = {}
    for k in a:
        va, vb = a[k], b[k]
        if isinstance(va, tuple):
            out[k] = (va[0] * (1 - t) + vb[0] * t, va[1] * (1 - t) + vb[1] * t)
        else:
            out[k] = va * (1 - t) + vb * t
    return out


def keys_to_frames(keys, count):
    """keys: list of (index, pose). Linear interpolation between keys."""
    frames = []
    for i in range(count):
        lo = max(k for k in keys if k[0] <= i)
        hi = min(k for k in keys if k[0] >= i)
        if lo[0] == hi[0]:
            frames.append(lo[1])
        else:
            t = (i - lo[0]) / (hi[0] - lo[0])
            frames.append(interp(lo[1], hi[1], t))
    return frames


def anim_idle():
    out = []
    for i in range(6):
        t = 2 * math.pi * i / 6
        dy = 1 if i in (2, 3) else 0
        p = stand()
        p['pelvis'] = (56, 45 + dy)
        for k in ('chest', 'neck', 'head'):
            x, y = p[k]
            p[k] = (x, y + dy)
        p['shoulder_n'] = (59, 29 + dy)
        p['shoulder_f'] = (54, 29 + dy)
        p['hip_n'] = (58, 46 + dy)
        p['hip_f'] = (54, 46 + dy)
        legs(p, (59, 71), (53, 71))
        arms(p, (62, 43), (54, 43))
        p['hair_angle'] = 2 * math.sin(t)
        p['cape_angle'] = 2.5 * math.sin(t + 0.4)
        out.append(p)
    return out


def anim_jump():
    p0 = stand(); body(p0, 49, -4); legs(p0, (60, 71), (52, 71)); arms(p0, (56, 40), (50, 40))
    p1 = stand(); body(p1, 41, -2); legs(p1, (60, 66), (52, 66)); arms(p1, (62, 30), (48, 30))
    p2 = stand(); body(p2, 37, 0); legs(p2, (61, 60), (51, 60)); arms(p2, (64, 34), (46, 34))
    p3 = stand(); body(p3, 41, 2); legs(p3, (61, 66), (51, 66)); arms(p3, (64, 38), (46, 38))
    for p in (p0, p1, p2, p3):
        p['hair_angle'] = -4; p['cape_angle'] = -6
    return [p0, p1, p2, p3]


def anim_land():
    p = stand(); body(p, 51, -8); legs(p, (60, 71), (52, 71)); arms(p, (64, 42), (48, 42))
    p['hair_angle'] = 6; p['cape_angle'] = 10
    return [p]


def anim_crouch():
    down = stand(); body(down, 51, -8); legs(down, (60, 71), (52, 71)); arms(down, (62, 44), (54, 44))
    mid = stand(); body(mid, 49, -6); legs(mid, (60, 71), (52, 71)); arms(mid, (62, 44), (54, 44))
    up = stand()
    for p in (down, mid):
        p['hair_angle'] = 4; p['cape_angle'] = 6
    return keys_to_frames([(0, up), (2, down), (4, up)], 5)


def anim_attack():
    p0 = stand()
    p1 = stand(); body(p1, 45, 4); legs(p1, (62, 71), (52, 71)); arms(p1, (54, 32), (52, 40))
    p2 = stand(); body(p2, 45, -8); legs(p2, (64, 71), (52, 71)); arms(p2, (72, 32), (50, 40))
    p3 = stand(); body(p3, 45, -6); legs(p3, (64, 71), (52, 71)); arms(p3, (72, 34), (50, 40))
    p4 = stand()
    for p in (p1, p2, p3):
        p['hair_angle'] = -6; p['cape_angle'] = -8
    return keys_to_frames([(0, p0), (1, p1), (2, p2), (3, p3), (4, p4)], 5)


def anim_attack2():
    p0 = stand()
    p1 = stand(); body(p1, 45, 6); legs(p1, (62, 71), (52, 71)); arms(p1, (56, 28), (52, 38))
    p2 = stand(); body(p2, 45, -10); legs(p2, (64, 71), (52, 71)); arms(p2, (72, 24), (50, 38))
    p3 = stand(); body(p3, 45, -8); legs(p3, (64, 71), (52, 71)); arms(p3, (72, 26), (50, 38))
    p4 = stand()
    for p in (p1, p2, p3):
        p['hair_angle'] = -8; p['cape_angle'] = -10
    return keys_to_frames([(0, p0), (1, p1), (2, p2), (3, p3), (4, p4)], 5)


def crouch_attack(high=False):
    p0 = stand(); body(p0, 50, -6); legs(p0, (60, 71), (52, 71)); arms(p0, (58, 40), (54, 42))
    p1 = stand(); body(p1, 50, -4); legs(p1, (60, 71), (52, 71)); arms(p1, (56, 34 if high else 40), (52, 42))
    p2 = stand(); body(p2, 50, -10); legs(p2, (62, 71), (52, 71)); arms(p2, (70, 34 if high else 42), (50, 42))
    p3 = stand(); body(p3, 50, -8); legs(p3, (62, 71), (52, 71)); arms(p3, (70, 36 if high else 44), (50, 42))
    p4 = stand(); body(p4, 50, -6); legs(p4, (60, 71), (52, 71)); arms(p4, (58, 40), (54, 42))
    for p in (p1, p2, p3):
        p['hair_angle'] = -4; p['cape_angle'] = -6
    return keys_to_frames([(0, p0), (1, p1), (2, p2), (3, p3), (4, p4)], 5)


def air_attack(high=False):
    p0 = stand(); body(p0, 39, 0); legs(p0, (61, 60), (51, 60)); arms(p0, (60, 34), (50, 34))
    p1 = stand(); body(p1, 39, 4); legs(p1, (61, 60), (51, 60)); arms(p1, (58, 30 if high else 36), (50, 34))
    p2 = stand(); body(p2, 39, -8); legs(p2, (63, 60), (51, 60)); arms(p2, (72, 28 if high else 38), (48, 34))
    p3 = stand(); body(p3, 39, -6); legs(p3, (63, 60), (51, 60)); arms(p3, (72, 30 if high else 40), (48, 34))
    p4 = stand(); body(p4, 39, 0); legs(p4, (61, 60), (51, 60)); arms(p4, (60, 34), (50, 34))
    for p in (p1, p2, p3):
        p['hair_angle'] = -10; p['cape_angle'] = -12
    return keys_to_frames([(0, p0), (1, p1), (2, p2), (3, p3), (4, p4)], 5)


def anim_backdash():
    p0 = stand(); body(p0, 45, 10); legs(p0, (60, 71), (50, 71)); arms(p0, (66, 40), (58, 40))
    p1 = stand(); body(p1, 45, 14); legs(p1, (62, 71), (48, 71)); arms(p1, (68, 38), (60, 38))
    p2 = stand(); body(p2, 45, 10); legs(p2, (60, 71), (50, 71)); arms(p2, (66, 40), (58, 40))
    p3 = stand()
    for p in (p0, p1, p2):
        p['hair_angle'] = 12; p['cape_angle'] = 16
    return [p0, p1, p2, p3]


def anim_hurt():
    p0 = stand()
    p1 = stand(); body(p1, 46, 12); legs(p1, (60, 71), (52, 71)); arms(p1, (64, 36), (48, 36))
    p1['hair_angle'] = 10; p1['cape_angle'] = 12
    return [p0, p1]


def anim_cast():
    p0 = stand()
    p1 = stand(); body(p1, 45, 2); legs(p1, (60, 71), (52, 71)); arms(p1, (58, 34), (52, 40))
    p2 = stand(); body(p2, 45, -4); legs(p2, (60, 71), (52, 71)); arms(p2, (70, 30), (50, 40))
    p3 = stand(); body(p3, 45, -3); legs(p3, (60, 71), (52, 71)); arms(p3, (66, 32), (50, 40))
    p4 = stand()
    for p in (p1, p2, p3):
        p['hair_angle'] = -4; p['cape_angle'] = -6
    return keys_to_frames([(0, p0), (1, p1), (2, p2), (3, p3), (4, p4)], 5)


def anim_dead():
    p0 = stand(); body(p0, 46, 14); legs(p0, (60, 71), (52, 71)); arms(p0, (64, 36), (48, 36))
    p1 = stand(); body(p1, 50, -20); legs(p1, (62, 71), (50, 71)); arms(p1, (62, 46), (50, 46))
    p2 = stand(); body(p2, 54, -55); legs(p2, (62, 71), (50, 71)); arms(p2, (66, 52), (48, 52))
    p3 = stand(); body(p3, 58, -80); legs(p3, (64, 71), (48, 71)); arms(p3, (70, 58), (44, 58))
    for p in (p0, p1, p2, p3):
        p['hair_angle'] = 8; p['cape_angle'] = 12
    return [p0, p1, p2, p3]


ANIMS = {
    'idle': anim_idle, 'run': lambda: [R.run_pose(i, 16) for i in range(16)],
    'jump': anim_jump, 'land': anim_land, 'crouch': anim_crouch,
    'attack': anim_attack, 'attack2': anim_attack2,
    'crouchatk': lambda: crouch_attack(False), 'crouchatk2': lambda: crouch_attack(True),
    'airatk': lambda: air_attack(False), 'airatk2': lambda: air_attack(True),
    'backdash': anim_backdash, 'hurt': anim_hurt, 'cast': anim_cast, 'dead': anim_dead,
}

GROUNDED = {'idle', 'run', 'land', 'crouch', 'attack', 'attack2', 'crouchatk',
            'crouchatk2', 'backdash', 'hurt', 'cast', 'dead'}


def clamp_ground(frame, grounded):
    a = frame.getchannel('A')
    bbox = a.getbbox()
    if not bbox:
        return frame
    low = bbox[3] - 1
    if grounded:
        shift = GROUND - low
    else:
        shift = min(0, GROUND - low)
    if shift == 0:
        return frame
    out = Image.new('RGBA', frame.size, (0, 0, 0, 0))
    out.alpha_composite(frame, (0, shift))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for sub in ('frames', 'strips', 'gifs'):
        (OUT / sub).mkdir(exist_ok=True)
    parts = build_parts()
    all_frames = {}
    for name in ORDER:
        poses = ANIMS[name]()
        assert len(poses) == COUNTS[name], (name, len(poses))
        frames = []
        for i, pose in enumerate(poses):
            frame = R.draw_pose(pose, parts)
            frame = clamp_ground(frame, name in GROUNDED)
            frame.save(OUT / 'frames' / f'{name}_{i:02d}.png')
            frames.append(frame)
        all_frames[name] = frames
        strip = Image.new('RGBA', (W * len(frames), H), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            strip.alpha_composite(frame, (i * W, 0))
        strip.save(OUT / 'strips' / f'{name}.png')
        strip.resize((strip.width * 3, strip.height * 3), Image.Resampling.NEAREST).save(
            OUT / 'strips' / f'{name}_3x.png')
        preview = []
        for frame in frames:
            bg = Image.new('RGBA', frame.size, (24, 29, 38, 255))
            bg.alpha_composite(frame)
            preview.append(bg.convert('RGB'))
        preview[0].save(OUT / 'gifs' / f'{name}.gif', save_all=True, append_images=preview[1:],
                        duration=100, loop=0, disposal=2)
        print(name, len(frames), 'low', max(f.getchannel('A').getbbox()[3] - 1 for f in frames))

    cols = max(COUNTS.values())
    sheet = Image.new('RGBA', (cols * W, len(ORDER) * H), (0, 0, 0, 0))
    for row, name in enumerate(ORDER):
        for col, frame in enumerate(all_frames[name]):
            sheet.alpha_composite(frame, (col * W, row * H))
    sheet.save(OUT / 'pandora_sheet.png')
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.Resampling.NEAREST).save(
        OUT / 'pandora_sheet_2x.png')

    meta = {
        'hero': {
            'faces': 'right', 'size': [W, H], 'feet': [56, 76],
            'anims': COUNTS,
            'sheet': {
                'file': 'pandora_sheet.png', 'cell': [W, H], 'columns': cols,
                'rows': len(ORDER), 'row_order': ORDER,
                'row_start': {name: row for row, name in enumerate(ORDER)},
                'frame_counts': COUNTS,
            },
        }
    }
    (OUT / 'sheet_meta.json').write_text(json.dumps(meta, indent=2), encoding='utf-8')
    print('sheet', sheet.size, 'frames', sum(COUNTS.values()))


if __name__ == '__main__':
    main()
