#!/usr/bin/env python3
"""Aset menu v26 THE GIANT — kepala Zunisha UTUH.
ATURAN DICABUT Arya 2026-11-18 15:50 WIB: Giant BOLEH ditampilkan
utuh sebagai siluet kepala gajah raksasa. v25 menampilkan hanya
belalai + gading + rahang bawah karena kusen jendela membatasi
pita pandang (dan grade v25 meng-crush pipi ke 0.5, jadi kepala
tidak terbaca sebagai kepala sama sekali — cuma kolom terang +
gading putih). v26: kepala UTUH masuk frame (jendela menu
diperlebar + pitch kamera -18, lihat main.gd), grade dibalik:
SELURUH kepala terbaca dengan struktur nilai internal, bukan
satu kolom terang.

Sumber: assets/sprites/elephant_front.png — sheet Arya (gajah
depan: kubah + telinga lebar + belalai + dua gading). Crop
(0, 0, 350, 270): lebih lebar dari v25 (10, 0, 340, 270) supaya
ujung gading kiri tidak terpotong. Bawah crop y 270 = ujung
belalai; kaki dipotong (kepala saja, bukan badan).

Grade (diukur lawan kabut menu L~50, transmisi kabut 0,47 di
z 12,5, tint billboard 1,2-1,3 — target kepala L~85-110 setelah
kabut, jadi ~70 lawan kabut 50):
  * desaturasi 0,45 + geser dingin, TANPA cerahkan global —
    kecerahan diatur per zona dari luminansi sumber yang diukur
    (piksel opak saja; sampling awal v26 sempat terkontaminasi
    piksel transparan RGB 0 dan salah letak gading kanan 25 px).
  * kubah/wajah (L sumber 54) x2,2 -> ~119; telinga (47/42)
    x2,2 -> ~100/92; belalai (51) x2,7 -> ~138; gading kiri
    (75) x2,5 -> ~188; gading kanan (67, di x 175-200, BUKAN
    195-235) x2,6 -> ~174. Gading paling terang, menempel di
    wajah jadi kebaca gading, bukan garis diagonal lepas.
  * tepi KIRI belalai saja digelapkan tipis (x 130-134, x0,7):
    kontur tanpa garis jeruji. Tepi kanan TIDAK digelapkan —
    itu sisi gading kanan.
  * mata dibiarkan (sudah lebih gelap dari wajah, membantu
    kepala kebaca wajah).

STATUS: PLACEHOLDER — kepala dari sheet Arya (aset asli) tapi
grade + skala kolosal (Zunisha) tetap placeholder, bukan art
final. Provenance: tools/ref/REFERENCES.md.
Jalankan: python3 tools/make_menu_head_v26.py (deterministik).
"""
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "assets" / "sprites"
FRONT = HERE.parent / "assets" / "sprites" / "elephant_front.png"


def grade_fog(im: Image.Image, bright: float, cool: tuple) -> Image.Image:
    """Grade kabut malam: desaturasi + cerahkan + geser dingin."""
    g = im.convert("RGB")
    gray = g.convert("L")
    g = Image.blend(g, Image.merge("RGB", (gray, gray, gray)), 0.45)
    g = ImageEnhance.Brightness(g).enhance(bright)
    gp = g.load()
    w, h = g.size
    for y in range(h):
        for x in range(w):
            r, gg, b = gp[x, y]
            gp[x, y] = (int(r * cool[0]), int(gg * cool[1]), int(b * cool[2]))
    out = g.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out


def alpha_bbox(im: Image.Image) -> tuple:
    """Kotak pembatas piksel tidak transparan (cek crop terpotong)."""
    a = im.getchannel("A")
    w, h = im.size
    ap = a.load()
    xs = [x for y in range(h) for x in range(w) if ap[x, y] > 10]
    ys = [y for y in range(h) for x in range(w) if ap[x, y] > 10]
    return (min(xs), min(ys), max(xs), max(ys)) if xs else (0, 0, 0, 0)


def make_head() -> None:
    src = Image.open(FRONT).convert("RGBA")
    print("source:", src.size, "alpha bbox:", alpha_bbox(src))
    head = src.crop((0, 0, 350, 270))
    print("crop alpha bbox:", alpha_bbox(head))
    head = head.filter(ImageFilter.GaussianBlur(1.0))
    head = grade_fog(head, 1.0, (0.85, 0.92, 1.02))
    w, h = head.size
    px = head.load()
    # Zona (dalam koordinat crop 350x270 = koordinat sumber):
    # belalai x 130-175 (tengah, y 55-270); gading kiri x 5-75
    # y 140-260, gading kanan x 175-200 y 130-260; telinga
    # x 35-130 dan x 200-330 (y 20-165); kubah y 0-80.
    # Urutan cek: gading dulu (menang atas telinga di x 180-200,
    # y 130-165), lalu belalai, lalu telinga, lalu dasar.
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if ((5 <= x <= 75 and y >= 140)
                    or (175 <= x <= 200 and y >= 130)) and lum >= 30:
                f = 2.55  # gading: paling terang
            elif abs(x - 152) < 24 and y >= 55:
                f = 2.7  # belalai: lebih terang dari wajah
            elif (35 <= x <= 130 or 200 <= x <= 330) and 20 <= y <= 165:
                f = 2.2  # telinga: sama dengan wajah (bentuk
                # misah lewat bayangan alami sumber, bukan crush)
            else:
                f = 2.2  # kubah + wajah: dasar
            # (dihapus ronde 2: pita gelap di tepi kiri belalai
            # terbaca seperti retakan hitam di tengah wajah.
            # Kontur belalai sudah cukup dari kecerahan.)
            px[x, y] = (min(255, int(r * f)), min(255, int(g * f)),
                        min(255, int(b * f)), a)
    head.save(OUT / "giant_head_zunisha_v26.png")
    print("giant_head_zunisha_v26.png", head.size)
    bg = Image.new("RGB", head.size, (60, 65, 60))
    bg.paste(head, (0, 0), head)
    bg.save("/tmp/head_v26_preview.png")
    print("preview /tmp/head_v26_preview.png")


if __name__ == "__main__":
    make_head()
