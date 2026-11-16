#!/usr/bin/env python3
"""Sintesis audio prosedural THE GIANT (numpy, 16-bit mono 22050 Hz).

Regenerasi: wind.wav, footstep.wav, heartbeat.wav.
Baru: giant_thud.wav — dentuman langkah Giant yang DEDIKASI, bukan lagi
footstep yang dipelankan pitch-nya (pitch 0.45 di audio.gd dulu).
Tidak disentuh: generator_hum, radio_static, door_creak (sudah cukup).

Jalankan dari root proyek:  python3 tools/synth_audio.py
Output: assets/audio/*.wav (langsung ditimpa, lalu Godot re-import).
Semua suara tetap disintesis dari kode, tanpa aset berlisensi.
Batas jujur: audio belum pernah didengar telinga manusia (sandbox tanpa
sound card); yang diverifikasi adalah bentuk gelombang + jalur play di
test rig mode=audio, bukan bunyinya.
"""
import os
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


def save(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    import wave
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"{name}: {len(samples)/SR:.2f}s peak={np.abs(samples).max():.2f} rms={np.sqrt((samples**2).mean()):.3f}")


def lowpass(x, alpha):
    """One-pole lowpass, alpha kecil = makin gelap."""
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def make_loopable(x, fade=0.5):
    """Crossfade ujung ke awal supaya loop tidak berdetak."""
    n = int(fade * SR)
    ramp = np.linspace(0, 1, n)
    x[-n:] = x[-n:] * (1 - ramp) + x[:n] * ramp
    return x


def wind():
    rng = np.random.default_rng(7)
    t = np.arange(4.0 * SR) / SR
    # Brown noise (diintegrasi) = angin dalam; + hembusan pelan 0.07 Hz.
    noise = rng.standard_normal(len(t))
    brown = np.cumsum(noise)
    brown /= np.abs(brown).max()
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * 0.07 * t + 0.8)
    gust += 0.18 * np.sin(2 * np.pi * 0.23 * t)
    x = lowpass(brown, 0.02) * gust
    # Desis daun samar di atasnya.
    x += lowpass(noise, 0.004) * 0.25 * gust
    x = make_loopable(x / np.abs(x).max() * 0.7)
    save("wind.wav", x)


def footstep():
    rng = np.random.default_rng(11)
    t = np.arange(0.25 * SR) / SR
    # Debuk tanah: noise lowpass + sine 85 Hz, decay cepat.
    noise = lowpass(rng.standard_normal(len(t)), 0.08)
    thump = np.sin(2 * np.pi * 85 * t) * np.exp(-t * 28)
    x = noise * np.exp(-t * 22) * 0.8 + thump * 0.7
    save("footstep.wav", x)


def heartbeat():
    t = np.arange(1.2 * SR) / SR
    x = np.zeros_like(t)
    for start, amp, dur in [(0.0, 1.0, 0.14), (0.38, 0.7, 0.11)]:
        m = (t >= start) & (t < start + dur)
        tt = t[m] - start
        x[m] += amp * np.sin(2 * np.pi * 55 * tt) * np.exp(-tt * 22)
    save("heartbeat.wav", x)


def giant_thud():
    """Dentuman Giant: DEDIKASI, bukan footstep dipelankan.
    Sub sine 75->34 Hz (0.5 detik) + gemuruh noise lowpass berat +
    dentuman kedua tertunda 0.45 detik (langkah kaki kedua). Total 1.4 dtk."""
    rng = np.random.default_rng(23)
    dur = 1.4
    t = np.arange(dur * SR) / SR
    # Sweep frekuensi turun: f(t) = 75 * (34/75)^(t/0.5) untuk t<0.5.
    phase = np.zeros_like(t)
    f = np.where(t < 0.5, 75.0 * (34.0 / 75.0) ** (t / 0.5), 34.0)
    phase[1:] = np.cumsum(f[1:]) / SR * 2 * np.pi
    sub = np.sin(phase) * np.exp(-t * 3.2)
    # Gemuruh: noise sangat lowpass, decay 0.9 dtk.
    rumble = lowpass(rng.standard_normal(len(t)), 0.012) * np.exp(-t * 4.5) * 1.4
    # Dentuman kedua (kaki satunya menapak), lebih pelan.
    t2 = np.clip(t - 0.45, 0, None)
    sub2 = np.sin(2 * np.pi * 42 * t2) * np.exp(-t2 * 5.0) * (t >= 0.45) * 0.55
    x = sub * 0.9 + rumble + sub2
    save("giant_thud.wav", x)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    wind()
    footstep()
    heartbeat()
    giant_thud()
