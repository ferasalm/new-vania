"""Animate one Pandora frame with PixelLab's text-to-animation API.

Usage:
  setx PIXELLAB_API_KEY "..."      (once, then open a new shell)
  python pixellab_animate.py --image pandora_base_112x80.png --action "idle breathing" --frames 8 --out idle

Reads the key from PIXELLAB_API_KEY only; never prints or writes it.
The base frame must be <=256x256, transparent, with room around the sprite.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

API = 'https://api.pixellab.ai/v2'
HERE = Path(__file__).resolve().parent


def request(method, url, key, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json',
    })
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors='replace')[:800]
        raise RuntimeError(f'{method} {url} -> HTTP {exc.code}: {body}') from exc


def extract_frames(result):
    """Accept the shapes PixelLab has used for animation results."""
    if not isinstance(result, dict):
        return []
    for key in ('images', 'base64_images', 'frames'):
        value = result.get(key)
        if isinstance(value, list) and value:
            return value
    for key in ('urls', 'image_urls', 'output_urls'):
        value = result.get(key)
        if isinstance(value, list) and value:
            return value
    nested = result.get('result')
    if isinstance(nested, dict):
        return extract_frames(nested)
    return []


def save_frames(items, out: Path):
    out.mkdir(parents=True, exist_ok=True)
    saved = []
    for index, item in enumerate(items):
        if isinstance(item, dict):
            item = item.get('image') or item.get('base64') or item.get('url') or ''
        if not isinstance(item, str) or not item:
            continue
        if item.startswith('http'):
            with urllib.request.urlopen(item, timeout=120) as response:
                raw = response.read()
        else:
            raw = base64.b64decode(item.split(',')[-1])
        path = out / f'frame_{index:02d}.png'
        path.write_bytes(raw)
        saved.append(path)
    if not saved:
        return []
    frames = [Image.open(p).convert('RGBA') for p in saved]
    width, height = frames[0].size
    strip = Image.new('RGBA', (width * len(frames), height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * width, 0))
    strip.save(out / 'strip.png')
    strip.resize((strip.width * 3, strip.height * 3), Image.Resampling.NEAREST).save(out / 'strip_3x.png')
    preview = []
    for frame in frames:
        bg = Image.new('RGBA', frame.size, (24, 29, 38, 255))
        bg.alpha_composite(frame)
        preview.append(bg.convert('RGB'))
    preview[0].save(out / 'preview.gif', save_all=True, append_images=preview[1:],
                    duration=100, loop=0, disposal=2)
    return saved


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--image', default=str(HERE / 'pandora_base_112x80.png'))
    parser.add_argument('--action', required=True, help='e.g. "idle breathing", "run cycle", "sword slash"')
    parser.add_argument('--frames', type=int, default=8, choices=range(4, 17, 2))
    parser.add_argument('--seed', type=int, default=0)
    parser.add_argument('--out', default='animation_out')
    parser.add_argument('--no-enhance', action='store_true')
    args = parser.parse_args()

    key = os.environ.get('PIXELLAB_API_KEY')
    if not key:
        raise SystemExit('PIXELLAB_API_KEY is not set. Set it in the environment first.')

    image_path = Path(args.image)
    image = Image.open(image_path).convert('RGBA')
    if max(image.size) > 256:
        raise SystemExit(f'{image_path} is {image.size}; PixelLab accepts at most 256x256.')
    payload = {
        'first_frame': base64.b64encode(image_path.read_bytes()).decode(),
        'action': args.action,
        'frame_count': args.frames,
        'seed': args.seed,
        'no_background': True,
        'enhance_prompt': not args.no_enhance,
    }
    accepted = request('POST', f'{API}/animate-with-text-v3', key, payload)
    job_id = accepted.get('background_job_id') or accepted.get('id')
    if not job_id:
        raise SystemExit(f'No job id in response: {accepted}')
    print('job', job_id, 'status', accepted.get('status'))

    deadline = time.time() + 900
    result = None
    while time.time() < deadline:
        time.sleep(3)
        job = request('GET', f'{API}/background-jobs/{job_id}', key)
        status = job.get('status')
        print('status', status)
        if status == 'completed':
            result = job.get('last_response', job)
            break
        if status == 'failed':
            raise SystemExit(f'Job failed: {json.dumps(job)[:600]}')
    if result is None:
        raise SystemExit('Timed out waiting for the animation job.')

    items = extract_frames(result)
    saved = save_frames(items, Path(args.out))
    print('saved', len(saved), 'frames to', args.out)
    print('usage', json.dumps(result.get('usage', {}))[:200])
    if not saved:
        print('RESULT_SHAPE', json.dumps(result)[:1500])


if __name__ == '__main__':
    main()
