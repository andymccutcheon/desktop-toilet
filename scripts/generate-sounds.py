#!/usr/bin/env python3
"""Synthesize original, license-free WAV effects for Desktop Toilet.

The plop and flush are generated from sine waves, exponential envelopes,
and filtered noise. No third-party samples. Public domain / CC0.
"""

from __future__ import annotations

import math
import os
import random
import struct
import wave

SR = 44100


def write_wav(path: str, samples: list[float]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(sample * 32767))))
            for sample in samples
        )
        handle.writeframes(frames)


def plop() -> list[float]:
    length = int(SR * 0.28)
    out: list[float] = []
    for i in range(length):
        t = i / SR
        envelope = math.exp(-t * 14)
        sample = 0.55 * math.sin(2 * math.pi * (170 - 80 * t) * t)
        sample += 0.25 * math.sin(2 * math.pi * 520 * t) * math.exp(-t * 22)
        sample += 0.12 * (random.random() * 2 - 1) * math.exp(-t * 30)
        out.append(sample * envelope)
    return out


def flush() -> list[float]:
    length = int(SR * 1.65)
    out = [0.0] * length

    for i in range(int(0.06 * SR)):
        t = i / SR
        out[i] += 0.4 * math.sin(2 * math.pi * 70 * t) * math.exp(-t * 40)
        out[i] += 0.15 * (random.random() * 2 - 1) * math.exp(-t * 80)

    random.seed(3)
    lowpass = 0.0
    for i in range(length):
        t = i / SR
        noise = random.random() * 2 - 1
        cutoff = 0.25 - 0.18 * (t / 1.65)
        lowpass += cutoff * (noise - lowpass)
        if t < 0.08:
            amp = t / 0.08
        elif t < 1.1:
            amp = 1.0
        else:
            amp = max(0.0, 1.0 - (t - 1.1) / 0.55)
        throb = 0.75 + 0.25 * math.sin(2 * math.pi * (6 + 10 * t) * t)
        out[i] += lowpass * 0.85 * amp * throb
        out[i] += 0.18 * amp * math.sin(2 * math.pi * (90 - 40 * t) * t)

    bubbles = random.Random(11)
    for _ in range(14):
        start = bubbles.uniform(0.15, 1.2)
        freq = bubbles.uniform(400, 1400)
        duration = bubbles.uniform(0.03, 0.09)
        for i in range(int(duration * SR)):
            index = int(start * SR) + i
            if index >= length:
                break
            tt = i / SR
            out[index] += 0.12 * math.sin(2 * math.pi * freq * tt) * math.exp(-tt * 40)

    peak = max(0.001, max(abs(sample) for sample in out))
    return [sample / peak * 0.9 for sample in out]


def main() -> None:
    root = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "Resources", "Sounds")
    )
    write_wav(os.path.join(root, "plop.wav"), plop())
    write_wav(os.path.join(root, "flush.wav"), flush())
    print(f"wrote {root}")


if __name__ == "__main__":
    main()
