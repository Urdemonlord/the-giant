#!/usr/bin/env python3
"""Suara radio THE GIANT: gTTS (id) + proses jadi radio tua rusak.

Teks sama persis dengan LINES di scripts/interactables/radio.gd, hanya
"...krrk..." (penanda statis, bukan kata) yang tidak dibacakan gTTS.
Urutan file radio_voice_1..5.wav = urutan LINES (1..5).

Rantai proses per klip (ffmpeg, tanpa dependensi lain):
  1. gTTS lang="id" -> mp3 mentah (/tmp, bukan di repo).
  2. Band-pass radio tua: highpass 300 Hz + lowpass 3000 Hz.
  3. Variasi pitch/kecepatan per baris (asetrate): baris 1-4 nyaris
     normal (1.00/1.02/0.99/1.01), baris 5 sengaja 0.90 (lebih rendah +
     lambat: "bukan suara manusia biasa", radio.gd).
  4. Statis ringan dicampur dari radio_static.wav yang sudah ada
     (volume 0.10, loop sampai durasi suara) + burst statis 0.25 dtk
     di awal (suara "mencari" frekuensi).
  5. Normalisasi peak ke -3 dB, lalu 16-bit mono WAV 22050 Hz
     (format yang sama dengan semua WAV proyek).

Jalankan dari root proyek:  python3 tools/make_radio_voice.py
Butuh internet (gTTS) + ffmpeg. Output: assets/audio/radio_voice_*.wav.
Lisensi: suara disintesis dari teks proyek sendiri lewat gTTS; tidak
ada audio berlisensi pihak ketiga. Batas jujur: belum pernah didengar
telinga manusia (sandbox tanpa sound card); yang diverifikasi adalah
durasi + bentuk gelombang + jalur play di test rig mode=audio.
"""
import os
import subprocess
import sys
import time

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "assets", "audio")
TMP = "/tmp/giant_radio_voice"
STATIC = os.path.join(AUDIO, "radio_static.wav")

# (nomor, teks untuk gTTS, faktor pitch/kecepatan)
LINES = [
    (1, "pos jaga taman, masuk", 1.00),
    (2, "Harian Rimba: gajah liar masuk kebun sawit, petani rugi miliaran", 1.02),
    (3, "sawit adalah anugerah Tuhan untuk rakyat Malayunesia", 0.99),
    (4, "Jangan jawab kalau ada yang mengetuk dari arah hutan.", 1.01),
    # Baris 5: suara yang "bukan manusia biasa" -> lebih rendah + lambat.
    (5, "mereka masih berdiri di sana... jangan lihat matanya...", 0.90),
]


def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        print("GAGAL:", " ".join(cmd), "\n", r.stderr[-2000:])
        sys.exit(1)
    return r


def ffprobe_dur(path):
    r = run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "csv=p=0", path])
    return float(r.stdout.strip())


def max_volume_db(path):
    r = subprocess.run(["ffmpeg", "-i", path, "-af", "volumedetect",
                        "-vn", "-sn", "-dn", "-f", "null", "/dev/null"],
                       capture_output=True, text=True)
    for line in r.stderr.splitlines():
        if "max_volume" in line:
            return float(line.split("max_volume:")[1].split("dB")[0].strip())
    raise RuntimeError("volumedetect tidak menemukan max_volume untuk " + path)


def main():
    os.makedirs(TMP, exist_ok=True)
    from gtts import gTTS

    for num, text, factor in LINES:
        raw_mp3 = os.path.join(TMP, f"raw_{num}.mp3")
        band_wav = os.path.join(TMP, f"band_{num}.wav")
        mixed_wav = os.path.join(TMP, f"mixed_{num}.wav")
        out_wav = os.path.join(AUDIO, f"radio_voice_{num}.wav")

        # 1. gTTS, 3x percobaan.
        for attempt in range(3):
            try:
                gTTS(text, lang="id").save(raw_mp3)
                break
            except Exception as e:  # noqa: BLE001 - jaringan, coba lagi
                print(f"  gTTS baris {num} percobaan {attempt + 1} gagal: {e}")
                time.sleep(2)
        else:
            print(f"GAGAL: gTTS baris {num} setelah 3 percobaan")
            sys.exit(1)

        # 2+3. Band-pass radio + variasi pitch/kecepatan.
        run(["ffmpeg", "-y", "-v", "error", "-i", raw_mp3, "-af",
             f"highpass=f=300,lowpass=f=3000,asetrate={SR}*{factor},"
             f"aresample={SR},pan=mono|c0=c0",
             "-ar", str(SR), "-ac", "1", band_wav])
        dur = ffprobe_dur(band_wav)

        # 4. Campur statis ringan (loop) + burst 0.25 dtk di awal.
        #    Statis ikut di-band-pass 300-3000 Hz supaya seluruh klip
        #    tetap di pita radio (statis mentah itu broadband, 73%
        #    energinya di atas 3 kHz, dan akan membocorkan lowpass).
        run(["ffmpeg", "-y", "-v", "error",
             "-i", band_wav,
             "-stream_loop", "-1", "-t", str(dur), "-i", STATIC,
             "-filter_complex",
             "[1:a]highpass=f=300,lowpass=f=3000,volume=0.10[bed];"
             "[1:a]atrim=0:0.25,highpass=f=300,lowpass=f=3000,volume=0.55,"
             "afade=t=out:st=0.05:d=0.20[burst];"
             "[0:a][bed][burst]amix=inputs=3:duration=first:normalize=0",
             "-ar", str(SR), "-ac", "1", mixed_wav])

        # 5. Normalisasi peak ke -3 dB.
        peak = max_volume_db(mixed_wav)
        gain = -3.0 - peak
        run(["ffmpeg", "-y", "-v", "error", "-i", mixed_wav, "-af",
             f"volume={gain:.2f}dB", "-ar", str(SR), "-ac", "1",
             "-sample_fmt", "s16", out_wav])

        final_dur = ffprobe_dur(out_wav)
        size = os.path.getsize(out_wav)
        print(f"radio_voice_{num}.wav: {final_dur:.2f}s {size} byte "
              f"pitch={factor} raw_gtts={os.path.getsize(raw_mp3)} byte")
    print("Selesai. File di assets/audio/radio_voice_1..5.wav")


if __name__ == "__main__":
    main()
