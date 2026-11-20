#!/usr/bin/env python3
"""Regenerate the four original mono click samples."""
import math
from pathlib import Path
import random
import struct
import wave

RATE = 32_000
OUTPUT = Path(__file__).resolve().parents[1] / "Pokelet" / "Resources"
noise = random.Random(104)


def tone(hz, t):
    return math.sin(math.tau * hz * t)


def envelope(t, attack, decay):
    return min(t / attack, 1) * math.exp(-t / decay)


def tap(t):
    return envelope(t, 0.0015, 0.016) * (0.47 * tone(420, t) + 0.14 * noise.uniform(-1, 1))


def pop(t):
    sweep = 260 * t + 630 * 0.013 * (1 - math.exp(-t / 0.013))
    return 0.62 * envelope(t, 0.003, 0.028) * math.sin(math.tau * sweep)


def wood(t):
    return envelope(t, 0.0009, 0.020) * (0.34 * tone(790, t) + 0.29 * tone(1195, t) + 0.12 * tone(1811, t))


def squeak(t):
    sweep = 540 * t + 350 * t * t / 0.12 + 0.29 * math.sin(math.tau * 7 * t)
    return envelope(t, 0.009, 0.060) * (0.38 * math.sin(math.tau * sweep) + 0.09 * math.sin(2 * math.tau * sweep))


for synth, duration in [(tap, 0.09), (pop, 0.13), (wood, 0.10), (squeak, 0.22)]:
    frames = int(RATE * duration)
    pcm = bytearray()
    for index in range(frames):
        end_fade = min(1, (frames - index - 1) / 320)
        pcm.extend(struct.pack("<h", int(32_767 * end_fade * synth(index / RATE))))
    with wave.open(str(OUTPUT / f"{synth.__name__}.wav"), "wb") as sample:
        sample.setparams((1, 2, RATE, frames, "NONE", "not compressed"))
        sample.writeframes(pcm)
