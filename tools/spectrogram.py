#!/usr/bin/env python3
"""Renders a log-frequency spectrogram of a Godot movie-maker WAV to PNG,
so the mix can be checked visually without speakers."""
import sys, wave
import numpy as np
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
w = wave.open(src)
n, sr, sw = w.getnframes(), w.getframerate(), w.getsampwidth()
dt = {2: np.int16, 4: np.int32}[sw]
a = np.frombuffer(w.readframes(n), dtype=dt).astype(np.float64)
a = a.reshape(-1, w.getnchannels()).mean(1) / 2 ** (8 * sw - 1)
win, hop = 4096, 512
frames = np.array([a[i:i + win] * np.hanning(win) for i in range(0, len(a) - win, hop)])
S = np.abs(np.fft.rfft(frames, axis=1)).T
S = 20 * np.log10(S + 1e-9)
S = np.clip((S - S.max() + 60) / 60, 0, 1)
freqs = np.arange(S.shape[0]) * sr / win
H = 360
ys = np.geomspace(50, 6000, H)
img = np.array([S[min(np.searchsorted(freqs, f), S.shape[0] - 1)] for f in ys])[::-1]
Image.fromarray((img * 255).astype(np.uint8)).resize((1200, H)).save(dst)
