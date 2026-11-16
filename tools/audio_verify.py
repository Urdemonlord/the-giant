#!/usr/bin/env python3
"""Verifikasi audio THE GIANT (bukti bentuk gelombang + spektrum).

Jalankan dari root proyek:  python3 tools/audio_verify.py
Cek tiap WAV di assets/audio/:
  - format: PCM 16-bit mono 22050 Hz (format proyek),
  - durasi > 0, peak < 1.0 (tidak clipping), RMS > 0.01 (tidak sunyi),
  - spektrum: centroid + porsi energi <300 / 300-3000 / >3000 Hz,
  - klip suara radio: mayoritas energi di pita radio 300-3000 Hz.
Keluar 0 kalau semua cek lolos, 1 kalau ada yang gagal.
Ini BUKAN bukti bunyi (sandbox tanpa sound card); bunyi dibuktikan
jalur play-nya di test rig mode=audio.
"""
import os
import subprocess
import sys
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "assets", "audio")

EXPECTED = ["wind.wav", "generator_hum.wav", "radio_static.wav",
            "door_creak.wav", "footstep.wav", "heartbeat.wav",
            "giant_thud.wav", "crickets.wav", "radio_voice_1.wav",
            "radio_voice_2.wav", "radio_voice_3.wav", "radio_voice_4.wav",
            "radio_voice_5.wav"]


def spectrum(x, sr):
    X = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    f = np.fft.rfftfreq(len(x), 1 / sr)

    def band(a, b):
        m = (f >= a) & (f < b)
        return float(X[m].sum() / X.sum())

    cent = float((f * X).sum() / X.sum())
    return cent, band(0, 300), band(300, 3000), band(3000, 99999)


def main():
    fails = 0
    print(f"{'file':<20} {'dur':>6} {'peak':>5} {'rms':>6} {'centr':>6} "
          f"{'<300':>5} {'300-3k':>6} {'>3k':>5}")
    for name in EXPECTED:
        path = os.path.join(AUDIO, name)
        if not os.path.exists(path):
            print(f"{name:<20} HILANG")
            fails += 1
            continue
        with wave.open(path) as w:
            n, sr, ch, sw = w.getnframes(), w.getframerate(), \
                w.getnchannels(), w.getsampwidth()
            x = np.frombuffer(w.readframes(n), dtype=np.int16) \
                .astype(float) / 32768
        peak = float(np.abs(x).max())
        rms = float(np.sqrt((x ** 2).mean()))
        cent, lo, mid, hi = spectrum(x, sr)
        size = os.path.getsize(path)
        ok = (sr, ch, sw) == (22050, 1, 2) and len(x) > 0 \
            and peak < 1.0 and rms > 0.01
        if name.startswith("radio_voice") and mid < 0.6:
            ok = False
        if not ok:
            fails += 1
        print(f"{name:<20} {len(x)/sr:5.2f}s {peak:5.2f} {rms:6.3f} "
              f"{cent:6.0f} {lo:5.2f} {mid:6.2f} {hi:5.2f} "
              f"{size} byte {'OK' if ok else 'FAIL'}")
    # File tak dikenal di folder audio ikut dilaporkan (bukan gagal).
    extra = sorted(set(os.listdir(AUDIO)) - set(EXPECTED)
                   - {n + ".import" for n in EXPECTED})
    for name in extra:
        if name.endswith(".wav"):
            print(f"{name:<20} file WAV tak dikenal (tidak dicek)")
    print("HASIL: " + ("PASS semua cek" if fails == 0
                       else f"FAIL ({fails} cek gagal)"))
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
