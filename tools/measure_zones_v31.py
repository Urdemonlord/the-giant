#!/usr/bin/env python3
"""Ukur luminance zona (Rec709, skala L 0-100) di screenshot THE GIANT.

Dipakai v31: bandingkan v33 (baseline) vs v34 (kabut pucat) dengan
kotak dan rumus yang SAMA. Kotak dipilih dari isi frame v33:
- menu 1280x720: kubah di tengah atas jendela, kabut jendela di
  kanan belalai, pohon kiri, pita kabut tanah bawah jendela, papan,
  lentera (cek fokus hangat tetap hangat, R>G>B).
- night_dark/flash: pos tengah, pohon kiri/kanan, pita kabut tanah,
  langit atas.
- path_dark/flash: whole + tengah.
Jalankan: python3 tools/measure_zones_v31.py <prefix_lama> <prefix_baru>
"""
import sys
from PIL import Image

SHOTS = "/home/hatch/workspace/godot/shots"

# (x0, y0, x1, y1) dalam piksel, frame 1280x720.
ZONES = {
    "menu": {
        "kubah": (480, 30, 640, 120),
        "kabut_jendela": (700, 240, 830, 310),
        "veil_menu": (700, 150, 830, 210),
        "pohon_kiri": (60, 60, 220, 180),
        "pohon_dekat_menu": (20, 40, 120, 200),
        "pita_kabut_tanah": (150, 250, 450, 320),
        "papan": (860, 215, 950, 285),
        "lentera": (1140, 420, 1220, 520),
        "buku": (500, 560, 800, 650),
    },
    "night": {
        "whole": (0, 0, 1280, 720),
        "pos_tengah": (550, 300, 750, 450),
        "pohon_kiri": (120, 300, 350, 420),
        "pohon_kanan": (980, 300, 1220, 420),
        "pohon_dekat": (180, 280, 300, 380),
        "veil_kiri": (60, 330, 200, 420),
        "veil_kanan": (1050, 330, 1200, 420),
        "pita_kabut_tanah": (150, 420, 500, 500),
        "langit": (500, 20, 800, 120),
    },
    "path": {
        "whole": (0, 0, 1280, 720),
        "tengah": (500, 300, 780, 500),
        "langit": (500, 20, 800, 120),
    },
}

FILES = {
    "menu": "menu_no_save",
    "night_dark": "night_dark",
    "night_flash": "night_flash",
    "path_dark": "path_dark",
    "path_flash": "path_flash",
}


def zone_stats(img, box):
    crop = img.crop(box).convert("RGB")
    px = list(crop.getdata())
    n = len(px)
    r = sum(p[0] for p in px) / n
    g = sum(p[1] for p in px) / n
    b = sum(p[2] for p in px) / n
    lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0 * 100.0
    return lum, r, g, b


def measure(prefix):
    out = {}
    for key, fname in FILES.items():
        path = f"{SHOTS}/{prefix}_{fname}.png"
        try:
            img = Image.open(path)
        except FileNotFoundError:
            print(f"  SKIP {path} (tidak ada)")
            continue
        group = "menu" if key == "menu" else ("night" if key.startswith("night") else "path")
        print(f"  --- {prefix}_{fname}.png")
        for name, box in ZONES[group].items():
            lum, r, g, b = zone_stats(img, box)
            out[(key, name)] = lum
            print(f"      {name:18s} L={lum:5.1f}  RGB=({r:5.1f},{g:5.1f},{b:5.1f})")
    return out


if __name__ == "__main__":
    a = measure(sys.argv[1]) if len(sys.argv) > 1 else {}
    if len(sys.argv) > 2:
        print()
        b = measure(sys.argv[2])
        print()
        print("  === DELTA (baru - lama) ===")
        for k in sorted(set(a) & set(b)):
            print(f"      {k[0]:12s} {k[1]:18s} {a[k]:5.1f} -> {b[k]:5.1f}  ({b[k]-a[k]:+5.1f})")
