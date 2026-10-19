#!/usr/bin/env python3
"""Band energy of captures written by tools/audio_probe.gd --dump=DIR.

    python3 -I tools/analysis/spectrum.py DIR [mix_rate]

Prints, per capture, RMS (dBFS) and the share of energy below 120 Hz
(inaudible on most laptop/phone speakers), 120-300 Hz, 300 Hz-4 kHz and above.
"""
import sys, pathlib
import numpy as np

d = pathlib.Path(sys.argv[1])
rate = float(sys.argv[2]) if len(sys.argv) > 2 else 44100.0
for p in sorted(d.glob("*.f32")):
    x = np.fromfile(p, dtype="<f4").astype(float)
    if x.size == 0:
        continue
    rms = np.sqrt((x ** 2).mean())
    X = np.abs(np.fft.rfft(x * np.hanning(x.size))) ** 2
    f = np.fft.rfftfreq(x.size, 1 / rate)
    tot = X.sum() or 1.0
    bands = [(0, 120), (120, 300), (300, 4000), (4000, rate / 2)]
    parts = ["%s %4.0f%%" % ("<120" if a == 0 else ">4k" if a == 4000 else f"{a}-{b}", 100 * X[(f >= a) & (f < b)].sum() / tot) for a, b in bands]
    print("%-28s rms %6.1f dBFS | %s" % (p.stem, 20 * np.log10(rms) if rms > 0 else -np.inf, " | ".join(parts)))
