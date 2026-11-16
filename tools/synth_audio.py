#!/usr/bin/env python3
"""Sintesis audio prosedural THE GIANT (numpy, 16-bit mono 22050 Hz).

Regenerasi: wind.wav, footstep.wav, heartbeat.wav, giant_thud.wav,
door_creak.wav (baru di v8-suara: dulu door_creak.wav dibuat entah di
mana, isinya didominasi noise di atas 3 kHz, centroid 3561 Hz, tanpa
nada derit kayu sama sekali), crickets.wav (v14: jangkrik malam).
Suara radio (radio_voice_1..5.wav) TIDAK dari sini, tapi dari gTTS,
lihat tools/make_radio_voice.py.

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


def normalize_peak(x, peak=0.85):
    """Skala ke peak target supaya tidak clipping (thud lama peak 0.99)."""
    m = np.abs(x).max()
    return x / m * peak if m > 0 else x


def footstep():
    """v2: dulu satu debuk 0,25 dtk, centroid 2407 Hz, 29% energi di
    atas 3 kHz (terdengar desis, bukan tanah). Sekarang 0,35 dtk:
    hentak tumit (sine 75 Hz) + krek tanah/daun kering (noise band
    ~0,5-2,5 kHz, puncak 0,03-0,08 dtk) + ekor geser pelan.
    Variasi antar langkah ditangani audio.gd (pitch acak 0.92-1.08)."""
    rng = np.random.default_rng(11)
    t = np.arange(0.35 * SR) / SR
    # Hentak tumit: noise lowpass + sine 75 Hz, decay cepat.
    noise = lowpass(rng.standard_normal(len(t)), 0.08)
    thump = np.sin(2 * np.pi * 75 * t) * np.exp(-t * 30)
    x = noise * np.exp(-t * 25) * 0.7 + thump * 0.8
    # Krek tanah/daun: noise band (~0,5-2,5 kHz). Draf pertama terlalu
    # panas (centroid 3529 Hz, 44% energi >3 kHz): band dibatasi
    # lowpass kedua + gain diturunkan supaya hentak tetap dominan.
    raw = rng.standard_normal(len(t))
    crunch = lowpass(raw, 0.12) - lowpass(raw, 0.05)
    crunch = lowpass(crunch, 0.15)
    crunch *= np.exp(-((t - 0.05) ** 2) / (2 * 0.035 ** 2))
    x += crunch * 0.9
    # Ekor geser: noise sangat lowpass, decay pelan.
    x += lowpass(rng.standard_normal(len(t)), 0.03) * np.exp(-t * 12) * 0.25
    save("footstep.wav", normalize_peak(x))


def heartbeat():
    """v2: dulu dua sine 55 Hz murni. Sekarang lub-dub dengan harmonik
    (58 + 116 Hz), ketuk katup singkat di awal tiap detak, dan badan
    sub 38 Hz; detak pertama lebih kuat dari kedua."""
    t = np.arange(1.2 * SR) / SR
    x = np.zeros_like(t)
    rng = np.random.default_rng(5)
    for start, amp in [(0.0, 1.0), (0.36, 0.65)]:
        m = (t >= start) & (t < start + 0.45)
        tt = t[m] - start
        # Ketuk katup: noise singkat yang mulai di tiap detak (bukan
        # sekali di t=0 saja, itu bug draf pertama: detak kedua sunyi).
        # Draf pertama juga terlalu berdesis (centroid 1879 Hz): klik
        # di-lowpass + gain kecil supaya jadi ketuk tumpul, bukan desis.
        click = lowpass(rng.standard_normal(m.sum()), 0.10) * np.exp(-tt * 200)
        x[m] += amp * (np.sin(2 * np.pi * 58 * tt) * np.exp(-tt * 18)
                       + 0.4 * np.sin(2 * np.pi * 116 * tt) * np.exp(-tt * 22)
                       + 0.5 * np.sin(2 * np.pi * 38 * tt) * np.exp(-tt * 10))
        x[m] += amp * 0.06 * click
    save("heartbeat.wav", normalize_peak(x))


def door_creak():
    """BARU (v8-suara): file lama didominasi noise broadband (centroid
    3561 Hz, 46% energi >3 kHz), tidak ada nada derit. Yang ini derit
    kayu stick-slip beneran: nada dasar menyapu 340->540->360 Hz
    (vibrato 6 Hz + jitter) dengan harmonik 2x/3x, modulasi amplitudo
    7 Hz (gaya gesek kayu yang menahan-lalu-melompat), geraman kayu
    85 Hz di bawahnya. Durasi 1,2 dtk."""
    rng = np.random.default_rng(17)
    dur = 1.2
    t = np.arange(dur * SR) / SR
    # Frekuensi dasar: naik lalu turun, + vibrato + jitter stick-slip.
    f0 = np.where(t < 0.7, 340 + 200 * (t / 0.7), 540 - 180 * ((t - 0.7) / 0.5))
    f0 += 12 * np.sin(2 * np.pi * 6 * t)
    f0 += lowpass(rng.standard_normal(len(t)), 0.02) * 18
    phase = np.zeros_like(t)
    phase[1:] = np.cumsum(f0[1:]) / SR * 2 * np.pi
    tone = (np.sin(phase) * 0.5 + np.sin(2 * phase) * 0.25
            + np.sin(3 * phase) * 0.12)
    # AM stick-slip 7 Hz + noise halus.
    am = 0.6 + 0.4 * np.sin(2 * np.pi * 7 * t + 0.5)
    am *= 0.8 + 0.2 * lowpass(rng.standard_normal(len(t)), 0.05)
    # Amplop: attack 0,15 dtk, lepas 0,3 dtk.
    env = np.minimum(t / 0.15, 1.0) * np.minimum((dur - t) / 0.3, 1.0)
    env = np.clip(env, 0, 1)
    # Geraman kayu rendah + sedikit noise gesek.
    groan = np.sin(2 * np.pi * 85 * t) * np.exp(-t * 2.5) * 0.3
    scrape = lowpass(rng.standard_normal(len(t)), 0.06) * 0.06
    x = tone * am * env + groan * env + scrape
    save("door_creak.wav", normalize_peak(x))


def giant_thud():
    """v2: dentuman Giant DEDIKASI (bukan footstep dipelankan).
    v1 sudah benar arahnya (sub sweep + gemuruh), tapi peak 0.99
    (nyaris clipping) dan attack-nya tumpul. v2: transient ketuk
    tajam di awal (retak tanah), sweep 80->30 Hz, gemuruh lebih
    panjang (total 1,8 dtk), gema samar kedua di 0,8 dtk, peak 0.9."""
    rng = np.random.default_rng(23)
    dur = 1.8
    t = np.arange(dur * SR) / SR
    # Transient retak tanah: noise burst 5 ms.
    crack = rng.standard_normal(len(t)) * np.exp(-t * 800) * 0.4
    # Sweep frekuensi turun: f(t) = 80 * (30/80)^(t/0.6) untuk t<0.6.
    phase = np.zeros_like(t)
    f = np.where(t < 0.6, 80.0 * (30.0 / 80.0) ** (t / 0.6), 30.0)
    phase[1:] = np.cumsum(f[1:]) / SR * 2 * np.pi
    sub = np.sin(phase) * np.exp(-t * 2.8)
    # Gemuruh: noise sangat lowpass, decay 1,2 dtk.
    rumble = lowpass(rng.standard_normal(len(t)), 0.012) * np.exp(-t * 3.0) * 1.4
    # Dentuman kedua (kaki satunya menapak), lebih pelan.
    t2 = np.clip(t - 0.45, 0, None)
    sub2 = np.sin(2 * np.pi * 42 * t2) * np.exp(-t2 * 5.0) * (t >= 0.45) * 0.55
    # Gema samar: sub 36 Hz di 0,8 dtk.
    t3 = np.clip(t - 0.8, 0, None)
    echo = np.sin(2 * np.pi * 36 * t3) * np.exp(-t3 * 4.0) * (t >= 0.8) * 0.25
    x = crack + sub * 0.9 + rumble + sub2 + echo
    save("giant_thud.wav", normalize_peak(x, 0.9))


def crickets():
    """v14: jangkrik malam, bed ambience di atas angin. Loop 6 dtk:
    dua jangkrik (4,2 kHz + 4,6 kHz), tiap train 3-4 chirp 18 ms,
    train tiap ~1,2 dtk. Sangat pelan (peak 0,3) + di-mix -30 dB di
    audio.gd, supaya tidak mengganggu radio dan suara Giant.
    Batas jujur sama seperti suara lain: belum didengar telinga
    manusia; yang dicek spektrum (centroid ~4,2 kHz) + jalur play."""
    rng = np.random.default_rng(41)
    dur = 6.0
    t = np.arange(dur * SR) / SR
    x = np.zeros_like(t)

    def add_cricket(freq, offset):
        tt = 0.0
        while tt < dur:
            train_len = int(rng.integers(3, 5))
            for c in range(train_len):
                start = tt + c * 0.07 + offset
                if start >= dur:
                    break
                n = int(0.018 * SR)
                i0 = int(start * SR)
                i1 = min(i0 + n, len(t))
                if i1 <= i0:
                    continue
                env = np.hanning(i1 - i0)
                seg_t = np.arange(i1 - i0) / SR
                x[i0:i1] += np.sin(2 * np.pi * freq * seg_t) * env * 0.5
            tt += float(rng.uniform(1.0, 1.5))

    add_cricket(4200.0, 0.0)
    add_cricket(4600.0, 0.45)
    x = make_loopable(x / np.abs(x).max() * 0.3)
    save("crickets.wav", x)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    wind()
    footstep()
    heartbeat()
    door_creak()
    giant_thud()
    crickets()
