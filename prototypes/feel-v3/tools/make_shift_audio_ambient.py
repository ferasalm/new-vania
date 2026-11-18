"""Ambient / machine family: drone_loop, machine_hum, machine_activate, dead_terminal."""
from __future__ import annotations

import numpy as np

import make_shift_audio_dsp as D
import make_shift_audio_voice as V

TAU = 2 * np.pi


def _quant(f, T):
    """Snap a frequency to a whole number of cycles over T seconds so a loop of length T has no seam."""
    return max(1, round(f * T)) / T


# ------------------------------------------------------------------ drone_loop (stereo, 36 s)
def _groan(dur, f0, f1):
    n = D.n_of(dur)
    t = np.arange(n) / D.SR
    f = D.glide(f0, f1, n) * (1 + 0.012 * np.sin(TAU * 0.35 * t + D.rng().uniform(0, 6)))
    ph = D.phase_from_freq(f)
    y = np.sin(ph + 2.3 * np.sin(1.41 * ph) + 1.1 * np.sin(2.76 * ph + 0.7))
    # stick-slip: the metal groans in uneven pulses
    stick = np.abs(D.lp(D.white(n), 9, 2))
    stick = stick / (np.max(stick) + 1e-9)
    y = y * (0.45 + 0.55 * stick)
    y = D.bp(y, 90, 2200, 2) * D.ar_env(n, dur * 0.42, None, 1.4)
    return D.saturate(y / (D.peak(y) + 1e-9), 1.6)


def build_drone_loop():
    D.seed(300)
    T = 36.0
    N = D.n_of(T)
    t = np.arange(N) / D.SR
    q = lambda f: _quant(f, T)  # noqa: E731
    r = D.rng()

    # --- deep detuned drone: every pair beats slowly (0.2 - 0.5 Hz); L and R lean to different partners
    pairs = [(36.71, 0.25, 1.0), (55.0, 0.33, 0.62), (58.27, 0.28, 0.45), (73.42, 0.42, 0.28)]
    L = np.zeros(N)
    R = np.zeros(N)
    for k, (f, beat, a) in enumerate(pairs):
        f1, f2 = q(f), q(f + beat)
        lfo1 = 1 + 0.35 * np.sin(TAU * q(1 / 12.0 * (k + 1)) * t + r.uniform(0, 6))
        lfo2 = 1 + 0.35 * np.sin(TAU * q(1 / 9.0 * (k + 1)) * t + r.uniform(0, 6))
        s1 = np.sin(TAU * f1 * t + r.uniform(0, 6))
        s2 = np.sin(TAU * f2 * t + r.uniform(0, 6))
        L += a * (s1 * lfo1 + 0.75 * s2 * lfo2)
        R += a * (s2 * lfo1 + 0.75 * s1 * lfo2)
    sub = np.stack([L, R], axis=1)
    sub = D.saturate(sub / np.max(np.abs(sub)) * 0.7, 1.7)  # soft saturation adds 2nd/3rd harmonics (audible on small speakers)

    # --- dark air: shaped noise, independent per channel, breathing slowly
    def air(seed_off):
        a = D.fft_noise(N, lambda f: np.where((f > 25) & (f < 4000), (f / 120.0 + 1e-3) ** -0.6 * (1 / (1 + (f / 500.0) ** 3)), 0.0))
        br = 1 + 0.5 * np.sin(TAU * q(1 / 12.0) * t + seed_off)
        return a * br

    airL, airR = air(0.3), air(2.4)

    # --- distant metallic groans (wrapping, so they can straddle the loop point)
    ir = D.cathedral_ir(3.4, 40, 0.8, seed_=31)
    groan_L = D.Canvas(T, wrap=True)
    groan_R = D.Canvas(T, wrap=True)
    for t0, dur, f0, f1, pan in [(4.5, 5.5, 150, 96, 0.3), (13.0, 4.5, 210, 128, 0.8), (21.0, 6.0, 118, 71, 0.45),
                                 (29.0, 5.0, 175, 112, 0.15), (34.0, 4.0, 240, 150, 0.65)]:
        g = D.reverb(_groan(dur, f0, f1), ir, wet=0.7, dry=0.5)
        groan_L.add(g, t0, 1 - pan)
        groan_R.add(g, t0, pan)

    # --- faint chant bed: vocoded, stretched voices on a dark chord, far away, plus two low murmurs
    chant_L = D.Canvas(T, wrap=True)
    chant_R = D.Canvas(T, wrap=True)
    ir_c = D.cathedral_ir(4.0, 60, 1.0, seed_=32)
    for key, st, chord, t0, pan, lvl in [
        ("ch1", -9, [82.4, 98.0, 123.5, 164.8], 2.0, 0.25, 1.0),
        ("ch2", -7, [92.5, 110.0, 138.6, 185.0], 10.0, 0.75, 0.9),
        ("ch3", -10, [73.4, 87.3, 110.0, 146.8], 18.5, 0.35, 1.0),
        ("ch1", -12, [65.4, 77.8, 98.0, 130.8], 27.0, 0.7, 0.9),
    ]:
        a = D.paulstretch(D.pitch(V.raw(key), st), 5.5)
        carrier = V.chord_carrier(chord, len(a), 15, 3, 0.1)
        c = D.vocoder(a, carrier, nb=20, lo=100, hi=4500, env_hz=25)
        c = D.lp(c, 1800, 2)
        c = D.fade(c / (D.peak(c) + 1e-9), 1500, 2000)
        c = D.reverb(c, ir_c, wet=0.7, dry=0.5)
        chant_L.add(c, t0, lvl * (1 - pan))
        chant_R.add(c, t0, lvl * pan)
    for key, t0, pan in [("ch3", 14.5, 0.8), ("ch1", 32.0, 0.2)]:
        m = V.ghost(V.raw(key), semis=-16, octave=0.7, rev=0.4, rev_delay=0.4, trem=(0.5, 0.5), smear=0.5,
                    formants=D.HOLLOW_FORMANTS, drive=2.0, ir=ir_c, wet=0.8, lowcut=45.0)
        m = D.fade(m / D.peak(m), 800, 1200)
        chant_L.add(m, t0, 0.6 * (1 - pan))
        chant_R.add(m, t0, 0.6 * pan)

    # --- mix: the drone carries the level, the rest sits well below it
    out = np.zeros((N, 2))
    out[:, 0] = 1.0 * sub[:, 0] + 0.06 * airL + 0.36 * groan_L.buf + 0.16 * chant_L.buf
    out[:, 1] = 1.0 * sub[:, 1] + 0.06 * airR + 0.36 * groan_R.buf + 0.16 * chant_R.buf
    # reference: the groans are normalised unit-peak, the chant unit-peak; levels above are set against the sub
    return out, -6.0


# ------------------------------------------------------------------ machine_hum (7 s loop)
def build_machine_hum():
    D.seed(310)
    T = 7.0
    N = D.n_of(T)
    t = np.arange(N) / D.SR
    q = lambda f: _quant(f, T)  # noqa: E731
    r = D.rng()

    hum = np.zeros(N)
    for f, a in [(55.0, 1.0), (55.43, 0.8), (110.0, 0.5), (110.86, 0.35), (165.0, 0.25), (220.0, 0.12)]:
        hum += a * np.sin(TAU * q(f) * t + r.uniform(0, 6))
    hum = D.saturate(hum / np.max(np.abs(hum)) * 0.8, 1.6)
    buzz = D.harm(np.full(N, q(100.0)), 9, 1.0, odd_only=True) * (0.5 + 0.5 * np.sin(TAU * q(0.43) * t + 1.0))
    hum = hum + 0.05 * buzz

    # clockwork: a slow tick/tock plus a fine ratchet
    cv = D.Canvas(T, wrap=True)
    tick = D.modal([2400, 5200, 780], [1.0, 0.4, 0.7], [0.006, 0.003, 0.02], 0.12)
    tock = D.modal([1850, 4100, 520], [1.0, 0.4, 0.8], [0.007, 0.003, 0.025], 0.12)
    fine = D.modal([3800, 7100], [1.0, 0.5], [0.003, 0.002], 0.05)
    for k in range(14):
        cv.add(tick if k % 2 == 0 else tock, k * 0.5, 1.0 * (0.9 + 0.1 * r.uniform()))
    for k in range(56):
        cv.add(fine, k * 0.125 + 0.0625, 0.1 * r.uniform(0.5, 1.0))
    ticks = cv.buf

    whirr = D.fft_noise(N, lambda f: np.where((f > 500) & (f < 2800), 1.0, 0.0))
    whirr = whirr * (0.55 + 0.45 * np.sin(TAU * q(14.0) * t))

    # faint organ pipes: 110 Hz and its fifth, plus a flat ninth that does not belong
    organ = np.zeros(N)
    for f0, a in [(110.0, 1.0), (165.0, 0.6), (233.14, 0.35)]:
        for k, w in enumerate([1.0, 0.5, 0.33, 0.22, 0.14, 0.08], start=1):
            organ += a * w * np.sin(TAU * q(f0 * k) * t + r.uniform(0, 6))
    organ *= 0.6 + 0.4 * np.sin(TAU * q(0.43) * t + 0.5)
    chiff = D.fft_noise(N, lambda f: np.where((f > 800) & (f < 3500), 1.0, 0.0)) * (0.5 + 0.5 * np.sin(TAU * q(0.86) * t))

    y = 1.0 * hum + 0.33 * ticks / (D.peak(ticks) + 1e-9) * D.peak(hum) + 0.05 * whirr + 0.22 * organ / np.max(np.abs(organ)) + 0.012 * chiff
    return y, -6.0


# ------------------------------------------------------------------ machine_activate (2.6 s)
def build_machine_activate():
    D.seed(320)
    T = 2.7
    N = D.n_of(T)
    cv = D.Canvas(T)
    t_spin = 2.05  # clockwork reaches full speed here; the chord locks in

    # accelerating ticks (3/s -> ~70/s) that blur into a whirr
    ns = D.n_of(t_spin)
    ts = np.arange(ns) / D.SR
    rate = 3.0 * (70.0 / 3.0) ** (ts / t_spin)
    phase = np.cumsum(rate) / D.SR
    idx = np.where(np.diff(np.floor(phase)) > 0)[0]
    tick = D.modal([2600, 5400, 800], [1.0, 0.45, 0.8], [0.005, 0.003, 0.015], 0.06)
    tock = D.modal([2000, 4400, 560], [1.0, 0.45, 0.8], [0.006, 0.003, 0.018], 0.06)
    for k, i in enumerate(idx):
        g = 0.35 + 0.65 * (i / ns) ** 1.2
        cv.add(tick if k % 2 == 0 else tock, i / D.SR, g * D.rng().uniform(0.8, 1.0))
    x = np.linspace(0, 1, ns)
    whirr = D.svf(D.white(ns), D.glide(220, 3600, ns), q=2.5, mode="band")
    whirr = whirr / (np.std(whirr) + 1e-9) * x ** 2.0
    gear = D.harm(D.glide(60, 700, ns), 10, 1.0) * x ** 2.2
    whine = D.sine(D.glide(300, 2500, ns), ns) * x ** 2.5
    # the spinning dies away over ~90 ms when the chord locks in (no hard cut)
    cv.add(D.fade(0.35 * whirr, 2.0, 90.0), 0.0, 1.0)
    cv.add(D.fade(0.28 * gear / (D.peak(gear) + 1e-9), 2.0, 90.0), 0.0, 1.0)
    cv.add(D.fade(0.14 * whine, 2.0, 90.0), 0.0, 1.0)

    # rising organ chord, sliding up from a fourth-ish below into place
    t0 = 0.45
    nc = D.n_of(T - t0)
    tc = np.arange(nc) / D.SR
    ease = np.clip(tc / (t_spin - t0), 0, 1)
    ease = ease * ease * (3 - 2 * ease)
    chord = np.zeros(nc)
    for f0 in [110.0, 164.81, 220.0, 261.63, 311.13]:
        f = f0 * 2.0 ** (-5.0 / 12.0 * (1 - ease)) * (1 + 0.004 * np.sin(TAU * 5.4 * tc + f0))
        chord += D.harm(f, 12, 0.85) + 0.7 * D.harm(f * 1.003, 8, 0.9)
    chord = chord / np.max(np.abs(chord))
    amp = (np.clip(tc / (t_spin - t0), 0, 1) ** 1.6)
    amp = amp * (1 + 0.12 * np.sin(TAU * 4.0 * tc) * (tc > (t_spin - t0)))
    amp[D.n_of(T - t0 - 0.3):] *= np.linspace(1, 0, len(amp[D.n_of(T - t0 - 0.3):])) ** 1.5
    chiff = D.noise_burst(0.25, 0.08, 1500, 5000) * 0.12
    chord = chord * amp
    cv.add(0.62 * chord, t0, 1.0)
    cv.add(chiff, t_spin - 0.02, 1.0)
    # the lock: a soft low thunk as the machine reaches speed
    cv.add(0.5 * D.thump(90, 42, 0.35, 0.09, 1.4), t_spin, 1.0)
    cv.add(0.28 * D.sine(D.glide(30, 52, N), N) * (np.arange(N) / N) ** 2, 0.0, 1.0)

    y = cv.buf
    y = D.reverb(y, D.cathedral_ir(1.5, 10, 1.0, seed_=33, early=False), wet=0.3, dry=0.95)
    y = y[: D.n_of(3.0)]
    y = D.fade_out(y, 0.4)
    return D.fade(y, 2.0, 5.0), -1.0


# ------------------------------------------------------------------ dead_terminal (1.25 s)
def build_dead_terminal():
    D.seed(330)
    T = 1.25
    cv = D.Canvas(T)
    r = D.rng()

    # crackle: sparse electrical snaps, thinning out
    times = D.poisson_times(0.0, 0.7, lambda t: 70 * np.exp(-t / 0.28) + 4, 74)
    for tt in times:
        dur = r.uniform(0.003, 0.02)
        cv.add(D.noise_burst(dur * 3, dur * 0.5, r.uniform(1200, 3500), 9000, 2), tt, r.uniform(0.25, 1.0))
    # mains buzz that stutters and dies
    n_b = D.n_of(0.55)
    buzz = D.saturate(D.harm(np.full(n_b, 120.0), 14, 0.7) * 1.4, 3.0)
    gate = (D.lp(D.white(n_b), 28, 2) > 0.02).astype(float)
    gate = D.lp(gate, 400, 1)
    cv.add(0.45 * buzz * gate * D.exp_env(n_b, 0.22), 0.0, 1.0)

    # the beep that fails: three shrinking, sagging, glitching beeps
    for k, (t0, dur, f0, f1) in enumerate([(0.10, 0.13, 1760, 1500), (0.30, 0.09, 1250, 900), (0.47, 0.07, 800, 380)]):
        n = D.n_of(dur)
        f = D.glide(f0, f1, n)
        sq = np.sign(np.sin(D.phase_from_freq(f)))
        sq = D.lp(sq, 6000, 2) * (0.8 ** k)
        if k == 2:
            sq *= (np.sin(TAU * 55 * np.arange(n) / D.SR) > 0)
            sq = D.bitcrush(sq, 5, 2)
        cv.add(D.fade(sq, 2, 12), t0, 0.7)

    # power-down whine
    t0 = 0.56
    nw = D.n_of(T - t0)
    fw = D.glide(1500, 42, nw)
    whine = D.harm(fw, 4, 1.0) * D.exp_env(nw, 0.3)
    whine = D.saturate(whine / np.max(np.abs(whine)), 1.3) * np.linspace(1, 0.2, nw)
    cv.add(0.6 * D.fade(whine, 5, 30), t0, 1.0)
    # last gasp: pop and a tiny ring
    cv.add(D.noise_burst(0.03, 0.006, 600, 7000, 2) * 0.9, 1.1, 1.0)
    cv.add(D.modal([3100, 5200], [1.0, 0.5], [0.02, 0.01], 0.1) * 0.3, 1.1, 1.0)
    return D.fade(cv.buf, 1.0, 15.0), -1.0
