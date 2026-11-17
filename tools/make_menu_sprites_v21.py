#!/usr/bin/env python3
## Menu v21: kertas buku jaga bertepi sobek (menu_ledger_v21.png).
##
## Masalah v20: tekstur ledger fully opaque (alpha 255 di semua
## tepi) — panel tampil sebagai persegi keras yang ditempel di atas
## backdrop, itu separuh alasan Arya menilai menu 3/10 ("ga nyatu
## ama background nya"). Perbaikan di sini, dari foto yang SAMA
## (menu_ledger_v20.png, dari foto perkamen Vecteezy 57329614):
##   1. Tepi sobek alpha: batas kertas tidak lagi garis lurus —
##      inset berombak (jumlah sinus, seed tetap) + 2-3 robekan dalam
##      di tiap sisi. Backdrop kelihatan lewat sobekan, kertas terasa
##      seperti benda di scene, bukan kartu UI.
##   2. Cahaya hangat tepi kanan: lampu teras pos ada di KANAN panel
##      di frame menu, jadi tepi kanan kertas menangkap cahaya hangat
##      (Kuning Lampu) dengan falloff halus. Ini cahaya, bukan dekorasi
##      — satu sumber cahaya per frame, aturan moodboard.
##   3. Tepi digelapkan tipis (burned edge) supaya sobekan kebaca.
## Isi kertas (tekstur, garis, noda) tidak diubah. Deterministik.
## Sprite tetap kelas PLACEHOLDER (foto stok + typeset).

import math
import random
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "assets" / "sprites"
SRC = OUT / "menu_ledger_v20.png"

W, H = 460, 600


def _wave(t: float, phases: tuple) -> float:
    # Ombak halus dari jumlah sinus: 0..1, seed tetap lewat fase.
    v = 0.0
    for amp, freq, ph in phases:
        v += amp * math.sin(t * freq + ph)
    return max(0.0, min(1.0, 0.5 + v))


def _edge_cut(length: int, base: float, depth: float, seed: int) -> list:
    # Inset tepi (px) sepanjang satu sisi, berombak + robekan dalam.
    rng = random.Random(seed)
    ph = (
        (0.30, 0.045, rng.uniform(0, 6.28)),
        (0.14, 0.11, rng.uniform(0, 6.28)),
        (0.06, 0.23, rng.uniform(0, 6.28)),
    )
    cuts = [base + depth * _wave(i, ph) for i in range(length)]
    # 2 robekan dalam (notch) di posisi acak tiap sisi.
    for _ in range(2):
        c = rng.randrange(length // 6, 5 * length // 6)
        deep = rng.uniform(14, 26)
        wide = rng.randrange(6, 14)
        for i in range(max(0, c - wide), min(length, c + wide)):
            d = 1.0 - abs(i - c) / wide
            cuts[i] = max(cuts[i], base + deep * d)
    return cuts


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    assert img.size == (W, H), img.size
    px = img.load()

    left = _edge_cut(H, 4, 12, 11)
    right = _edge_cut(H, 4, 12, 23)
    top = _edge_cut(W, 4, 10, 37)
    bottom = _edge_cut(W, 4, 12, 51)

    for y in range(H):
        for x in range(W):
            cut = max(left[y] - x, right[y] - (W - 1 - x),
                      top[x] - y, bottom[x] - (H - 1 - y))
            r, g, b, a = px[x, y]
            if cut >= 0:
                # Di luar batas sobek: transparan.
                px[x, y] = (r, g, b, 0)
                continue
            # Tepi dalam 8 px: gelapkan (burned edge).
            if cut > -8:
                f = 0.72 + 0.28 * (-cut / 8.0)
                r, g, b = int(r * f), int(g * f), int(b * f)
            # Cahaya hangat tepi kanan (lampu teras): falloff 70 px.
            if x > W - 70:
                t = (x - (W - 70)) / 70.0
                t = t * t
                r = min(255, int(r * (1.0 + 0.14 * t)))
                g = min(255, int(g * (1.0 + 0.03 * t)))
                b = min(255, int(b * (1.0 - 0.16 * t)))
            px[x, y] = (r, g, b, a)

    img.save(OUT / "menu_ledger_v21.png")
    print("menu_ledger_v21.png", img.size)


if __name__ == "__main__":
    main()
