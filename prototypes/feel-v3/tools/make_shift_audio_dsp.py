"""DSP primitives for tools/make_shift_audio.py (shift / world sound generator).

Pure numpy + scipy. Everything is deterministic: call seed(n) before building a file.
Functions work on float64 mono arrays at SR = 44100 unless stated.
"""
from __future__ import annotations

from fractions import Fraction

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
_rng = np.random.default_rng(0)


def seed(n: int) -> None:
    global _rng
    _rng = np.random.default_rng(n)


def rng() -> np.random.Generator:
    return _rng


# ---------------------------------------------------------------- basics
def n_of(sec: float) -> int:
    return int(round(sec * SR))


def tax(sec: float) -> np.ndarray:
    return np.arange(n_of(sec)) / SR


def db(x: float) -> float:
    return 10 ** (x / 20.0)


def peak(x: np.ndarray) -> float:
    return float(np.max(np.abs(x))) if len(x) else 0.0


def rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(np.square(x)))) if len(x) else 0.0


def normalize(x: np.ndarray, peak_db: float) -> np.ndarray:
    p = peak(x)
    if p < 1e-9:
        return x
    return x * (db(peak_db) / p)


def pad_to(x: np.ndarray, n: int) -> np.ndarray:
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def mix(*parts, gains=None) -> np.ndarray:
    """Sum arrays of different lengths (padded at the end)."""
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for i, p in enumerate(parts):
        g = 1.0 if gains is None else gains[i]
        out[: len(p)] += g * p
    return out


def fade(x: np.ndarray, fin_ms: float = 2.0, fout_ms: float = 8.0) -> np.ndarray:
    x = x.copy()
    a = min(len(x), int(fin_ms * SR / 1000))
    b = min(len(x), int(fout_ms * SR / 1000))
    if a > 1:
        x[:a] *= np.linspace(0, 1, a) ** 1.5
    if b > 1:
        x[-b:] *= np.linspace(1, 0, b) ** 1.5
    return x


def fade_out(x: np.ndarray, sec: float) -> np.ndarray:
    x = x.copy()
    n = min(len(x), n_of(sec))
    if n > 1:
        x[-n:] *= np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    return x


def fade_in(x: np.ndarray, sec: float) -> np.ndarray:
    x = x.copy()
    n = min(len(x), n_of(sec))
    if n > 1:
        x[:n] *= np.sin(np.linspace(0, np.pi / 2, n)) ** 2
    return x


def trim_silence(x: np.ndarray, thresh_db: float = -42.0, keep_ms: float = 15) -> np.ndarray:
    p = peak(x)
    if p == 0:
        return x
    idx = np.where(np.abs(x) > p * db(thresh_db))[0]
    if len(idx) == 0:
        return x
    k = int(keep_ms * SR / 1000)
    return x[max(0, idx[0] - k): idx[-1] + k]


def load_wav(path: str) -> np.ndarray:
    sr, d = wavfile.read(path)
    if d.ndim > 1:
        d = d.mean(axis=1)
    if d.dtype == np.int16:
        d = d.astype(np.float64) / 32768.0
    elif d.dtype == np.int32:
        d = d.astype(np.float64) / 2147483648.0
    elif d.dtype == np.uint8:
        d = (d.astype(np.float64) - 128) / 128.0
    else:
        d = d.astype(np.float64)
    if sr != SR:
        fr = Fraction(SR, sr).limit_denominator(1000)
        d = signal.resample_poly(d, fr.numerator, fr.denominator)
    return d


def read_any(path: str) -> np.ndarray:
    """Read a 16-bit WAV back as float, keeping the channel layout ((n,) or (n, 2))."""
    _sr, d = wavfile.read(path)
    return d.astype(np.float64) / 32768.0


def save_wav(path: str, x: np.ndarray, peak_db: float) -> None:
    """Normalise to peak_db and write 16-bit PCM (mono (n,) or stereo (n,2))."""
    p = peak(x)
    y = x * (db(peak_db) / p) if p > 1e-9 else x
    y = np.clip(y, -1.0, 1.0)
    wavfile.write(path, SR, np.round(y * 32767).astype(np.int16))


# ---------------------------------------------------------------- filters
def _sos(kind: str, fc, order: int = 4):
    return signal.butter(order, fc, btype=kind, fs=SR, output="sos")


def lp(x, fc, order=4):
    return signal.sosfilt(_sos("low", min(fc, SR * 0.49), order), x)


def hp(x, fc, order=4):
    return signal.sosfilt(_sos("high", fc, order), x)


def bp(x, lo, hi, order=3):
    hi = min(hi, SR * 0.49)
    return signal.sosfilt(_sos("band", [lo, hi], order), x)


def svf(x, fc, q=2.0, mode="band"):
    """Zavalishin TPT state-variable filter with per-sample cutoff (array or scalar).

    mode: low | band | high | notch.  q is resonance (0.5 = flat)."""
    n = len(x)
    fc = np.broadcast_to(np.asarray(fc, dtype=np.float64), (n,))
    qv = np.broadcast_to(np.asarray(q, dtype=np.float64), (n,))
    g = np.tan(np.pi * np.clip(fc, 10, SR * 0.45) / SR)
    k = 1.0 / qv
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    out = np.empty(n)
    ic1 = 0.0
    ic2 = 0.0
    xl = x.tolist()
    a1l, a2l, a3l, kl = a1.tolist(), a2.tolist(), a3.tolist(), k.tolist()
    for i in range(n):
        v3 = xl[i] - ic2
        v1 = a1l[i] * ic1 + a2l[i] * v3
        v2 = ic2 + a2l[i] * ic1 + a3l[i] * v3
        ic1 = 2.0 * v1 - ic1
        ic2 = 2.0 * v2 - ic2
        if mode == "low":
            out[i] = v2
        elif mode == "band":
            out[i] = v1 * kl[i]
        elif mode == "high":
            out[i] = xl[i] - kl[i] * v1 - v2
        else:
            out[i] = xl[i] - kl[i] * v1
    return out


# ---------------------------------------------------------------- noise
def white(n: int) -> np.ndarray:
    return _rng.standard_normal(n)


def pink(n: int) -> np.ndarray:
    return fft_noise(n, lambda f: 1.0 / np.sqrt(np.maximum(f, 20.0)))


def fft_noise(n: int, mag) -> np.ndarray:
    """Spectrally shaped noise of exactly n samples; periodic over n (loops with no seam)."""
    f = np.fft.rfftfreq(n, 1.0 / SR)
    m = mag(f) if callable(mag) else np.asarray(mag)
    ph = _rng.uniform(0, 2 * np.pi, len(f))
    spec = m * np.exp(1j * ph)
    spec[0] = 0
    x = np.fft.irfft(spec, n)
    s = np.std(x)
    return x / s if s > 0 else x


def slow_random(n: int, rate_hz: float, periodic: bool = True) -> np.ndarray:
    """Slowly wandering unit-ish signal (periodic over n when requested)."""
    if periodic:
        return fft_noise(n, lambda f: np.where((f > 0) & (f < rate_hz), 1.0, 0.0))
    return lp(white(n), rate_hz, 2) / (np.std(lp(white(n), rate_hz, 2)) + 1e-9)


# ---------------------------------------------------------------- pitch / time
def pitch(x: np.ndarray, semis: float) -> np.ndarray:
    """Pitch shift by resampling (speed and pitch change together; negative = lower + slower)."""
    ratio = 2.0 ** (-semis / 12.0)  # output length / input length
    fr = Fraction(ratio).limit_denominator(400)
    return signal.resample_poly(x, fr.numerator, fr.denominator)


def reverse(x):
    return x[::-1].copy()


def paulstretch(x: np.ndarray, stretch: float, win_s: float = 0.22) -> np.ndarray:
    ws = int(win_s * SR) // 2 * 2
    hop_out = ws // 2
    hop_in = hop_out / stretch
    window = (1 - np.linspace(-1, 1, ws) ** 2) ** 1.25
    n_frames = int((len(x) - ws) / hop_in) + 1
    if n_frames < 1:
        x = np.concatenate([x, np.zeros(ws)])
        n_frames = 1
    out = np.zeros(int(n_frames * hop_out + ws))
    for i in range(n_frames):
        a = int(i * hop_in)
        seg = x[a: a + ws]
        if len(seg) < ws:
            seg = np.concatenate([seg, np.zeros(ws - len(seg))])
        spec = np.abs(np.fft.rfft(seg * window))
        ph = _rng.uniform(0, 2 * np.pi, len(spec))
        fr = np.fft.irfft(spec * np.exp(1j * ph), ws) * window
        out[i * hop_out: i * hop_out + ws] += fr
    return out / (np.max(np.abs(out)) + 1e-9) * peak(x)


# ---------------------------------------------------------------- effects
def tremolo(x, rate, depth, phase=0.0):
    t = np.arange(len(x)) / SR
    return x * (1.0 - depth * (0.5 + 0.5 * np.sin(2 * np.pi * rate * t + phase)))


def saturate(x, drive=2.0):
    return np.tanh(x * drive) / np.tanh(drive)


def comb(x, delay_ms, fb=0.6, tail_s=0.0):
    d = max(2, int(delay_ms * SR / 1000))
    if tail_s:
        x = np.concatenate([x, np.zeros(n_of(tail_s))])
    a = np.zeros(d + 1)
    a[0] = 1.0
    a[d] = -fb
    return signal.lfilter([1.0], a, x)


def echo(x, delay_s, fb, lp_hz=3000, tail_s=2.0):
    """Feedback echo with damping in the loop (cheap tape-delay)."""
    d = n_of(delay_s)
    x = np.concatenate([x, np.zeros(n_of(tail_s))])
    out = x.copy()
    cur = x.copy()
    for _ in range(14):
        cur = lp(np.concatenate([np.zeros(d), cur[:-d]]), lp_hz, 1) * fb
        if peak(cur) < 1e-3 * (peak(x) + 1e-9):
            break
        out += cur
    return out


def formant_smear(x, formants, mix_wet=0.6):
    """Parallel narrow band-pass resonators; formants = [(freq, bandwidth, gain), ...]."""
    wet = np.zeros_like(x)
    for f, bw, g in formants:
        lo = max(30.0, f - bw / 2)
        hi = min(SR * 0.45, f + bw / 2)
        wet += g * signal.sosfilt(_sos("band", [lo, hi], 2), x)
    s = rms(wet)
    if s > 0:
        wet *= rms(x) / s
    return (1 - mix_wet) * x + mix_wet * wet


CHOIR_FORMANTS = [(650, 120, 1.0), (1080, 140, 0.8), (2650, 260, 0.5), (3300, 300, 0.3)]
HOLLOW_FORMANTS = [(320, 70, 1.0), (760, 110, 0.7), (2300, 300, 0.4)]
OO_FORMANTS = [(300, 60, 1.0), (870, 100, 0.55), (2240, 250, 0.25)]


def ring_mod(x, freq, mix_wet=0.5):
    t = np.arange(len(x)) / SR
    return (1 - mix_wet) * x + mix_wet * x * np.sin(2 * np.pi * freq * t)


def bitcrush(x, bits=6, hold=3):
    q = 2 ** bits
    y = np.round(x * q / 2) / (q / 2)
    if hold > 1:
        y = np.repeat(y[::hold], hold)[: len(x)]
    return y


def vocoder(mod, carrier, nb=22, lo=110.0, hi=7600.0, env_hz=45.0, hf_boost=1.0):
    """Channel vocoder: speech envelope (mod) imposed on carrier. Output length = len(mod)."""
    n = len(mod)
    carrier = pad_to(carrier, n)
    edges = np.geomspace(lo, hi, nb + 1)
    env_sos = _sos("low", env_hz, 2)
    out = np.zeros(n)
    for i in range(nb):
        sos = _sos("band", [edges[i], edges[i + 1]], 2)
        m = signal.sosfilt(sos, mod)
        c = signal.sosfilt(sos, carrier)
        env = signal.sosfilt(env_sos, np.abs(m))
        env = np.maximum(env, 0)
        gain = hf_boost ** (i / max(1, nb - 1))
        out += c * env * gain
    return out


# ---------------------------------------------------------------- reverb
_ir_cache: dict = {}


def cathedral_ir(rt60=3.2, predelay_ms=22, damp=1.0, seed_=0, early=True) -> np.ndarray:
    """Synthetic stone-hall impulse response: exponential noise tail, low band lingers, highs die faster."""
    key = (round(rt60, 2), predelay_ms, damp, seed_, early)
    if key in _ir_cache:
        return _ir_cache[key]
    r = np.random.default_rng(1000 + seed_)
    n = n_of(rt60 * 1.15)
    t = np.arange(n) / SR
    noise = r.standard_normal(n)
    bands = [(25, 450, 1.35), (450, 3500, 1.0), (3500, 15000, 0.42 / damp)]
    ir = np.zeros(n)
    for lo, hi, k in bands:
        b = signal.sosfilt(_sos("band", [lo, hi], 2), noise)
        b = b / (np.std(b) + 1e-9)
        ir += b * np.exp(-6.9078 * t / (rt60 * k))
    # soft onset so there is no click, then add a few early reflections (stone walls)
    att = n_of(0.012)
    ir[:att] *= np.linspace(0, 1, att)
    if early:
        for d, g in [(0.011, 0.9), (0.023, 0.7), (0.037, 0.6), (0.052, 0.5), (0.071, 0.45)]:
            i = n_of(d + r.uniform(-0.002, 0.002))
            if i < n:
                ir[i] += g * 5.0 * r.choice([-1, 1])
    pre = np.zeros(n_of(predelay_ms / 1000.0))
    ir = np.concatenate([pre, ir])
    ir /= np.sqrt(np.sum(ir ** 2))
    _ir_cache[key] = ir
    return ir


def reverb(x, ir, wet=0.5, dry=1.0, keep_tail=True):
    y = signal.fftconvolve(x, ir)
    n = len(y) if keep_tail else len(x)
    out = np.zeros(n)
    out[: len(x)] += dry * x
    out += wet * y[:n]
    return out


def circ_reverb(x, ir, wet=0.5, dry=1.0):
    """Reverb whose tail wraps around to the start: keeps loops seamless."""
    n = len(x)
    y = signal.fftconvolve(x, ir)
    out = dry * x.copy()
    for k in range(0, len(y), n):
        seg = y[k: k + n]
        out[: len(seg)] += wet * seg
    return out


# ---------------------------------------------------------------- synthesis
def phase_from_freq(f):
    return 2 * np.pi * np.cumsum(f) / SR


def harm(f, n_harm=24, tilt=1.0, odd_only=False, max_hz=9000.0):
    """Additive harmonic tone. f = scalar or per-sample array (Hz). tilt: amplitude ~ 1/k^tilt."""
    f = np.asarray(f, dtype=np.float64)
    ph = phase_from_freq(f)
    fmax = float(np.max(f))
    out = np.zeros(len(f))
    for k in range(1, n_harm + 1):
        if odd_only and k % 2 == 0:
            continue
        if k * fmax > max_hz:
            break
        out += np.sin(k * ph) / (k ** tilt)
    return out


def sine(f, n=None):
    if np.isscalar(f):
        t = np.arange(n) / SR
        return np.sin(2 * np.pi * f * t)
    return np.sin(phase_from_freq(f))


def glide(f0, f1, n, curve="exp"):
    if curve == "exp":
        return f0 * (f1 / f0) ** np.linspace(0, 1, n)
    return np.linspace(f0, f1, n)


def exp_env(n, tau_s):
    return np.exp(-np.arange(n) / (tau_s * SR))


def ar_env(n, a_s, r_s=None, shape=1.0):
    """Attack/release (sine) envelope: rise over a_s, fall over the rest (or r_s)."""
    a = max(1, min(n - 1, n_of(a_s)))
    r = n - a if r_s is None else max(1, min(n - a, n_of(r_s)))
    env = np.zeros(n)
    env[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** shape
    env[a: a + r] = np.cos(np.linspace(0, np.pi / 2, r)) ** shape
    return env


def bell_env(n, centre=0.5, width=0.25):
    x = np.linspace(0, 1, n)
    return np.exp(-0.5 * ((x - centre) / width) ** 2)


def thump(f0, f1, dur, tau, drive=1.0):
    n = n_of(dur)
    f = glide(f0, f1, n)
    y = np.sin(phase_from_freq(f)) * exp_env(n, tau)
    if drive != 1.0:
        y = saturate(y, drive)
    return fade(y, 1.0, 5.0)


BAR = [1.0, 2.756, 5.404, 8.933, 13.34, 18.64]
BELL = [0.56, 0.92, 1.19, 1.71, 2.0, 2.74, 3.0, 3.76, 4.07]
PLATE = [1.0, 1.59, 2.14, 2.30, 2.65, 2.92, 3.50, 4.06]


def modal(freqs, amps, taus, dur, phases=None):
    n = n_of(dur)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for i, (f, a, d) in enumerate(zip(freqs, amps, taus)):
        if f >= SR * 0.47:
            continue
        ph = 0.0 if phases is None else phases[i]
        out += a * np.exp(-t / d) * np.sin(2 * np.pi * f * t + ph)
    att = max(2, int(0.0004 * SR))
    out[:att] *= np.linspace(0, 1, att)
    fo = min(n // 4, int(0.02 * SR))  # smooth end: no click when a slow ring is cut short
    if fo > 1:
        out[-fo:] *= np.linspace(1, 0, fo)
    return out


def metal(f0, dur=0.6, tau=0.25, ratios=BAR, brightness=0.8, detune=0.0):
    r = _rng
    freqs = [f0 * k * (1 + detune * r.uniform(-1, 1)) for k in ratios]
    amps = [brightness ** i * r.uniform(0.7, 1.0) for i in range(len(ratios))]
    taus = [tau / (k ** 0.7) for k in ratios]
    return modal(freqs, amps, taus, dur)


def noise_burst(dur, tau, lo=None, hi=None, order=3):
    n = n_of(dur)
    x = white(n)
    if lo and hi:
        x = bp(x, lo, hi, order)
    elif hi:
        x = lp(x, hi, order)
    elif lo:
        x = hp(x, lo, order)
    return fade(x * exp_env(n, tau), 0.5, 3.0)


class Canvas:
    """Timeline buffer: add(x, t_sec, gain) mixes x at time t (growing or clipped to fixed length)."""

    def __init__(self, dur=None, wrap=False):
        self.wrap = wrap
        self.buf = np.zeros(n_of(dur) if dur else 0)
        self.fixed = dur is not None

    def add(self, x, t=0.0, g=1.0):
        i = n_of(t)
        if self.wrap:
            n = len(self.buf)
            idx = (np.arange(len(x)) + i) % n
            np.add.at(self.buf, idx, g * x)
            return self
        if i < 0:
            x = x[-i:]
            i = 0
        end = i + len(x)
        if end > len(self.buf):
            if self.fixed:
                x = x[: len(self.buf) - i]
                end = len(self.buf)
            else:
                self.buf = np.concatenate([self.buf, np.zeros(end - len(self.buf))])
        if len(x) > 0:
            self.buf[i: i + len(x)] += g * x
        return self


def bank_clinks(count=24, lo=1800, hi=5500, tau=(0.006, 0.02), dur=0.09):
    """A bank of tiny metal 'clink' hits (chain links, rivets)."""
    r = _rng
    out = []
    for _ in range(count):
        f = r.uniform(lo, hi)
        ratios = [1.0, r.uniform(2.1, 2.6), r.uniform(3.4, 4.2)]
        tau0 = r.uniform(*tau)
        out.append(modal([f * k for k in ratios], [1.0, 0.55, 0.3], [tau0, tau0 * 0.6, tau0 * 0.4], dur))
    return out


def bank_stone(count=24, lo=180, hi=1900, tau=(0.012, 0.06), dur=0.14):
    """Bank of stone 'clack' hits: noisy transient + low inharmonic ring."""
    r = _rng
    out = []
    for _ in range(count):
        f = r.uniform(lo, hi)
        ratios = [1.0, r.uniform(1.4, 1.9), r.uniform(2.3, 3.4)]
        tau0 = r.uniform(*tau)
        m = modal([f * k for k in ratios], [1.0, 0.6, 0.35], [tau0, tau0 * 0.7, tau0 * 0.5], dur)
        nz = bp(white(n_of(dur)), f * 0.6, f * 3.5, 2) * exp_env(n_of(dur), 0.004) * 0.9
        out.append(m + nz)
    return out


def scatter(canvas: Canvas, times, bank, gains=None, gain=1.0, pitch_var=0.0):
    r = _rng
    for i, t in enumerate(times):
        h = bank[r.integers(len(bank))]
        if pitch_var:
            h = pitch(h, r.uniform(-pitch_var, pitch_var))
        g = (gains[i] if gains is not None else r.uniform(0.35, 1.0)) * gain
        canvas.add(h, t, g)


def poisson_times(t0, t1, rate_fn, max_rate):
    """Inhomogeneous Poisson event times by thinning. rate_fn(t) in events/s."""
    r = _rng
    t = t0
    out = []
    while True:
        t += r.exponential(1.0 / max_rate)
        if t >= t1:
            break
        if r.uniform() < rate_fn(t) / max_rate:
            out.append(t)
    return out


# ---------------------------------------------------------------- analysis
def analyse(x: np.ndarray) -> dict:
    """Peak dBFS, RMS dBFS, duration, longest run at full scale, spectral centroid."""
    mono = x if x.ndim == 1 else x.mean(axis=1)
    p = np.max(np.abs(x))
    full = np.abs(x.reshape(len(x), -1)).max(axis=1) >= 0.999
    run = best = 0
    for v in full:
        run = run + 1 if v else 0
        best = max(best, run)
    spec = np.abs(np.fft.rfft(mono * np.hanning(len(mono))))
    f = np.fft.rfftfreq(len(mono), 1 / SR)
    cen = float((spec * f).sum() / (spec.sum() + 1e-12))
    # energy per band to prove the spectrum is not empty
    def band(lo, hi):
        m = (f >= lo) & (f < hi)
        return float(np.sum(spec[m] ** 2))
    tot = band(0, SR / 2) + 1e-18
    return {
        "dur": len(x) / SR,
        "peak_db": 20 * np.log10(p + 1e-12),
        "rms_db": 20 * np.log10(rms(mono) + 1e-12),
        "clip_run": best,
        "centroid": cen,
        "lo": band(0, 200) / tot,
        "mid": band(200, 3000) / tot,
        "hi": band(3000, SR / 2) / tot,
    }
