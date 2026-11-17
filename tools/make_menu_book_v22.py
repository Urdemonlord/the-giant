#!/usr/bin/env python3
## Generator halaman buku menu THE GIANT v22 (Opsi B, diegetic desk).
##
## v22 mengganti menu kertas-tempel (v19-v21) dengan BUKU JAGA FISIK
## yang tergeletak di atas meja pos: kamera menyorot meja, buku adalah
## menu-nya, lentera fisik di samping buku. Halaman buku harus bisa
## dibaca dengan tinta GELAP (ketikan mesin tik), jadi kertasnya dibuat
## JAUH LEBIH TERANG dari ledger v20/v21 (yang gelap karena teksnya
## putih). Zona teks dibuat tenang (blur ringan di tengah), kerut dan
## noda foto tetap di tepi.
##
## REFERENSI PER SPRITE (sama seperti v20, jangan ganti sumber):
##   menu_book_page_l/r.png — halaman kiri/kanan buku terbuka:
##     * Foto asli: parchment_vecteezy.jpg di tools/ref/ (Vecteezy
##       free photo 57329614, "distressed paper texture", 3497x1960).
##       Crop tengah foto (kerut + noda), di-grade TERANG ke tulang
##       hangat (bukan gelap seperti ledger v20): darken 0.88,
##       green 1.02. Tengah halaman di-blur (radius 6) supaya garis
##       teks tidak bertabrakan dengan kerut foto (kritik #1: tekstur
##       kusut di belakang tombol terlalu ramai). Tepi sobek alpha
##       (irregular, ~14px) meniru tepi sobek foto. Kanan = flip
##       horizontal kiri (kreasi beda, satu sumber).
##     * Grain: tile grain_mb000.png (high-pass foto kabut Sumatra,
##       sama seperti v20), bukan noise acak.
##   menu_form_page.png — lembar formulir Peralatan Pos (layar Options):
##     * Foto kertas yang SAMA, crop beda yang lebih tenang, grade
##       terang (darken 0.92). Dipakai sebagai latar ScrollContainer
##       Options dengan teks tinta gelap.
##
## STATUS: masih kelas PLACEHOLDER (aturan aset Arya): kertas foto stok
## + teks typeset, bukan art final gambar tangan.
##
## Jalankan: python3 tools/make_menu_book_v22.py
## (seed tetap = hasil tetap; referensi di tools/ref/)

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
REF = HERE / "ref"
OUT = HERE.parent / "assets" / "sprites"
random.seed(22)

PARCHMENT = REF / "parchment_vecteezy.jpg"
GRAIN_TILE = REF / "grain_mb000.png"


def load_grain(w: int, h: int) -> Image.Image:
    """Tile grain dari foto kabut asli (high-pass, mean ~128)."""
    tile = Image.open(GRAIN_TILE).convert("L")
    out = Image.new("L", (w, h), 128)
    for y in range(0, h, tile.height):
        for x in range(0, w, tile.width):
            out.paste(tile, (x, y))
    return out.crop((0, 0, w, h))


def apply_sampled_grain(img: Image.Image, strength: int = 6) -> None:
    """Grain dari foto asli: overlay high-pass, bukan noise acak."""
    w, h = img.size
    g = load_grain(w, h)
    base = img.convert("RGBA")
    px = base.load()
    gp = g.load()
    for y in range(h):
        for x in range(w):
            d = (gp[x, y] - 128) * strength // 128
            if d == 0:
                continue
            r, gg, b, a = px[x, y]
            px[x, y] = (
                max(0, min(255, r + d)),
                max(0, min(255, gg + d)),
                max(0, min(255, b + d)),
                a,
            )
    img.paste(base, (0, 0))


def grade_paper_light(crop: Image.Image, w: int, h: int,
                      darken: float, green: float) -> Image.Image:
    """Foto kertas asli -> halaman buku TERANG (tinta gelap bisa dibaca):
    desaturasi ringan, sedikit gelapkan, geser hangat. Sama dengan
    grade_paper v20 tapi darken jauh lebih tinggi (0.88 vs 0.52)."""
    img = crop.resize((w, h), Image.LANCZOS).convert("RGB")
    g = img.convert("L")
    img = Image.blend(img, Image.merge("RGB", (g, g, g)), 0.45)
    px = img.load()
    for y in range(h):
        for x in range(w):
            r, gg, b = px[x, y]
            r = int(r * darken)
            gg = int(gg * darken * green)
            b = int(b * darken * (2.0 - green) * 0.94)
            px[x, y] = (max(0, min(255, r)), max(0, min(255, gg)),
                        max(0, min(255, b)))
    return img.convert("RGBA")


def calm_center(img: Image.Image, margin: int = 130, radius: int = 7) -> None:
    """Tenangkan zona teks di tengah halaman: blur ringan supaya kerut
    foto tidak bertabrakan dengan huruf (kritik #1). Tepi tetap kasar."""
    w, h = img.size
    region = img.crop((margin, margin, w - margin, h - margin))
    region = region.filter(ImageFilter.GaussianBlur(radius))
    img.paste(region, (margin, margin))


def torn_edges(img: Image.Image, depth: int = 14) -> None:
    """Tepi sobek alpha (irregular) meniru tepi sobek foto asli."""
    w, h = img.size
    a = img.getchannel("A")
    px = a.load()
    for x in range(w):
        for y in range(h):
            d_edge = min(x, w - 1 - x, y, h - 1 - y)
            if d_edge >= depth:
                continue
            # Sobekan tidak rata: ambang naik-turun pakai hash posisi.
            h1 = (x * 73 + y * 131) % 11
            if d_edge < h1:
                px[x, y] = 0
            elif d_edge < depth:
                px[x, y] = int(255 * (d_edge - h1 + 1) / (depth - h1 + 1))
    img.putalpha(a)


def make_book_pages() -> None:
    photo = Image.open(PARCHMENT).convert("RGB")
    # Crop tengah foto: kerut + noda, hindari sudut paling terang.
    crop = photo.crop((300, 250, 1324, 1274))
    left = grade_paper_light(crop, 1024, 1024, darken=0.88, green=1.02)
    calm_center(left)
    torn_edges(left)
    apply_sampled_grain(left, strength=5)
    left.save(OUT / "menu_book_page_l.png")
    print("menu_book_page_l.png", left.size)
    right = left.transpose(Image.FLIP_LEFT_RIGHT)
    right.save(OUT / "menu_book_page_r.png")
    print("menu_book_page_r.png", right.size)


def make_form_page() -> None:
    photo = Image.open(PARCHMENT).convert("RGB")
    # Crop yang lebih tenang (kanan bawah foto, kerut jarang).
    crop = photo.crop((1800, 900, 2568, 1924))
    img = grade_paper_light(crop, 768, 1024, darken=0.92, green=1.0)
    calm_center(img, margin=90, radius=9)
    apply_sampled_grain(img, strength=4)
    img.save(OUT / "menu_form_page.png")
    print("menu_form_page.png", img.size)


if __name__ == "__main__":
    make_book_pages()
    make_form_page()
