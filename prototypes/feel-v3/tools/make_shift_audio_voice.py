"""Voice raw material and 'inhuman' processing for tools/make_shift_audio.py.

Raw voices come from Windows SAPI (David and Zira) speaking invented pseudo-Latin lines,
cached as WAV in the scratch folder. Everything audible in the result is then processed
beyond recognition (pitch down, octave/reverse layers, vocoding, smear, saturation, cathedral reverb).
"""
from __future__ import annotations

import os
import subprocess

import numpy as np

import make_shift_audio_dsp as D

SCRATCH = "C:/Users/AUC/.claude/jobs/711ab256/tmp/audio"
TTS_DIR = os.path.join(SCRATCH, "tts")

VOICES = {"david": "Microsoft David Desktop", "zira": "Microsoft Zira Desktop"}

# key -> (voice, rate, spoken text). Spellings are phonetic so the English voices read them as Latin.
# The comment shows the intended Latin line (all invented, not scripture or prayer).
LINES = {
    # tempus frangitur, memoria cadit in tenebras
    "inc1": ("david", 0, "Tempoos frangitoor, memoria kaddit in tenebrahs"),
    # porta aperitur, veni
    "inc2": ("zira", 0, "Porta ah-pehritoor, weh-nee"),
    # nomen tuum non est tuum
    "inc3": ("david", -1, "Nomen too-oom, non est too-oom"),
    # umbra surgit, sanguis tacet
    "inc4": ("zira", 0, "Oombra soorgit, sangwis tahket"),
    # ultima hora frangitur, horologium moritur
    "inc5": ("david", 0, "Horologium moritoor"),
    # sanguis aperitur, nox aeterna
    "inc6": ("zira", 0, "Sangwis ah-pehritoor, nox eye-ternah"),
    "inc6b": ("david", 0, "Weh-nee, weh-nee, weh-nee"),
    # short chant fragments for the shift and the drone bed
    "ch1": ("david", 0, "Tempoos frangitoor"),
    "ch2": ("zira", 0, "Memoria kaddit"),
    "ch3": ("david", 0, "Nox aeterna, nox aeterna"),
    # whispers
    "wh1": ("zira", 0, "Weh-nee"),
    "wh2": ("david", 0, "Non est too-oom"),
    "wh3": ("zira", 0, "Tahkete, tahkete"),
    "wh4": ("zira", 0, "Oodee nomen too-oom"),
    "wh5": ("david", 0, "Soob oombra, soob oombra"),
}


def render_tts() -> None:
    os.makedirs(TTS_DIR, exist_ok=True)
    todo = {k: v for k, v in LINES.items() if not os.path.exists(os.path.join(TTS_DIR, k + ".wav"))}
    if not todo:
        return
    ps = ["Add-Type -AssemblyName System.Speech", "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer"]
    for k, (voice, rate, text) in todo.items():
        path = os.path.join(TTS_DIR, k + ".wav").replace("/", "\\")
        ps += [
            f"$s.SelectVoice('{VOICES[voice]}')",
            f"$s.Rate = {rate}",
            "$s.Volume = 100",
            f"$s.SetOutputToWaveFile('{path}')",
            f"$s.Speak('{text}')",
            "$s.SetOutputToNull()",
        ]
    ps.append("$s.Dispose()")
    script = os.path.join(SCRATCH, "tts_render.ps1")
    with open(script, "w", encoding="utf-8") as f:
        f.write("\n".join(ps))
    subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script],
        check=True,
    )


_cache: dict = {}


def raw(key: str) -> np.ndarray:
    if key not in _cache:
        x = D.load_wav(os.path.join(TTS_DIR, key + ".wav"))
        x = D.trim_silence(x, -40, 20)
        _cache[key] = x / (D.peak(x) + 1e-9)
    return _cache[key].copy()


# ------------------------------------------------------------ carriers & drones
def chord_carrier(freqs, n, detune_cents=9.0, voices=3, noise=0.12, vibrato=(5.2, 0.004)):
    """Choir-ish carrier: detuned bright saws at each chord note plus a little breath noise."""
    r = D.rng()
    t = np.arange(n) / D.SR
    out = np.zeros(n)
    for f in freqs:
        for v in range(voices):
            c = (v - (voices - 1) / 2) * detune_cents / (voices - 1 if voices > 1 else 1)
            c += r.uniform(-2, 2)
            vr = vibrato[0] * r.uniform(0.85, 1.15)
            vib = 1 + vibrato[1] * np.sin(2 * np.pi * vr * t + r.uniform(0, 6.28))
            out += D.harm(f * 2 ** (c / 1200) * vib, 30, 0.9)
    out /= max(1e-9, D.rms(out))
    out += noise * D.white(n)
    return out


def drone_under(n, f0=41.0, level=1.0, env=None):
    """Low drone cluster: two slightly detuned fundamentals plus a fifth and soft harmonics."""
    t = np.arange(n) / D.SR
    y = (np.sin(2 * np.pi * f0 * t) + 0.8 * np.sin(2 * np.pi * (f0 + 0.37) * t)
         + 0.45 * np.sin(2 * np.pi * f0 * 1.5 * t + 1.0) + 0.3 * np.sin(2 * np.pi * f0 * 2.0 * t + 0.3))
    y = D.saturate(y * 0.6, 2.0)
    if env is None:
        env = D.ar_env(n, n / D.SR * 0.35, None, 1.0)
    return level * y * env / (D.peak(y) + 1e-9)


# ------------------------------------------------------------ the 'inhuman' chain
def ghost(x, semis=-9.0, octave=0.5, rev=0.3, rev_delay=0.0, trem=(0.6, 0.45), smear=0.55,
          formants=None, comb_ms=None, comb_fb=0.55, drive=2.0, ir=None, wet=0.6, drone=0.0,
          drone_f0=41.0, ring=0.0, ring_hz=30.0, echo_s=0.0, echo_fb=0.4, lowcut=70.0):
    """Turn a human line into something that is not human. Returns the full (tail included) result."""
    a = D.pitch(x, semis)
    parts = [a]
    gains = [1.0]
    if octave:
        parts.append(D.pitch(a, -12.0))
        gains.append(octave)
    if rev:
        r = D.reverse(a)
        pad = np.concatenate([np.zeros(D.n_of(rev_delay)), r])
        parts.append(pad)
        gains.append(rev)
    y = D.mix(*parts, gains=gains)
    if ring:
        y = D.ring_mod(y, ring_hz, ring)
    if smear:
        y = D.formant_smear(y, formants or D.CHOIR_FORMANTS, smear)
    if comb_ms:
        y = D.comb(y, comb_ms, comb_fb)
        y = y / (D.peak(y) + 1e-9) * D.peak(a)
    if trem:
        y = D.tremolo(y, trem[0], trem[1], D.rng().uniform(0, 6.28))
    y = D.hp(y, lowcut, 2)
    y = D.saturate(y / (D.peak(y) + 1e-9), drive)
    if echo_s:
        y = D.echo(y, echo_s, echo_fb, 2500, 1.5)
    if ir is not None:
        y = D.reverb(y, ir, wet=wet, dry=1.0 - 0.4 * wet)
    if drone:
        n = len(y)
        y = y + D.peak(y) * drone * drone_under(n, drone_f0)
    return y
