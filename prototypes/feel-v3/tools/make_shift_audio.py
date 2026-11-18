"""Generate the shift / world sound set for feel-v3 (no external samples; pure synthesis + SAPI voices).

Usage (from prototypes/feel-v3/tools or anywhere):
    python tools/make_shift_audio.py              # build everything
    python tools/make_shift_audio.py shift_tear lever   # build named files only
    python tools/make_shift_audio.py --list

Output: assets/audio/sfx/shift/*.wav and assets/audio/sfx/world/*.wav
        44100 Hz, 16-bit, mono (drone_loop is stereo); one-shots peak -1 dBFS, loops -6 dBFS.
Helpers: make_shift_audio_dsp.py (primitives), make_shift_audio_voice.py (SAPI + voice chain),
         make_shift_audio_shift.py (shift_tear, incants, whispers),
         make_shift_audio_ambient.py (drone, machine, terminal), make_shift_audio_world.py (world sfx).
Voices are cached under the scratch folder (see make_shift_audio_voice.SCRATCH).
"""
from __future__ import annotations

import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(HERE)  # prototypes/feel-v3

import make_shift_audio_dsp as D  # noqa: E402
import make_shift_audio_voice as V  # noqa: E402
import make_shift_audio_shift as S  # noqa: E402
import make_shift_audio_ambient as A  # noqa: E402
import make_shift_audio_world as W  # noqa: E402

SHIFT_DIR = os.path.join(ROOT, "assets", "audio", "sfx", "shift")
WORLD_DIR = os.path.join(ROOT, "assets", "audio", "sfx", "world")

# name -> (folder, builder returning (samples, peak_db))
BUILDERS = {"shift_tear": (SHIFT_DIR, S.build_shift_tear)}
for _i in range(1, 7):
    BUILDERS[f"incant_{_i:02d}"] = (SHIFT_DIR, (lambda i=_i: S.build_incant(i)))
for _i in range(1, 6):
    BUILDERS[f"whisper_{_i:02d}"] = (SHIFT_DIR, (lambda i=_i: S.build_whisper(i)))
BUILDERS.update({
    "drone_loop": (SHIFT_DIR, A.build_drone_loop),
    "dead_terminal": (SHIFT_DIR, A.build_dead_terminal),
    "machine_hum": (SHIFT_DIR, A.build_machine_hum),
    "machine_activate": (SHIFT_DIR, A.build_machine_activate),
})
for _name, _fn in W.BUILDERS.items():
    BUILDERS[_name] = (WORLD_DIR, _fn)


def main(argv) -> int:
    if "--list" in argv:
        print("\n".join(BUILDERS))
        return 0
    names = [a for a in argv if not a.startswith("-")] or list(BUILDERS)
    os.makedirs(SHIFT_DIR, exist_ok=True)
    os.makedirs(WORLD_DIR, exist_ok=True)
    V.render_tts()
    rows = []
    for name in names:
        folder, fn = BUILDERS[name]
        t0 = time.time()
        for attempt in range(5):  # the shared machine sometimes runs out of memory for a moment: just retry
            try:
                x, peak_db = fn()
                break
            except MemoryError:
                print(f"{name}: out of memory, retry {attempt + 1}", flush=True)
                time.sleep(4)
        else:
            raise MemoryError(name)
        path = os.path.join(folder, name + ".wav")
        D.save_wav(path, x, peak_db)
        info = D.analyse(D.read_any(path))
        rows.append((name, info))
        print(f"{name:18s} {info['dur']:5.2f}s  peak {info['peak_db']:6.2f}  rms {info['rms_db']:6.1f}  "
              f"clip {info['clip_run']}  cen {info['centroid']:6.0f}Hz  lo/mid/hi "
              f"{info['lo']:.2f}/{info['mid']:.2f}/{info['hi']:.2f}  ({time.time() - t0:.1f}s)", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
