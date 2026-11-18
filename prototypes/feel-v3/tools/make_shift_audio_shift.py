"""Shift family: shift_tear, incant_01..06, whisper_01..05 (builders for make_shift_audio.py)."""
from __future__ import annotations

import numpy as np

import make_shift_audio_dsp as D
import make_shift_audio_voice as V

# Dark chord used by the choirs (A, C, Eb, A, Bb, E: diminished stack with a clashing flat ninth)
DARK_CHORD = [110.0, 130.81, 155.56, 220.0, 233.08, 329.63]


def fit(x, lo, hi, tail_fade=1.0):
    """Keep length in [lo, hi] seconds: long -> cut with a fade, short -> pad with silence."""
    n_hi, n_lo = D.n_of(hi), D.n_of(lo)
    if len(x) > n_hi:
        x = D.fade_out(x[:n_hi], tail_fade)
    elif len(x) < n_lo:
        x = D.pad_to(x, n_lo)
    return D.fade(x, 3.0, 20.0)


# ------------------------------------------------------------------ incantations
# (raw line, pitch shift, start delay s, level relative to the voice) of the whispered double
BREATH = {1: ("inc1", -2.0, 0.0, 0.22), 2: ("inc2", -3.0, 0.0, 0.2), 3: ("inc3", -1.0, 0.0, 0.24),
          4: ("inc4", -3.0, 0.0, 0.2), 5: ("inc5", -2.0, 2.08, 0.24), 6: ("inc6", -4.0, 0.25, 0.2)}


def build_incant(i: int):
    D.seed(100 + i)
    if i == 1:  # David: slow, low, hollow; reversed copy trailing; drone
        ir = D.cathedral_ir(3.6, 30, 1.0, seed_=1)
        y = V.ghost(V.raw("inc1"), semis=-8, octave=0.55, rev=0.35, rev_delay=0.5, trem=(0.55, 0.5),
                    smear=0.5, formants=D.CHOIR_FORMANTS, drive=2.0, ir=ir, wet=0.5, drone=0.1, drone_f0=41.0)
    elif i == 2:  # Zira: vocoded into a robotic choir on a dark chord, plus her own low ghost
        ir = D.cathedral_ir(3.2, 20, 0.9, seed_=2)
        a = D.pitch(V.raw("inc2"), -9)
        carrier = V.chord_carrier([146.83, 174.61, 220.0, 277.18, 293.66], len(a), detune_cents=14, voices=3)
        choir = D.vocoder(a, carrier, nb=22, lo=120, hi=7000, env_hz=40, hf_boost=3.0)
        choir = choir / (D.peak(choir) + 1e-9)
        own = V.ghost(V.raw("inc2"), semis=-9, octave=0.5, rev=0.25, rev_delay=0.3, trem=(0.8, 0.5),
                      smear=0.6, drive=2.5, ir=None, wet=0, drone=0)
        y = D.mix(0.85 * choir, 0.55 * own / (D.peak(own) + 1e-9))
        y = D.tremolo(y, 0.45, 0.35)
        y = D.reverb(D.saturate(y / D.peak(y), 1.8), ir, wet=0.55, dry=0.8)
        y = y + 0.1 * D.peak(y) * V.drone_under(len(y), 36.7)
    elif i == 3:  # David: echoing "tuum... tuum", comb smear, slow ring-mod growl
        ir = D.cathedral_ir(4.0, 40, 1.1, seed_=3)
        y = V.ghost(V.raw("inc3"), semis=-6, octave=0.45, rev=0.2, rev_delay=0.2, trem=(0.8, 0.35),
                    smear=0.5, formants=D.HOLLOW_FORMANTS, comb_ms=7.0, comb_fb=0.72, drive=2.4,
                    ring=0.22, ring_hz=38.0, echo_s=0.43, echo_fb=0.5, ir=ir, wet=0.48, drone=0.1, drone_f0=46.0)
    elif i == 4:  # Zira: two-voiced, harsh growl, "oo" mouth
        ir = D.cathedral_ir(3.0, 15, 0.8, seed_=4)
        base = V.raw("inc4")
        low = V.ghost(base, semis=-10, octave=0.7, rev=0.0, trem=(1.1, 0.55), smear=0.6,
                      formants=D.OO_FORMANTS, drive=4.0, ring=0.35, ring_hz=47.0, ir=None, drone=0)
        high = V.ghost(base, semis=-4, octave=0.0, rev=0.4, rev_delay=0.1, trem=(0.7, 0.4), smear=0.5,
                       drive=2.0, ir=None, drone=0)
        y = D.mix(low / D.peak(low), 0.45 * high / D.peak(high))
        y = D.reverb(y, ir, wet=0.5, dry=0.85)
        y = y + 0.1 * D.peak(y) * V.drone_under(len(y), 43.7)
    elif i == 5:  # David: words arrive out of their own reverb (reverse-reverb swell), then ring out
        ir_s = D.cathedral_ir(1.8, 10, 1.0, seed_=5)
        ir = D.cathedral_ir(3.4, 30, 1.0, seed_=15)
        base = D.pitch(V.raw("inc5"), -6)
        sw = D.reverse(D.reverb(D.reverse(base), ir_s, wet=1.0, dry=0.0))
        fwd = np.concatenate([np.zeros(len(ir_s) - 1), base])
        mixed = D.mix(0.9 * sw / D.peak(sw), 0.8 * fwd / D.peak(fwd))
        mixed = D.formant_smear(mixed, D.CHOIR_FORMANTS, 0.45)
        mixed = D.tremolo(mixed, 0.5, 0.4)
        oct_ = D.pitch(mixed, -12)
        y = D.mix(mixed, 0.5 * oct_)
        y = D.reverb(D.saturate(y / D.peak(y), 2.2), ir, wet=0.45, dry=0.85)
        y = y + 0.1 * D.peak(y) * V.drone_under(len(y), 38.9)
    else:  # 6: a crowd: five pitched copies from both voices, staggered
        ir = D.cathedral_ir(4.2, 35, 1.0, seed_=6)
        layers = []
        for key, st, dly, g in [("inc6b", -5, 0.0, 0.8), ("inc6", -7, 0.25, 0.9), ("inc6b", -9, 0.5, 0.7),
                                ("inc6", -12, 0.15, 0.8), ("inc6b", -14, 0.4, 0.6)]:
            c = V.ghost(V.raw(key), semis=st, octave=0.0, rev=0.0, trem=(D.rng().uniform(0.4, 0.9), 0.5),
                        smear=0.5, formants=D.CHOIR_FORMANTS if st > -10 else D.HOLLOW_FORMANTS,
                        drive=1.8, ir=None, drone=0)
            layers.append(np.concatenate([np.zeros(D.n_of(dly)), c / D.peak(c) * g]))
        y = D.mix(*layers)
        y = D.reverb(D.saturate(y / D.peak(y), 1.6), ir, wet=0.55, dry=0.75)
        y = y + 0.1 * D.peak(y) * V.drone_under(len(y), 40.2)
    # a whispering double of the same line rides on top: this is the air the pitched-down voice lacks
    bkey, bst, bdly, bgain = BREATH[i]
    br = whisper_layer(bkey, bst, hf=2.4)
    br = D.reverb(br, D.cathedral_ir(1.6, 12, 1.2, seed_=40 + i, early=False), wet=0.6, dry=0.8)
    br = np.concatenate([np.zeros(D.n_of(bdly)), br])
    y = D.mix(y, br / (D.peak(br) + 1e-9) * D.peak(y) * bgain)
    y = fit(y, 3.0, 7.0)
    return y, -1.0


# ------------------------------------------------------------------ whispers
def whisper_layer(key, semis=0.0, reverse=False, hf=2.0, lo=150.0, tilt_noise=0.0):
    x = V.raw(key)
    if semis:
        x = D.pitch(x, semis)
    if reverse:
        x = D.reverse(x)
    n = len(x)
    car = D.white(n)
    if tilt_noise:
        car = D.lp(car, 2500, 1) * tilt_noise + car * (1 - tilt_noise)
    w = D.vocoder(x, car, nb=28, lo=lo, hi=9500, env_hz=75.0, hf_boost=hf)
    w = w + 0.18 * D.hp(x, 3500)
    w = D.hp(w, 140, 2)
    env = D.lp(np.abs(w), 25, 2) + 0.02 * D.peak(w)  # gentle levelling: whispers stay audible
    w = w * (env / (np.max(env) + 1e-9)) ** -0.35
    return w / (D.peak(w) + 1e-9)


def build_whisper(i: int):
    D.seed(200 + i)
    ir_s = D.cathedral_ir(0.9, 4, 1.4, seed_=30 + i, early=False)
    if i == 1:  # "veni", near, then echoing away
        a = whisper_layer("wh1", 0.0)
        y = D.mix(a, np.concatenate([np.zeros(D.n_of(0.55)), 0.55 * whisper_layer("wh1", -2.0)]),
                  np.concatenate([np.zeros(D.n_of(1.1)), 0.3 * whisper_layer("wh1", -5.0, tilt_noise=0.5)]))
        y = D.reverb(y, ir_s, wet=0.28, dry=0.9)
    elif i == 2:  # "non est tuum": pitched down, reversed ghost a hair behind, comb
        a = whisper_layer("wh2", -3.0, tilt_noise=0.3)
        b = np.concatenate([np.zeros(D.n_of(0.14)), 0.35 * whisper_layer("wh2", -3.0, reverse=True)])
        y = D.mix(a, b)
        y = D.comb(y, 4.3, 0.45, tail_s=0.5)
        y = D.reverb(y, ir_s, wet=0.3, dry=0.9)
    elif i == 3:  # "tacete": slow ear-to-ear flutter
        a = whisper_layer("wh3", 0.0, hf=2.4)
        a = D.tremolo(a, 5.0, 0.3)
        y = D.reverb(a, ir_s, wet=0.35, dry=0.9)
        y = D.pad_to(y, D.n_of(2.1))
    elif i == 4:  # "audi nomen tuum": up a little, thin, child-like and wrong
        a = whisper_layer("wh4", 3.0, hf=2.8, lo=220.0)
        b = np.concatenate([np.zeros(D.n_of(0.75)), 0.4 * whisper_layer("wh4", -4.0)])
        y = D.mix(a, b)
        y = D.reverb(y, ir_s, wet=0.3, dry=0.9)
    else:  # 5: "sub umbra, sub umbra": low and slow, a breathy low murmur under it
        a = whisper_layer("wh5", -4.0, hf=1.5, lo=110.0, tilt_noise=0.55)
        b = np.concatenate([np.zeros(D.n_of(0.1)), 0.4 * D.pitch(whisper_layer("wh5", -4.0, tilt_noise=0.8), -5)])
        y = D.mix(a, b)
        y = D.formant_smear(y, D.HOLLOW_FORMANTS, 0.35)
        y = D.reverb(y, ir_s, wet=0.3, dry=0.9)
    y = fit(y, 1.5, 3.0, 0.5)
    return y, -1.0


# ------------------------------------------------------------------ the shift
def build_shift_tear():
    D.seed(7)
    T = 5.8
    t_hit = 1.75
    ir_big = D.cathedral_ir(3.6, 30, 1.0, seed_=21)
    ir_mid = D.cathedral_ir(2.4, 15, 1.0, seed_=22)
    cv = D.Canvas(T)

    # ---- 1. reverse swell before the hit
    sw_n = D.n_of(t_hit - 0.05)
    x = np.linspace(0, 1, sw_n)
    voice = V.ghost(V.raw("ch1"), semis=-10, octave=0.5, rev=0.0, trem=None, smear=0.5, drive=2.0,
                    ir=ir_mid, wet=0.9)
    vrev = D.reverse(voice)
    vrev = D.pad_to(np.concatenate([np.zeros(max(0, sw_n - len(vrev))), vrev]), sw_n)[-sw_n:]
    voice_sw = vrev * (x ** 2.2)
    sweep = D.svf(D.white(sw_n), D.glide(140, 4200, sw_n), q=3.0, mode="band")
    noise_sw = sweep / (np.std(sweep) + 1e-9) * (x ** 2.4)
    glide_a = D.harm(D.glide(110, 880, sw_n), 14, 1.0) * (x ** 2.6)
    glide_b = D.harm(D.glide(116.5, 932, sw_n) * (1 + 0.004 * np.sin(2 * np.pi * 6 * np.arange(sw_n) / D.SR)), 10, 1.0) * (x ** 2.6)
    sub = D.sine(D.glide(30, 41, sw_n), sw_n) * (x ** 2.0)
    swell = (1.0 * voice_sw / (D.peak(voice_sw) + 1e-9) + 0.55 * noise_sw / (D.peak(noise_sw) + 1e-9)
             + 0.4 * (glide_a + 0.7 * glide_b) / (D.peak(glide_a) + 1e-9) + 0.45 * sub)
    # vacuum just before the hit
    cut = D.n_of(0.03)
    swell[-cut:] *= np.linspace(1, 0, cut) ** 2
    cv.add(swell / D.peak(swell), 0.0, 0.6)

    # ---- 2. the hit
    n_h = D.n_of(3.0)
    crash = D.svf(D.white(n_h), D.glide(11000, 350, n_h), q=0.8, mode="low") * D.exp_env(n_h, 0.30)
    crash = crash / (D.peak(crash) + 1e-9)
    rumble = D.lp(D.white(n_h), 150, 3) * D.exp_env(n_h, 0.95)
    rumble = rumble / (D.peak(rumble) + 1e-9)
    boom = D.metal(58.0, 3.0, 1.3, D.BAR, 0.65, 0.01)
    boom = boom / (D.peak(boom) + 1e-9)
    hit = D.mix(D.thump(95, 30, 3.0, 0.62, 1.6), 0.6 * D.thump(190, 55, 0.6, 0.13, 3.0), 0.7 * crash,
                0.5 * rumble, 0.3 * boom)
    hit = hit / D.peak(hit)
    # reverb only above 140 Hz: the sub-bass stays tight so the attack is the loudest moment
    hit = D.mix(hit, D.reverb(D.hp(hit, 140, 2), ir_big, wet=0.55, dry=0.0))
    cv.add(hit, t_hit, 1.0)

    # ---- 3. choir chord of processed voices
    L = 3.9
    nL = D.n_of(L)
    sa = D.paulstretch(D.pitch(V.raw("ch1"), -4), 3.2)
    sb = D.paulstretch(D.pitch(V.raw("ch2"), -2), 4.0)
    chA = D.vocoder(D.pad_to(sa, nL), V.chord_carrier(DARK_CHORD, nL, 16, 3), nb=22, lo=100, hi=6500, env_hz=30)
    chB = D.vocoder(D.pad_to(sb, nL), V.chord_carrier([f * 2 for f in DARK_CHORD[:4]], nL, 18, 3), nb=22, lo=100, hi=6500, env_hz=30)
    choir = D.mix(chA / (D.peak(chA) + 1e-9), 0.6 * chB / (D.peak(chB) + 1e-9))
    env = D.ar_env(nL, 0.12, None, 1.0) * np.exp(-np.arange(nL) / (D.SR * 2.6))
    choir = D.saturate(choir / D.peak(choir) * env, 1.6)
    choir = D.tremolo(choir, 0.5, 0.3)
    choir = D.reverb(choir, ir_big, wet=0.55, dry=0.75)
    cv.add(choir, t_hit + 0.06, 0.4)

    # ---- 4. glass and metal shriek
    ns = D.n_of(1.7)
    ts = np.arange(ns) / D.SR
    wob = 1 + 0.012 * np.sin(2 * np.pi * 6.5 * ts) + 0.006 * D.lp(D.white(ns), 18, 1) / 0.12
    fscr = D.glide(1500, 3900, ns) * wob
    scr = D.harm(fscr, 14, 0.9)
    scr = D.bp(D.saturate(scr, 4.0), 1300, 7500, 2)
    scr = scr * D.ar_env(ns, 0.08, None, 1.0) ** 0.7 * np.exp(-ts / 1.0)
    scr = scr / (D.peak(scr) + 1e-9)
    glass = D.modal([1900 * k for k in D.PLATE], [1, .8, .7, .65, .5, .45, .35, .3],
                    [1.1 / k ** 0.6 for k in D.PLATE], 2.3)
    glass = glass / (D.peak(glass) + 1e-9)
    shriek = D.mix(scr, 0.55 * glass)
    for _ in range(46):
        tt = D.rng().exponential(0.6)
        if tt > 2.0:
            continue
        f = D.rng().uniform(3500, 11500)
        d = D.rng().uniform(0.05, 0.28)
        ping = D.sine(f, D.n_of(d * 5)) * D.exp_env(D.n_of(d * 5), d)
        shriek = D.mix(shriek, np.concatenate([np.zeros(D.n_of(tt)), 0.18 * D.rng().uniform(0.4, 1) * ping]))
    shriek = D.reverb(shriek / D.peak(shriek), ir_mid, wet=0.45, dry=0.9)
    cv.add(shriek, t_hit + 0.1, 0.26)

    # ---- 5. what the new world starts to say: a murmur in the tail, and a low drone from the hit on
    murmur = V.ghost(V.raw("ch3"), semis=-12, octave=0.6, rev=0.3, rev_delay=0.3, trem=(0.6, 0.5),
                     smear=0.5, formants=D.HOLLOW_FORMANTS, drive=2.0, ir=ir_mid, wet=0.7)
    cv.add(D.fade_in(murmur / D.peak(murmur), 0.4), t_hit + 1.35, 0.22)
    nd = D.n_of(T - t_hit)
    dr = V.drone_under(nd, 38.9, 1.0, D.ar_env(nd, 0.6, None, 1.0) ** 1.2)
    cv.add(dr, t_hit, 0.36)

    y = D.fade_out(cv.buf, 1.4)
    y = D.fade(y, 2.0, 10.0)
    return y, -1.0
