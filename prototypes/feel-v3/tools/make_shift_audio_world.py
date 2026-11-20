"""World sound effects: levers, doors, walls, hazards, enemies. All synthesised (modal metal/stone, filtered noise)."""
from __future__ import annotations

import numpy as np

import make_shift_audio_dsp as D

TAU = 2 * np.pi


# ------------------------------------------------------------------ shared pieces
def chain(dur, r0, r1, lo=1800, hi=5200, decay=None, heavy=False):
    """Chain rattle: a shower of tiny metal hits whose rate slides from r0 to r1 per second."""
    bank = D.bank_clinks(26, lo, hi, (0.006, 0.022))
    cv = D.Canvas(dur)
    times = D.poisson_times(0.0, dur, lambda t: r0 + (r1 - r0) * t / dur, max(r0, r1))
    D.scatter(cv, times, bank, gain=1.0)
    if heavy:
        knock = D.bank_clinks(14, 450, 1300, (0.02, 0.05), 0.16)
        D.scatter(cv, [t for t in times if D.rng().uniform() < 0.3], knock, gain=0.8)
    y = cv.buf
    if decay:
        y = y * D.exp_env(len(y), decay)
    return y


def crackle(dur, r0, r1, lo, hi, tau=0.002):
    cv = D.Canvas(dur)
    for t in D.poisson_times(0.0, dur, lambda t: r0 + (r1 - r0) * t / dur, max(r0, r1)):
        cv.add(D.noise_burst(tau * 8, tau * D.rng().uniform(0.5, 1.5), lo, hi, 2), t, D.rng().exponential(0.6) + 0.1)
    return cv.buf


def finish(y, peak_db=-1.0, fin=1.0, fout=10.0):
    return D.fade(y, fin, fout), peak_db


def stick_slip(n, rate_hz=14.0):
    s = np.abs(D.lp(D.white(n), rate_hz, 2))
    return s / (np.max(s) + 1e-9)


# ------------------------------------------------------------------ mechanisms and rooms
def build_lever():
    D.seed(400)
    cv = D.Canvas(1.05)
    cv.add(0.3 * chain(0.32, 25, 80), 0.0)  # slack chain as the hand takes the lever
    t = 0.2
    for gap in [0.075, 0.063, 0.054, 0.047]:  # ratchet pawl clicks, speeding up
        click = D.mix(D.noise_burst(0.02, 0.004, 1400, 3800) * 0.8, D.modal([950, 1900], [1, 0.5], [0.01, 0.006], 0.04))
        cv.add(click, t, 0.8)
        t += gap
    clunk = D.mix(D.thump(135, 45, 0.5, 0.1, 1.5), 0.85 * D.metal(172, 0.7, 0.24, D.BAR, 0.7, 0.01),
                  0.6 * D.noise_burst(0.06, 0.012, None, 2600))
    cv.add(clunk, 0.46, 1.0)
    cv.add(0.55 * chain(0.5, 70, 8, heavy=True, decay=0.18), 0.5)  # chain swings and settles
    return finish(cv.buf)


def build_bars_open():
    D.seed(401)
    dur = 1.85
    n = D.n_of(dur)
    t = np.arange(n) / D.SR
    slip = stick_slip(n, 13.0)
    fc = 520 + 320 * np.sin(TAU * 1.7 * t + 0.5) + 160 * D.lp(D.white(n), 10, 2) / 0.07
    grind = D.svf(D.white(n), np.clip(fc, 200, 1500), q=3.5, mode="band")
    grind = grind / (np.std(grind) + 1e-9) * (0.3 + 0.7 * slip)
    rumble = D.lp(D.white(n), 130, 3) * (0.6 + 0.4 * slip)
    rumble = rumble / (np.std(rumble) + 1e-9)
    f_sq = D.glide(1150, 1550, n) * (1 + 0.03 * D.lp(D.white(n), 25, 1) / 0.12)
    gate = D.lp((slip > 0.72).astype(float), 60, 2)
    squeal = D.harm(f_sq, 5, 1.2) * gate
    body_env = D.ar_env(n, 0.12, None, 0.6)
    body_env = np.where(t < 1.5, np.minimum(1.0, t / 0.12), np.maximum(0.0, 1 - (t - 1.5) / 0.1))
    body = (grind + 0.8 * rumble + 0.35 * squeal / (np.std(squeal) + 1e-9)) * body_env
    cv = D.Canvas(dur)
    cv.add(body / (D.peak(body) + 1e-9), 0.0, 0.8)
    cv.add(0.45 * chain(1.45, 12, 45, heavy=True), 0.05)
    # the bars reach the top and bang into the stop
    stop = D.mix(D.thump(120, 48, 0.3, 0.07, 1.6), D.metal(210, 0.6, 0.2, D.BAR, 0.75, 0.01), 0.5 * D.noise_burst(0.05, 0.01, 300, 5000))
    cv.add(stop / D.peak(stop), 1.5, 0.95)
    cv.add(0.4 * chain(0.3, 50, 6, decay=0.1), 1.52)
    return finish(cv.buf)


def build_wall_crack():
    D.seed(402)
    cv = D.Canvas(0.8)
    cv.add(D.thump(170, 58, 0.35, 0.09, 2.0), 0.0, 0.95)  # the blow
    cv.add(D.noise_burst(0.14, 0.022, 700, 9000), 0.0, 1.0)  # the crack itself
    bank = D.bank_stone(26, 250, 2400, (0.01, 0.045), 0.12)
    times = [0.0, 0.02, 0.045, 0.08, 0.12, 0.17, 0.23, 0.31, 0.4]
    D.scatter(cv, times, bank, gains=[1, .9, .8, .7, .6, .5, .45, .35, .3], pitch_var=3.0)
    cv.add(0.55 * crackle(0.55, 70, 8, 900, 6500, 0.0015), 0.05)  # the crack running along the wall
    dust = D.noise_burst(0.6, 0.18, 3200, None, 2)
    cv.add(0.15 * dust, 0.05)
    # one creak as the stone settles
    n = D.n_of(0.3)
    creak = D.bp(D.sine(D.glide(300, 190, n), n) * (0.5 + 0.5 * stick_slip(n, 25)), 150, 900, 2) * D.bell_env(n, 0.4, 0.3)
    cv.add(0.2 * creak, 0.38)
    return finish(cv.buf)


def build_wall_crumble():
    D.seed(403)
    dur = 1.5
    cv = D.Canvas(dur)
    n = D.n_of(dur)
    cv.add(D.thump(95, 38, 0.6, 0.16, 1.8), 0.0, 0.8)
    cv.add(D.noise_burst(0.12, 0.03, 500, 8000), 0.0, 0.7)
    rumble = D.lp(D.white(n), 190, 3) * np.exp(-np.arange(n) / (D.SR * 0.75))
    cv.add(rumble / (D.peak(rumble) + 1e-9), 0.0, 0.7)
    bank = D.bank_stone(44, 160, 2300, (0.015, 0.07), 0.2)
    times = D.poisson_times(0.0, 1.35, lambda t: 110 * np.exp(-t / 0.55) + 5, 115)
    D.scatter(cv, times, bank, gain=0.9, pitch_var=4.0)
    # big blocks landing, then gravel sliding off
    for tt, f in [(0.22, 120), (0.5, 105), (0.88, 140)]:
        cv.add(0.7 * D.mix(D.thump(f, 52, 0.25, 0.05, 1.4), D.noise_burst(0.1, 0.025, 200, 1600)), tt)
    nn = D.n_of(1.2)
    sand = D.svf(D.white(nn), D.glide(3200, 500, nn), q=1.4, mode="band") * np.exp(-np.arange(nn) / (D.SR * 0.5))
    cv.add(0.45 * sand / (D.peak(sand) + 1e-9), 0.05)
    return finish(cv.buf, fout=40.0)


def build_locked():
    D.seed(404)
    cv = D.Canvas(0.8)
    cv.add(D.mix(D.thump(140, 70, 0.18, 0.04, 1.4), D.metal(150, 0.5, 0.17, D.BAR, 0.75, 0.01), 0.5 * D.noise_burst(0.04, 0.008, 400, 4000)), 0.0, 1.0)
    cv.add(0.6 * chain(0.2, 110, 40, 700, 3800, heavy=True), 0.04)
    cv.add(D.mix(D.thump(150, 80, 0.15, 0.035, 1.3), D.metal(190, 0.45, 0.14, D.BAR, 0.7, 0.01)), 0.31, 0.7)
    cv.add(0.4 * chain(0.18, 90, 30, 700, 3800, heavy=True), 0.34)
    # the final dull knock: it will not open
    cv.add(D.mix(D.thump(105, 62, 0.22, 0.05, 1.5), 0.4 * D.noise_burst(0.05, 0.01, 150, 1400)), 0.57, 0.8)
    cv.add(D.modal([1150, 2350], [1, 0.5], [0.009, 0.005], 0.05), 0.55, 0.3)  # bolt clicks home
    return finish(cv.buf)


# ------------------------------------------------------------------ hazards
def build_blade_swing():
    D.seed(410)
    dur = 0.95
    n = D.n_of(dur)
    x = np.linspace(0, 1, n)
    t = x * dur
    bump = np.exp(-0.5 * ((x - 0.48) / 0.2) ** 2)
    fc = 230 + 1000 * bump
    whoosh = D.svf(D.white(n), fc, q=1.8, mode="band")
    whoosh = whoosh / (np.std(whoosh) + 1e-9) * (0.08 + bump ** 1.3)
    air = D.lp(D.white(n), 110, 3) * bump
    air = air / (np.std(air) + 1e-9)
    ring_f = D.glide(1500, 1180, n)  # doppler drop as the blade passes
    ring = (D.sine(ring_f, n) + 0.5 * D.sine(ring_f * 2.76, n)) * bump ** 2
    cv = D.Canvas(dur)
    cv.add(whoosh / D.peak(whoosh), 0.0, 1.0)
    cv.add(0.5 * air / D.peak(air), 0.0, 1.0)
    cv.add(0.07 * ring, 0.0, 1.0)
    cv.add(0.25 * chain(0.3, 35, 10, heavy=True, decay=0.12), 0.0)  # the chain creaking on its mount
    return finish(cv.buf, fout=60.0)


def build_crusher_warn():
    D.seed(411)
    dur = 0.62
    cv = D.Canvas(dur)
    ch = chain(dur, 45, 110, 1500, 4800, heavy=True)
    cv.add(ch * np.linspace(0.3, 1.0, len(ch)), 0.0)
    # dust trickle: tiny high grains
    for tt in D.poisson_times(0.08, dur, lambda t: 140, 140):
        cv.add(D.noise_burst(0.01, 0.0015, 3500, None, 2), tt, D.rng().uniform(0.1, 0.35))
    n = D.n_of(dur)
    creak = D.bp(D.harm(D.glide(110, 165, n), 6, 1.0) * (0.4 + 0.6 * stick_slip(n, 22)), 120, 1100, 2)
    cv.add(0.3 * creak / (D.peak(creak) + 1e-9) * D.ar_env(n, 0.3, None, 1.0), 0.0)
    return finish(cv.buf, fout=25.0)


def build_crusher_slam():
    D.seed(412)
    dur = 1.35
    cv = D.Canvas(dur)
    n = D.n_of(dur)
    cv.add(D.thump(72, 26, dur, 0.38, 2.0), 0.0, 1.0)
    cv.add(D.thump(170, 52, 0.45, 0.09, 3.0), 0.0, 0.8)
    crash = D.svf(D.white(n), D.glide(9000, 300, n), q=0.8, mode="low") * D.exp_env(n, 0.2)
    cv.add(crash / (D.peak(crash) + 1e-9), 0.0, 0.8)
    cv.add(D.metal(72, dur, 0.6, D.BAR, 0.8, 0.01) / 1.5, 0.0, 0.5)
    cv.add(D.metal(215, 0.9, 0.3, D.BAR, 0.7, 0.012) / 1.5, 0.0, 0.5)
    bank = D.bank_stone(30, 180, 1900, (0.012, 0.05), 0.15)
    D.scatter(cv, D.poisson_times(0.04, 1.0, lambda t: 90 * np.exp(-t / 0.35) + 4, 95), bank, gain=0.6, pitch_var=3.0)
    dust = D.hp(D.white(n), 2500, 2) * D.exp_env(n, 0.35)
    cv.add(0.08 * dust, 0.05)
    y = D.reverb(cv.buf, D.cathedral_ir(1.0, 6, 1.0, seed_=41, early=False), wet=0.3, dry=0.95)
    y = y[: D.n_of(1.25)]
    return finish(y, fout=60.0)


def build_vent_hiss():
    D.seed(413)
    dur = 0.62
    n = D.n_of(dur)
    t = np.arange(n) / D.SR
    hiss = D.svf(D.white(n), D.glide(3800, 6800, n), q=1.1, mode="band") + 0.7 * D.hp(D.white(n), 3000, 3)
    hiss = hiss / (np.std(hiss) + 1e-9)
    env = np.minimum(1.0, t / 0.06) * np.where(t < dur - 0.16, 1.0, np.maximum(0.0, (dur - t) / 0.16))
    env = env * (1 + 0.12 * np.sin(TAU * 9 * t))
    pipe = D.svf(D.white(n), 1180, q=25, mode="band")
    pipe = pipe / (np.std(pipe) + 1e-9) * 0.12 * env
    cv = D.Canvas(dur)
    cv.add(hiss * env, 0.0, 1.0)
    cv.add(pipe, 0.0, 1.0)
    cv.add(D.modal([1250, 2900], [1, 0.4], [0.03, 0.015], 0.15), 0.0, 0.25)  # valve ticks open
    return finish(cv.buf, fout=20.0)


def build_vent_flame():
    D.seed(414)
    dur = 1.0
    n = D.n_of(dur)
    t = np.arange(n) / D.SR
    lfo = D.lp(D.white(n), 6, 1)
    lfo = lfo / (np.std(lfo) + 1e-9)
    roar = D.svf(D.white(n), 950 + 300 * lfo, q=0.8, mode="low") + 0.8 * D.bp(D.white(n), 130, 520, 2)
    roar = roar / (np.std(roar) + 1e-9)
    env = np.minimum(1.0, t / 0.07) * np.where(t < 0.55, 1.0, np.exp(-(t - 0.55) / 0.18))
    flicker = 1 + 0.32 * D.lp(D.white(n), 28, 2) / 0.1
    cv = D.Canvas(dur)
    cv.add(roar * env * np.clip(flicker, 0.3, 1.8), 0.0, 0.8)
    cv.add(D.mix(D.thump(75, 38, 0.5, 0.12, 1.3), 0.7 * D.noise_burst(0.14, 0.04, 200, 3200)), 0.0, 1.0)  # whump of ignition
    cv.add(0.55 * crackle(0.9, 70, 15, 1500, 6500, 0.0012), 0.05)
    cv.add(0.12 * D.hp(D.white(n), 3500, 2) * env, 0.0)
    return finish(cv.buf, fout=40.0)


def build_spikes():
    D.seed(415)
    cv = D.Canvas(0.5)
    for k, t0 in enumerate([0.0, 0.013, 0.029, 0.044]):
        n = D.n_of(0.11)
        shing = D.svf(D.white(n), D.glide(2400, 7800, n), q=2.6, mode="band") * D.exp_env(n, 0.035)
        cv.add(shing / (D.peak(shing) + 1e-9), t0, 0.7)
    # they hit their stops: a short bright metal rattle and a thud
    for k, t0 in enumerate([0.07, 0.085, 0.103, 0.118]):
        cv.add(D.metal(820 + 190 * k, 0.32, 0.14, D.BAR, 0.65, 0.01), t0, 0.5)
    cv.add(D.mix(D.thump(150, 62, 0.16, 0.03, 1.5), D.noise_burst(0.04, 0.008, 300, 3000)), 0.06, 0.7)
    cv.add(0.3 * chain(0.25, 80, 10, 2500, 6500, decay=0.08), 0.12)
    return finish(cv.buf, fout=40.0)


# ------------------------------------------------------------------ enemies
def build_crab_click():
    D.seed(420)
    cv = D.Canvas(0.52)
    for t0, f, g in [(0.0, 2300, 1.0), (0.115, 2550, 0.9), (0.245, 2200, 1.0)]:
        click = D.mix(D.modal([f, f * 1.43, f * 2.04], [1, 0.7, 0.4], [0.012, 0.008, 0.005], 0.09),
                      0.8 * D.modal([650, 1100], [1, 0.6], [0.02, 0.012], 0.08),
                      0.7 * D.noise_burst(0.012, 0.002, 2500, 9000, 2))
        cv.add(click, t0, g)
    cv.add(D.modal([1500, 3200], [1, 0.5], [0.04, 0.02], 0.12), 0.245, 0.12)  # a little scuttling rattle after
    return finish(cv.buf, fout=30.0)


def build_crab_spines():
    D.seed(421)
    cv = D.Canvas(0.78)
    bank = D.bank_clinks(26, 1400, 3800, (0.004, 0.012), 0.06)
    low = D.bank_clinks(10, 600, 1100, (0.01, 0.025), 0.08)
    times = [0.34 * (k / 22.0) ** 0.75 for k in range(22)]
    D.scatter(cv, times, bank, gains=[0.4 + 0.6 * k / 22 for k in range(22)], gain=1.0)
    D.scatter(cv, times[::3], low, gain=0.5)
    for t0 in [0.40, 0.425, 0.45, 0.48]:  # spines fire
        n = D.n_of(0.13)
        thwip = D.svf(D.white(n), D.glide(9500, 3500, n), q=3.0, mode="band") * D.exp_env(n, 0.03)
        cv.add(thwip / (D.peak(thwip) + 1e-9), t0, 0.85)
        cv.add(D.modal([4200], [1], [0.006], 0.03), t0, 0.3)
    return finish(cv.buf, fout=40.0)


def build_crab_burrow():
    D.seed(422)
    dur = 0.95
    n = D.n_of(dur)
    t = np.arange(n) / D.SR
    cv = D.Canvas(dur)
    gain_mod = 0.55 + 0.45 * np.sin(TAU * 11 * t) ** 2
    for tt in D.poisson_times(0.0, dur - 0.05, lambda x: 75, 75):
        g = gain_mod[min(n - 1, D.n_of(tt))] * D.rng().uniform(0.3, 1.0)
        cv.add(D.noise_burst(0.06, D.rng().uniform(0.01, 0.03), 180, D.rng().uniform(1200, 2600), 2), tt, g)
    sand = D.bp(D.white(n), 1800, 5200, 2) * gain_mod
    cv.add(0.22 * sand / (np.std(sand) + 1e-9) * 0.2, 0.0)
    rum = D.svf(D.white(n), D.glide(220, 70, n), q=1.2, mode="low")
    cv.add(0.45 * rum / (D.peak(rum) + 1e-9), 0.0)
    bank = D.bank_stone(12, 220, 1500, (0.012, 0.04), 0.12)
    D.scatter(cv, [0.12, 0.47, 0.72], bank, gain=0.7)
    y = cv.buf
    y = D.svf(y, D.glide(7000, 260, len(y)), q=0.6, mode="low")  # muffles as it goes underground
    y = y * np.where(t < dur - 0.2, 1.0, np.maximum(0.0, (dur - t) / 0.2))
    return finish(y, fout=20.0)


def build_crab_tink():
    D.seed(423)
    dur = 0.65
    cv = D.Canvas(dur)
    cv.add(D.modal([2250, 2250 * 2.76, 2250 * 5.4, 2250 * 8.93], [1, 0.6, 0.35, 0.2], [0.34, 0.2, 0.1, 0.06], dur), 0.0, 1.0)
    cv.add(D.modal([3130, 3130 * 2.4], [0.5, 0.25], [0.18, 0.09], 0.65), 0.0, 0.8)  # second, detuned ring: shell vs blade
    cv.add(D.modal([430, 760], [1, 0.5], [0.02, 0.012], 0.12), 0.0, 0.55)  # dull thud of the shell
    cv.add(D.noise_burst(0.012, 0.002, 3000, 12000, 2), 0.0, 0.9)  # the strike
    return finish(cv.buf, fout=80.0)


def build_moth_flutter():
    D.seed(430)
    N = D.n_of(1.0)
    t = np.arange(N) / D.SR
    flaps = 14
    env = (0.5 - 0.5 * np.cos(TAU * flaps * t)) ** 1.4
    jitter = 1 + 0.25 * D.slow_random(N, 30) / 2.0
    body = D.fft_noise(N, lambda f: np.where((f > 120) & (f < 1300), 1.0 / (1 + (f / 700.0) ** 2), 0.0))
    dust = D.fft_noise(N, lambda f: np.where((f > 2500) & (f < 7000), 1.0, 0.0))
    low = np.sin(TAU * 70 * t) * env ** 2.5
    y = body * env * jitter + 0.14 * dust * env ** 2 + 0.45 * low
    return y, -6.0


def build_moth_gust():
    D.seed(431)
    dur = 0.95
    n = D.n_of(dur)
    x = np.linspace(0, 1, n)
    bump = np.exp(-0.5 * ((x - 0.14) / 0.1) ** 2) + 0.95 * np.exp(-0.5 * ((x - 0.4) / 0.13) ** 2)
    tail = np.exp(-np.maximum(0, x - 0.4) / 0.25) * 0.35
    env = np.maximum(bump, tail)
    fc = 320 + 1000 * env
    wind = D.svf(D.white(n), fc, q=1.4, mode="band")
    wind = wind / (np.std(wind) + 1e-9) * env
    cv = D.Canvas(dur)
    cv.add(wind / D.peak(wind), 0.0, 1.0)
    for t0, g in [(0.09, 1.0), (0.31, 0.85)]:  # two heavy wingbeats
        cv.add(D.mix(D.thump(95, 52, 0.22, 0.06, 1.3), 0.6 * D.noise_burst(0.12, 0.04, 150, 1200)), t0, g * 0.8)
    cv.add(0.1 * D.hp(D.white(n), 3000, 2) * env, 0.0)
    return finish(cv.buf, fout=80.0)


def build_censer_chime():
    D.seed(440)
    dur = 1.05
    cv = D.Canvas(dur)
    cv.add(0.4 * chain(0.4, 70, 25, 2200, 6500), 0.0)  # chain jingles as the censer swings
    for t0, f, g in [(0.02, 880.0, 1.0), (0.15, 932.3, 0.8), (0.29, 1318.5, 0.65)]:  # G-ish, flat 2nd above, then a fifth: unsettling
        amps = [1.0, 0.7, 0.55, 0.4, 0.5, 0.3, 0.25, 0.15, 0.1]
        taus = [0.55 / (k ** 0.5) for k in D.BELL]
        bell = D.modal([f * k for k in D.BELL], amps, taus, 0.8)
        cv.add(bell / D.peak(bell), t0, g * 0.8)
    y = D.reverb(cv.buf, D.cathedral_ir(1.1, 8, 0.9, seed_=44, early=False), wet=0.25, dry=0.95)
    return finish(y[: D.n_of(1.15)], fout=100.0)


def build_scribe_scratch():
    D.seed(450)
    dur = 0.66
    cv = D.Canvas(dur)
    for t0, d, up in [(0.0, 0.07, 1), (0.095, 0.05, 0), (0.18, 0.09, 1), (0.30, 0.055, 0), (0.395, 0.085, 1)]:
        n = D.n_of(d)
        a, b = (3000, 5800) if up else (5600, 2800)
        s = D.svf(D.white(n), D.glide(a, b, n), q=2.6, mode="band")
        shape = np.sin(np.linspace(0, np.pi, n)) ** 0.7
        fibre = (1 + 0.6 * np.sign(np.sin(TAU * D.rng().uniform(120, 260) * np.arange(n) / D.SR)))
        grain = D.lp(D.white(n), 1600, 2)
        s = (s / (np.std(s) + 1e-9) * fibre * 0.6 + 0.4 * grain / (np.std(grain) + 1e-9)) * shape
        cv.add(s / (D.peak(s) + 1e-9), t0, D.rng().uniform(0.7, 1.0))
    # the ink glows: a thin charging shimmer
    n = D.n_of(0.36)
    shim = (D.sine(1760, n) + 0.7 * D.sine(2349, n) + 0.4 * D.sine(3136, n)) * (0.6 + 0.4 * np.sin(TAU * 11 * np.arange(n) / D.SR))
    cv.add(0.14 * shim * D.ar_env(n, 0.3, 0.06, 1.0), 0.3, 1.0)
    return finish(cv.buf, fout=40.0)


def build_scribe_needle():
    D.seed(451)
    dur = 0.5
    n = D.n_of(0.4)
    f = D.glide(3700, 2350, n)
    env = D.bell_env(n, 0.4, 0.28)
    whistle = D.sine(f, n) * env
    breath = D.svf(D.white(n), f, q=25, mode="band")
    breath = breath / (np.std(breath) + 1e-9) * env * 0.5
    over = D.sine(f * 2.01, n) * env ** 2 * 0.15
    cv = D.Canvas(dur)
    cv.add(whistle * 0.38 + breath * 0.22 + 0.5 * over, 0.04, 1.0)
    cv.add(D.mix(D.noise_burst(0.02, 0.004, 1800, 9000, 2), D.modal([2600], [1], [0.008], 0.04)), 0.0, 1.0)  # the flick that throws it
    return finish(cv.buf, fout=80.0)


def build_glyph_burst():
    D.seed(452)
    dur = 0.95
    cv = D.Canvas(dur)
    n = D.n_of(0.14)
    x = np.linspace(0, 1, n)
    sw = D.svf(D.white(n), D.glide(500, 6000, n), q=2.0, mode="band") * x ** 2
    cv.add(0.5 * sw / (D.peak(sw) + 1e-9), 0.0)  # the glyph sucks air in
    t0 = 0.14
    cv.add(D.noise_burst(0.28, 0.055, 300, 7000), t0, 1.0)
    cv.add(D.thump(150, 50, 0.35, 0.07, 2.0), t0, 0.5)
    nn = D.n_of(0.7)
    tt = np.arange(nn) / D.SR
    for f0, g in [(660, 1.0), (990, 0.7), (1320, 0.5)]:
        sh = D.sine(D.glide(f0, f0 * 1.03, nn), nn) * np.exp(-tt / 0.28) * (0.7 + 0.3 * np.sin(TAU * 14 * tt))
        cv.add(0.42 * g * sh, t0, 1.0)
    cv.add(D.metal(880, 0.6, 0.25, D.PLATE, 0.8, 0.01) * 0.25, t0, 1.0)
    for _ in range(24):
        ts = t0 + D.rng().exponential(0.18)
        if ts > dur - 0.1:
            continue
        d = D.rng().uniform(0.03, 0.14)
        ping = D.sine(D.rng().uniform(2500, 9000), D.n_of(d * 5)) * D.exp_env(D.n_of(d * 5), d)
        cv.add(ping, ts, 0.14 * D.rng().uniform(0.4, 1.0))
    y = D.reverb(cv.buf, D.cathedral_ir(0.9, 6, 1.0, seed_=45, early=False), wet=0.3, dry=0.95)
    return finish(y[: D.n_of(1.0)], fout=80.0)


def build_ink_drip():
    D.seed(453)
    dur = 0.58
    cv = D.Canvas(dur)
    n = D.n_of(0.22)
    stretch = D.sine(D.glide(115, 215, n), n) * D.bell_env(n, 0.75, 0.3)  # ink thread stretching
    stretch = stretch + D.lp(D.white(n), 500, 2) * 0.08
    cv.add(0.22 * stretch, 0.0)
    nd = D.n_of(0.18)
    drop = D.sine(D.glide(560, 170, nd), nd) * D.exp_env(nd, 0.045)
    plop = D.noise_burst(0.07, 0.02, None, 800, 2)
    body = D.sine(88, nd) * D.exp_env(nd, 0.06)
    cv.add(D.mix(drop, 0.5 * plop / D.peak(plop), 0.5 * body), 0.22, 1.0)
    nd2 = D.n_of(0.1)
    drop2 = D.sine(D.glide(840, 310, nd2), nd2) * D.exp_env(nd2, 0.022)
    cv.add(0.45 * drop2, 0.39)
    cv.add(0.12 * D.noise_burst(0.04, 0.01, None, 1000, 2), 0.39)
    return finish(cv.buf, fout=40.0)


def build_leech_squelch():
    D.seed(454)
    dur = 0.52
    cv = D.Canvas(dur)
    n = D.n_of(0.13)
    suck = D.svf(D.white(n), D.glide(350, 1500, n), q=7.0, mode="band") * D.bell_env(n, 0.55, 0.3)
    cv.add(suck / (D.peak(suck) + 1e-9), 0.02, 1.0)
    for t0 in [0.12, 0.17, 0.225, 0.29]:  # wet bubbles
        nb = D.n_of(D.rng().uniform(0.015, 0.03))
        f0 = D.rng().uniform(250, 600)
        b = D.sine(D.glide(f0, f0 * D.rng().uniform(1.8, 2.8), nb), nb) * D.exp_env(nb, 0.012)
        cv.add(b, t0, D.rng().uniform(0.4, 0.7))
    cv.add(crackle(0.3, 90, 20, 500, 3200, 0.002), 0.08, 0.3)
    cv.add(D.mix(D.modal([1100], [1], [0.01], 0.04), 0.6 * D.noise_burst(0.015, 0.003, 800, 4500, 2)), 0.34, 0.6)
    return finish(cv.buf, fout=40.0)


def build_leech_drop():
    D.seed(455)
    dur = 0.72
    cv = D.Canvas(dur)
    n = D.n_of(0.08)
    twang = D.sine(D.glide(3400, 2400, n), n) * D.exp_env(n, 0.016)
    cv.add(D.mix(twang, 0.8 * D.noise_burst(0.015, 0.002, 2000, 9000, 2)), 0.0, 0.8)  # thread snaps
    nw = D.n_of(0.4)
    tw = np.arange(nw) / D.SR
    whoosh = D.svf(D.white(nw), D.glide(1700, 320, nw), q=3.0, mode="band") * np.sin(np.linspace(0, np.pi, nw)) ** 0.8
    whoosh = whoosh * (1 + 0.5 * np.sin(TAU * 38 * tw))
    cv.add(whoosh / (D.peak(whoosh) + 1e-9), 0.03, 0.85)  # wet whoosh down
    t_hit = 0.43
    cv.add(D.thump(115, 55, 0.2, 0.04, 1.4), t_hit, 0.7)
    cv.add(D.noise_burst(0.1, 0.03, 200, 1300), t_hit, 0.9)
    for dt in [0.01, 0.045, 0.085]:
        nb = D.n_of(0.025)
        f0 = D.rng().uniform(250, 500)
        cv.add(D.sine(D.glide(f0, f0 * 2.2, nb), nb) * D.exp_env(nb, 0.01), t_hit + dt, 0.45)
    return finish(cv.buf, fout=40.0)


# ------------------------------------------------------------------ S1 world cues (2026-11-19)
def build_door_lamp():
    """A door's lamp changes: a relay tick and a short glass hum."""
    D.seed(610)
    cv = D.Canvas(0.45)
    cv.add(D.noise_burst(0.015, 0.003, 2000, 6000) * 0.7, 0.0)
    hum = D.sine(D.glide(220, 330, D.n_of(0.3))) * D.ar_env(D.n_of(0.3), 0.01, 0.25)
    cv.add(0.35 * hum + 0.15 * D.modal([660, 1320], [1, 0.4], [0.08, 0.05], 0.3), 0.02)
    return finish(cv.buf, peak_db=-4.0)


def build_chain_run():
    """A long chain runs through a pulley: a fast heavy rattle that slows down."""
    D.seed(611)
    return finish(chain(1.4, 90, 14, heavy=True, decay=0.9), fout=60.0)


def build_boom():
    """A deep stone boom far off: a low thump and a stone rumble."""
    D.seed(612)
    cv = D.Canvas(1.6)
    cv.add(D.thump(70, 32, 1.2, 0.35, 2.0), 0.0)
    cv.add(0.5 * D.lp(D.pink(D.n_of(1.5)), 300) * D.exp_env(D.n_of(1.5), 0.45), 0.02)
    return finish(cv.buf, peak_db=-1.5, fout=80.0)


def build_dust():
    """Dust and grit trickle down: a soft dry crackle."""
    D.seed(613)
    return finish(0.6 * crackle(0.9, 70, 4, 2500, 9000), peak_db=-8.0, fout=60.0)


def build_cold_air():
    """A breath of cold air: a filtered noise swell."""
    D.seed(614)
    n = D.n_of(1.6)
    y = D.bp(D.pink(n), 300, 1400) * D.bell_env(n, 0.45, 0.3)
    return finish(y, peak_db=-8.0, fin=60.0, fout=200.0)


def build_candle():
    """A candle catches: a soft whoosh and a tiny crackle."""
    D.seed(615)
    cv = D.Canvas(0.8)
    n = D.n_of(0.35)
    cv.add(D.bp(D.white(n), 500, 2500) * D.ar_env(n, 0.06, 0.25) * 0.8, 0.0)
    cv.add(0.4 * crackle(0.6, 30, 6, 2000, 7000), 0.12)
    return finish(cv.buf, peak_db=-5.0)


def build_rattle():
    """Something shut rattles in its frame: a short chain shake and a knock."""
    D.seed(616)
    cv = D.Canvas(0.5)
    cv.add(chain(0.35, 120, 60, heavy=True), 0.0)
    cv.add(0.6 * D.thump(150, 80, 0.12, 0.04), 0.05)
    return finish(cv.buf, peak_db=-4.0)


def build_winch():
    """The winch turns: ratchet clicks, a groaning drum, a chain hauled in."""
    D.seed(617)
    cv = D.Canvas(1.5)
    t = 0.0
    for gap in [0.11, 0.1, 0.095, 0.09, 0.09, 0.095, 0.1, 0.12]:
        click = D.mix(D.noise_burst(0.02, 0.004, 1200, 3600) * 0.8, D.modal([700, 1450], [1, 0.5], [0.012, 0.007], 0.05))
        cv.add(click, t, 0.7)
        t += gap
    n = D.n_of(1.0)
    groan = D.bp(D.white(n), 90, 400) * stick_slip(n, 9.0) * 0.6
    cv.add(groan, 0.05)
    cv.add(0.5 * chain(1.1, 40, 20, heavy=True, decay=0.8), 0.15)
    return finish(cv.buf, peak_db=-2.0, fout=60.0)


BUILDERS = {
    "lever": build_lever,
    "bars_open": build_bars_open,
    "wall_crack": build_wall_crack,
    "wall_crumble": build_wall_crumble,
    "locked": build_locked,
    "blade_swing": build_blade_swing,
    "crusher_warn": build_crusher_warn,
    "crusher_slam": build_crusher_slam,
    "vent_hiss": build_vent_hiss,
    "vent_flame": build_vent_flame,
    "spikes": build_spikes,
    "crab_click": build_crab_click,
    "crab_spines": build_crab_spines,
    "crab_burrow": build_crab_burrow,
    "crab_tink": build_crab_tink,
    "moth_flutter": build_moth_flutter,
    "moth_gust": build_moth_gust,
    "censer_chime": build_censer_chime,
    "scribe_scratch": build_scribe_scratch,
    "scribe_needle": build_scribe_needle,
    "glyph_burst": build_glyph_burst,
    "ink_drip": build_ink_drip,
    "leech_squelch": build_leech_squelch,
    "leech_drop": build_leech_drop,
    "door_lamp": build_door_lamp,
    "chain_run": build_chain_run,
    "boom": build_boom,
    "dust": build_dust,
    "cold_air": build_cold_air,
    "candle": build_candle,
    "rattle": build_rattle,
    "winch": build_winch,
}
