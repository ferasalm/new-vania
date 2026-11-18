# Shift and world sounds: sources and method

Everything in `sfx/shift/` and `sfx/world/` is made by `tools/make_shift_audio.py`
(helpers `tools/make_shift_audio_*.py`). No external sample was used and no licence applies.
Raw voices are Windows SAPI text-to-speech (Microsoft David and Zira) speaking invented pseudo-Latin
lines (not prayers or scripture). The voices are only raw material: they are processed until they are not human.

**Nothing was listened to.** Checks were numeric (peak, RMS, clipping runs, loop-seam jump) and
visual (spectrograms). Re-pick levels and details by ear at playtest.
Rebuild: `python tools/make_shift_audio.py` (all) or `python tools/make_shift_audio.py lever shift_tear` (some).
Every file is deterministic (fixed seeds). WAV, 44100 Hz, 16-bit, mono (drone_loop is stereo).
One-shots peak at -1 dBFS, loops at -6 dBFS: set the playback volumes in the game, not in the files.

## Voice chain ("inhuman")
Pitch down by resampling (5-12 semitones), octave-down copy, reversed copy, slow tremolo, choir or
hollow formant smear (parallel band-pass resonators), optional comb filter / ring-mod / feedback echo,
tanh saturation, convolution with a synthetic cathedral impulse response (exponential noise tail, 2.4-4.2 s,
low band lingers and highs die first), and a low detuned drone underneath. Each incantation uses its own mix.
Choirs use a channel vocoder (speech envelope imposed on detuned saw chords) and Paul-stretch.
Whispers use a noise vocoder (speech envelope on white noise).

## shift/
| File | Length | What it is |
|---|---|---|
| `shift_tear.wav` | 5.8 s | Reverse swell (reversed ghost voice, rising noise sweep, rising dark chord, sub) -> 30 ms vacuum -> huge low impact (95->30 Hz sine, body, crash, rumble, low metal boom; reverb only above 140 Hz) -> vocoded choir on a dark chord (A, C, Eb, A, Bb, E) -> glass/metal shriek (distorted gliding saw, inharmonic plate partials, 40+ glass pings) -> low murmur and drone in the tail |
| `incant_01.wav` | 7.0 s | David, "tempus frangitur, memoria cadit in tenebras", -8 st, octave-down, reversed trailing copy, drone 41 Hz |
| `incant_02.wav` | 7.0 s | Zira, "porta aperitur, veni", vocoded into a robotic choir (D minor-major cluster) plus her own ghost, drone 36.7 Hz |
| `incant_03.wav` | 7.0 s | David, "nomen tuum non est tuum", -6 st, hollow formants, comb, ring-mod growl, long echo, drone 46 Hz |
| `incant_04.wav` | 7.0 s | Zira, "umbra surgit, sanguis tacet", two voices (-10 st harsh growl, -4 st ghost), "oo" mouth, heavy saturation |
| `incant_05.wav` | 7.0 s | David, "horologium moritur": reverse-reverb swell so the words arrive out of their own reverb, then ring out |
| `incant_06.wav` | 7.0 s | Crowd chant: five pitched copies (-5 to -14 st) from both voices, staggered, 4.2 s reverb |
| `whisper_01..05.wav` | 2.1-3.0 s | Noise-vocoded close whispers: "veni" echoing away; "non est tuum" with reversed ghost + comb; "tacete" with fast flutter; "audi nomen tuum" pitched up a little; "sub umbra" low and breathy. Every incantation also carries a quiet whispered double of its own line for air |
| `drone_loop.wav` | 36 s | Stereo, seamless: four detuned drone pairs (36.7, 55, 58.3, 73.4 Hz, beating 0.25-0.42 Hz) with soft saturation, dark air noise, five distant metallic FM groans, four faint stretched-and-vocoded chant swells, two low murmurs. Frequencies are snapped to whole cycles and events wrap around the end, so no crossfade is needed |
| `dead_terminal.wav` | 1.25 s | Electrical crackle + stuttering mains buzz, three failing square beeps (dropping, last one bit-crushed and gated), power-down whine sliding 1500 -> 42 Hz, last pop |
| `machine_hum.wav` | 7.0 s | Seamless: 55/110 Hz hum with beating pairs, faint 100 Hz transformer buzz, tick-tock clockwork at 2 per second plus fine ratchet, faint organ pipes (110, 165 and a flat ninth) with breath |
| `machine_activate.wav` | 3.0 s | Ticks accelerating 3 -> 70 per second into a whirr, rising whine, organ chord sliding up into place, soft low "lock" thunk at 2.05 s. Plays right before `shift_tear` |

## world/
Modal synthesis (damped inharmonic partials for iron, bell and stone), filtered noise, and Poisson-timed hit showers
for chains and rubble. `lever` (ratchet clicks, clunk, chain), `bars_open` (stick-slip grind, squeal, chain, stop bang),
`wall_crack` (blow, crack, fissure crackle, dust), `wall_crumble` (rumble, rubble cascade, big blocks, sand),
`locked` (two rattles and a dull refusal), `blade_swing` (doppler whoosh, air thud, blade ring), `crusher_warn`
(rising chain rattle, dust grains, creak), `crusher_slam` (sub thump, crash, iron ring, rubble, short reverb),
`vent_hiss`, `vent_flame` (ignition whump, roar, crackle), `spikes` (shing, stop rattle, thud),
`crab_click`, `crab_spines` (rattle then four thwips), `crab_burrow` (gravel scrape closing to a muffle),
`crab_tink` (bright metal ring with a dull shell thud), `moth_flutter` (14 flaps per second, periodic noise, seamless 1 s loop),
`moth_gust` (two heavy wingbeats and wind), `censer_chime` (chain jingle and three dissonant bells), `scribe_scratch`
(five quill strokes and a charging shimmer), `scribe_needle` (thin gliding whistle), `glyph_burst` (air sucked in, burst, shimmer, pings),
`ink_drip` (stretching thread, thick drop, small drop), `leech_squelch` (suction, bubbles, pop), `leech_drop` (thread snap, wet whoosh, splat).
