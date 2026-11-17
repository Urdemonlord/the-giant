#!/usr/bin/env python3
## Menu v21: siluet Giant untuk backdrop menu.
##
## Referensi: sprite elephant_shadow dari sheet Arya (siluet gajah
## samping, foto asli, bukan generate). Masalahnya: tekstur itu
## menghadap KANAN (kepala di kanan), sedangkan di frame menu Giant
## harus menghadap pos (kepala ke kiri, ke arah kamera/pemain).
## Sprite3D billboard tidak bisa flip, jadi dibuat salinan yang
## dibalik horizontal di sini — satu-satunya perubahan geometri.
## Sisanya hanya grade: dikali 0.8 + desaturasi ke arah Hijau Sakit,
## supaya jadi siluet malam di kabut, bukan gajah siang.
##
## Keluaran: assets/sprites/menu_giant_v21.png (207x137, RGBA).
## Dijalankan ulang dengan seed tetap (deterministik, tanpa acak).
## Sprite ini PLACEHOLDER kelasnya sama dengan sprite lain: potongan
## dari sheet Arya, bukan art final gambar tangan.

from pathlib import Path
from PIL import Image, ImageEnhance

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "assets" / "sprites"

SRC = HERE.parent / "assets" / "sprites" / "elephant_shadow.png"

def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    # Balik horizontal: kepala yang tadinya di kanan jadi di kiri,
    # menghadap pos jaga (dan pemain) di frame menu.
    img = img.transpose(Image.FLIP_LEFT_RIGHT)
    # Grade malam: lebih gelap + desaturasi ke hijau-abu sakit.
    # Alpha tidak disentuh (siluet tetap utuh, kabut yang menelannya
    # di scene, bukan tekstur yang dibuat transparan).
    r, g, b, a = img.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = ImageEnhance.Brightness(rgb).enhance(0.8)
    rgb = ImageEnhance.Color(rgb).enhance(0.55)
    # Geser dingin sedikit ke arah Hijau Sakit (#1C2420): kurangi
    # merah, tambah hijau tipis.
    px = rgb.load()
    w, h = rgb.size
    for y in range(h):
        for x in range(w):
            pr, pg, pb = px[x, y]
            px[x, y] = (int(pr * 0.92), int(pg * 1.0), int(pb * 0.94))
    img = Image.merge("RGBA", (*rgb.split(), a))
    img.save(OUT / "menu_giant_v21.png")
    print("menu_giant_v21.png", img.size)

if __name__ == "__main__":
    main()
