"""Cutout rig for the user's Pandora sprite: rest, idle and run proofs.

Every pixel comes from the user's sprite; parts are only rotated/translated.
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
PARTS = ROOT / 'parts'
OUT = ROOT / 'rig_out'
W, H = 112, 80

# Source joints in the 112x80 base.
SRC = {
    'pelvis': (56, 45), 'chest': (56, 30), 'neck': (56, 24), 'head': (57, 15),
    'shoulder_n': (59, 29), 'elbow_n': (61, 36), 'hand_n': (62, 43),
    'hip_n': (58, 46), 'knee_n': (59, 61), 'ankle_n': (59, 71),
    'shoulder_f': (54, 29), 'elbow_f': (56, 36), 'hand_f': (57, 43),
    'hip_f': (54, 46), 'knee_f': (53, 61), 'ankle_f': (53, 71),
    'hair': (53, 20), 'cape': (56, 30),
}
JOINT_FILL = (35, 42, 57, 255)


def load(name):
    return Image.open(PARTS / f'{name}.png').convert('RGBA')


def split(img, y, overlap=3):
    upper = img.copy()
    lower = img.copy()
    a = np.array(upper)
    a[y + overlap:, :, 3] = 0
    upper = Image.fromarray(a, 'RGBA')
    b = np.array(lower)
    b[:max(0, y - overlap), :, 3] = 0
    lower = Image.fromarray(b, 'RGBA')
    return upper, lower


def darken(img, factor=0.7):
    a = np.array(img).astype(float)
    a[:, :, :3] *= factor
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), 'RGBA')


def shift(img, dx, dy):
    a = np.zeros((H, W, 4), np.uint8)
    src = np.array(img)
    x0, x1 = max(0, dx), min(W, W + dx)
    y0, y1 = max(0, dy), min(H, H + dy)
    a[y0:y1, x0:x1] = src[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
    return Image.fromarray(a, 'RGBA')


def angle(a, b):
    return math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))


def transform(canvas, img, src_pivot, dst_pivot, delta_deg):
    bbox = img.getbbox()
    if not bbox:
        return
    margin = 10
    x0 = max(0, bbox[0] - margin)
    y0 = max(0, bbox[1] - margin)
    x1 = min(W, bbox[2] + margin)
    y1 = min(H, bbox[3] + margin)
    crop = img.crop((x0, y0, x1, y1))
    px, py = src_pivot[0] - x0, src_pivot[1] - y0
    rotated = crop.rotate(-delta_deg, resample=Image.NEAREST, center=(px, py), expand=False)
    dx = int(round(dst_pivot[0] - src_pivot[0]))
    dy = int(round(dst_pivot[1] - src_pivot[1]))
    canvas.alpha_composite(rotated, (x0 + dx, y0 + dy))


def joint(canvas, point, radius=3):
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((point[0] - radius, point[1] - radius,
                  point[0] + radius, point[1] + radius), fill=JOINT_FILL)


def draw_pose(pose, parts):
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    torso = parts['torso']
    head = parts['head']
    hair = parts['hair_back']
    cape = parts['cape']
    arm_u, arm_l = parts['arm_n_upper'], parts['arm_n_lower']
    leg_u, leg_l = parts['leg_n_upper'], parts['leg_n_lower']
    fleg_u, fleg_l = parts['leg_f_upper'], parts['leg_f_lower']
    farm_u, farm_l = parts['arm_f_upper'], parts['arm_f_lower']

    # Behind the body.
    transform(canvas, hair, SRC['hair'], (pose['neck'][0] - 3, pose['neck'][1] - 4),
              pose.get('hair_angle', 0))
    transform(canvas, cape, SRC['cape'], pose['chest'], pose.get('cape_angle', 0))
    transform(canvas, farm_u, SRC['shoulder_f'], pose['shoulder_f'],
              angle(SRC['shoulder_f'], SRC['elbow_f']) * -1 + angle(pose['shoulder_f'], pose['elbow_f']))
    transform(canvas, farm_l, SRC['elbow_f'], pose['elbow_f'],
              angle(SRC['elbow_f'], SRC['hand_f']) * -1 + angle(pose['elbow_f'], pose['hand_f']))
    joint(canvas, pose['hip_f'])
    joint(canvas, pose['knee_f'])
    transform(canvas, fleg_u, SRC['hip_f'], pose['hip_f'],
              angle(SRC['hip_f'], SRC['knee_f']) * -1 + angle(pose['hip_f'], pose['knee_f']))
    transform(canvas, fleg_l, SRC['knee_f'], pose['knee_f'],
              angle(SRC['knee_f'], SRC['ankle_f']) * -1 + angle(pose['knee_f'], pose['ankle_f']))

    # Torso and head.
    transform(canvas, torso, SRC['pelvis'], pose['pelvis'],
              angle(SRC['pelvis'], SRC['chest']) * -1 + angle(pose['pelvis'], pose['chest']))
    joint(canvas, pose['pelvis'])
    joint(canvas, pose['neck'])
    transform(canvas, head, SRC['neck'], pose['neck'],
              angle(SRC['neck'], SRC['head']) * -1 + angle(pose['neck'], pose['head']))

    # Near limbs on top.
    joint(canvas, pose['hip_n'])
    joint(canvas, pose['knee_n'])
    transform(canvas, leg_u, SRC['hip_n'], pose['hip_n'],
              angle(SRC['hip_n'], SRC['knee_n']) * -1 + angle(pose['hip_n'], pose['knee_n']))
    transform(canvas, leg_l, SRC['knee_n'], pose['knee_n'],
              angle(SRC['knee_n'], SRC['ankle_n']) * -1 + angle(pose['knee_n'], pose['ankle_n']))
    joint(canvas, pose['shoulder_n'])
    joint(canvas, pose['elbow_n'])
    transform(canvas, arm_u, SRC['shoulder_n'], pose['shoulder_n'],
              angle(SRC['shoulder_n'], SRC['elbow_n']) * -1 + angle(pose['shoulder_n'], pose['elbow_n']))
    transform(canvas, arm_l, SRC['elbow_n'], pose['elbow_n'],
              angle(SRC['elbow_n'], SRC['hand_n']) * -1 + angle(pose['elbow_n'], pose['hand_n']))
    return canvas


def rest_pose():
    return {k: v for k, v in SRC.items() if k not in ('hair', 'cape')} | {
        'hair_angle': 0, 'cape_angle': 0}


def ik2(hip, target, l1, l2, bend=1):
    dx, dy = target[0] - hip[0], target[1] - hip[1]
    d = max(abs(l1 - l2) + 0.01, min(l1 + l2 - 0.01, math.hypot(dx, dy)))
    base = math.atan2(dy, dx)
    cos_a = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    a = math.acos(max(-1.0, min(1.0, cos_a)))
    return (hip[0] + l1 * math.cos(base + bend * a),
            hip[1] + l1 * math.sin(base + bend * a))


def run_pose(i, n=8):
    t = 2 * math.pi * i / n

    def foot(phase):
        phase = phase % (2 * math.pi)
        if phase < math.pi:  # stance: ankle on the ground, moving back
            u = phase / math.pi
            return (62 - 10 * u, 69)
        u = (phase - math.pi) / math.pi  # swing: lift and move forward
        return (52 + 10 * u, 69 - 8 * math.sin(math.pi * u))

    fn = foot(t)
    ff = foot(t + math.pi)
    py = 45 - 1.5 * math.cos(2 * t)
    lean = -8.0

    def rot(p, pivot, deg):
        a = math.radians(deg)
        x, y = p[0] - pivot[0], p[1] - pivot[1]
        return (pivot[0] + x * math.cos(a) - y * math.sin(a),
                pivot[1] + x * math.sin(a) + y * math.cos(a))

    pelvis = (56, py)
    chest = rot((56, 30), (56, 45), lean)
    neck = rot((56, 24), (56, 45), lean)
    head = rot((57, 15), (56, 45), lean)
    sh_n = rot((59, 29), (56, 45), lean)
    sh_f = rot((54, 29), (56, 45), lean)
    hip_n = (58, py + 1)
    hip_f = (54, py + 1)
    knee_n = ik2(hip_n, fn, 15, 10, 1)
    knee_f = ik2(hip_f, ff, 15, 10, -1)
    hand_n = (62 - 8 * math.cos(t), 40 + 2 * math.sin(t))
    hand_f = (54 + 8 * math.cos(t), 40 - 2 * math.sin(t))
    elbow_n = ik2(sh_n, hand_n, 7, 7, 1)
    elbow_f = ik2(sh_f, hand_f, 7, 7, -1)
    return {
        'pelvis': pelvis, 'chest': chest, 'neck': neck, 'head': head,
        'shoulder_n': sh_n, 'elbow_n': elbow_n, 'hand_n': hand_n,
        'shoulder_f': sh_f, 'elbow_f': elbow_f, 'hand_f': hand_f,
        'hip_n': hip_n, 'knee_n': knee_n, 'ankle_n': fn,
        'hip_f': hip_f, 'knee_f': knee_f, 'ankle_f': ff,
        'hair_angle': -8 + 3 * math.sin(t + 0.6),
        'cape_angle': -6 + 4 * math.sin(t + 0.3),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['rest', 'idle', 'run'], default='rest')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    parts = {
        'torso': load('torso'), 'head': load('head'), 'hair_back': load('hair_back'),
        'cape': load('cape'), 'arm_n': load('arm_n'), 'leg_n': load('leg_n'),
        'leg_f': load('leg_f'),
    }
    parts['arm_n_upper'], parts['arm_n_lower'] = split(parts['arm_n'], 36)
    parts['leg_n_upper'], parts['leg_n_lower'] = split(parts['leg_n'], 61)
    parts['leg_f_upper'], parts['leg_f_lower'] = split(parts['leg_f'], 61)
    parts['arm_f_upper'] = darken(shift(parts['arm_n_upper'], -5, 0))
    parts['arm_f_lower'] = darken(shift(parts['arm_n_lower'], -5, 0))

    if args.mode == 'rest':
        frame = draw_pose(rest_pose(), parts)
        frame.save(OUT / 'rest.png')
        bg = Image.new('RGBA', (W, H), (24, 29, 38, 255))
        bg.alpha_composite(frame)
        bg.resize((W * 4, H * 4), Image.Resampling.NEAREST).save(OUT / 'rest_4x.png')
        print('rest bbox', frame.getbbox())
        return

    n = 6 if args.mode == 'idle' else 8
    frames = []
    for i in range(n):
        if args.mode == 'idle':
            t = 2 * math.pi * i / n
            pose = rest_pose()
            pose['pelvis'] = (56, 45 + (1 if i in (2, 3) else 0))
            pose['chest'] = (56, 30 + (1 if i in (2, 3) else 0))
            pose['neck'] = (56, 24 + (1 if i in (2, 3) else 0))
            pose['head'] = (57, 15 + (1 if i in (2, 3) else 0))
            pose['hair_angle'] = 2.0 * math.sin(t)
            pose['cape_angle'] = 2.5 * math.sin(t + 0.4)
        else:
            pose = run_pose(i, n)
        frames.append(draw_pose(pose, parts))
    for i, frame in enumerate(frames):
        frame.save(OUT / f'{args.mode}_{i:02d}.png')
    strip = Image.new('RGBA', (W * n, H), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        strip.alpha_composite(frame, (i * W, 0))
    strip.save(OUT / f'{args.mode}_strip.png')
    strip.resize((strip.width * 3, strip.height * 3), Image.Resampling.NEAREST).save(OUT / f'{args.mode}_strip_3x.png')
    preview = []
    for frame in frames:
        bg = Image.new('RGBA', frame.size, (24, 29, 38, 255))
        bg.alpha_composite(frame)
        preview.append(bg.convert('RGB'))
    preview[0].save(OUT / f'{args.mode}.gif', save_all=True, append_images=preview[1:],
                    duration=100, loop=0, disposal=2)
    print(args.mode, 'frames', n, 'bboxes', [f.getbbox() for f in frames])


if __name__ == '__main__':
    main()
