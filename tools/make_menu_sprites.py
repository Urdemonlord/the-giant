#!/usr/bin/env python3
## Generator sprite Main UI THE GIANT (menu utama).
## Semua sprite digambar prosedural dengan PIL dari palette kunci game,
## BUKAN potongan foto dan BUKAN hasil model gambar: kelas PLACEHOLDER
## (aturan aset Arya: aset yang digambar/dibuat-buat itu placeholder,
## bukan art final). Kalau ada art final nanti, ganti file-file ini.
##
## Palette kunci (moodboard v2/v3, jangan tambah warna di luar ini
## kecuali sebagai campuran alpha dari warna-warna ini):
##   Hitam Kabut #05070A, Hijau Sakit #1C2420, Abu Lumut #5C6B57,
##   Kuning Lampu #D8A93B, Putih Tulang #E6E1D3, Merah REC #C63A24.
## Satu sumber cahaya per frame: glow lampu dari pojok kiri atas.
##
## Yang dibuat (assets/sprites/):
##   menu_logo.png      1000x280  judul "THE GIANT", huruf berat + rusak VHS
##   menu_ledger.png     460x600  kertas buku jaga gelap: noda, garis, stempel
##   menu_btn.png        460x64   strip kertas tombol (normal)
##   menu_btn_hover.png  460x64   strip kertas tombol (hover: lampu + garis kuning)
##   menu_btn_pressed.png 460x64  strip kertas tombol (pressed: gelap + cap merah)
##   menu_rec.png         64x64   dot REC merah dengan glow
## Ikon lentera + jejak kaki TIDAK dibuat ulang: pakai sprite sheet Arya
## yang sudah ada (lantern.png, footprint.png) lewat SpriteRegistry.
##
## Jalankan: python3 tools/make_menu_sprites.py  (seed tetap = hasil tetap)

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
random.seed(7)

INK = (5, 7, 10)          # Hitam Kabut
SICK = (28, 36, 32)       # Hijau Sakit
MOSS = (92, 107, 87)      # Abu Lumut
LAMP = (216, 169, 59)     # Kuning Lampu
BONE = (230, 225, 211)    # Putih Tulang
REC = (198, 58, 36)       # Merah REC

SERIF_BLACK = "/usr/share/fonts/truetype/noto/NotoSerifDisplay-Black.ttf"
MONO_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"


def speckle(img: Image.Image, amount: int, alpha_max: int = 70) -> None:
    """Bintik-bintik gelap/terang acak: debu dan jamur kertas.
    Bintik terang jarang dan kecil supaya tidak terbaca seperti salju."""
    d = ImageDraw.Draw(img, "RGBA")
    w, h = img.size
    for _ in range(amount):
        x = random.randint(0, w - 1)
        y = random.randint(0, h - 1)
        if random.random() < 0.75:
            r = random.randint(1, 3)
            a = random.randint(8, alpha_max)
            d.ellipse([x - r, y - r, x + r, y + r], fill=(0, 0, 0, a))
        else:
            r = random.randint(1, 2)
            a = random.randint(6, alpha_max // 2)
            d.ellipse([x - r, y - r, x + r, y + r], fill=(230, 225, 211, a))


def blotches(img: Image.Image, n: int, col: tuple, a_lo: int, a_hi: int,
             r_lo: int, r_hi: int) -> None:
    """Noda air/lembap: blob lembut yang di-blur."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w, h = img.size
    for _ in range(n):
        x = random.randint(0, w)
        y = random.randint(0, h)
        r = random.randint(r_lo, r_hi)
        a = random.randint(a_lo, a_hi)
        d.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=col + (a,))
    layer = layer.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(layer)


def coffee_ring(img: Image.Image, cx: int, cy: int, r: int) -> None:
    """Lingkaran bekas cangkir kopi: garis tidak rata, ada yang putus."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for t in range(0, 360, 3):
        if random.random() < 0.18:
            continue
        a = math.radians(t)
        rr = r + random.randint(-3, 3)
        x = cx + int(rr * math.cos(a))
        y = cy + int(rr * math.sin(a) * 0.9)
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(20, 12, 4, 90))
    layer = layer.filter(ImageFilter.GaussianBlur(1))
    img.alpha_composite(layer)


def torn_edge_mask(w: int, h: int, jitter: int = 5) -> Image.Image:
    """Mask dengan tepi kiri/kanan/atas/bawah yang disobek (alpha kasar)."""
    mask = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(mask)
    for x in range(w):
        cut_top = random.randint(0, jitter)
        cut_bot = random.randint(0, jitter)
        d.rectangle([x, 0, x, cut_top], fill=0)
        d.rectangle([x, h - cut_bot, x, h], fill=0)
    for y in range(h):
        cut_l = random.randint(0, jitter)
        cut_r = random.randint(0, jitter)
        d.rectangle([0, y, cut_l, y], fill=0)
        d.rectangle([w - cut_r, y, w, y], fill=0)
    return mask


def stamp(img: Image.Image, text: str, cx: int, cy: int, angle: float,
          size: int, col: tuple, alpha: int) -> None:
    """Stempel karet: teks miring, tinta tidak rata, sebagian hilang."""
    font = ImageFont.truetype(MONO_BOLD, size)
    tw = int(font.getlength(text)) + 24
    th = size + 24
    layer = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rectangle([6, 6, tw - 7, th - 7], outline=col + (alpha,), width=3)
    d.text((12, 10), text, font=font, fill=col + (alpha,))
    # Tinta stempel tidak rata: hapus bercak acak.
    erase = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ed = ImageDraw.Draw(erase)
    for _ in range(22):
        x = random.randint(0, tw)
        y = random.randint(0, th)
        r = random.randint(2, 5)
        ed.ellipse([x - r, y - r, x + r, y + r], fill=(0, 0, 0, 255))
    layer = Image.composite(Image.new("RGBA", (tw, th), (0, 0, 0, 0)), layer, erase)
    layer = layer.rotate(angle, expand=True, resample=Image.BICUBIC)
    img.alpha_composite(layer, (cx - layer.width // 2, cy - layer.height // 2))


def make_logo() -> None:
    w, h = 1000, 280
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    text = "THE GIANT"
    # Ukuran huruf disesuaikan sampai teks muat (batas 920px): ronde
    # pertama teks kepotong di tepi kanan.
    size = 170
    while size > 100:
        font = ImageFont.truetype(SERIF_BLACK, size)
        total = sum(int(font.getlength(c)) - (14 if c != " " else 0) for c in text)
        if total <= 920:
            break
        size -= 4
    font = ImageFont.truetype(SERIF_BLACK, size)
    # Posisi tiap huruf dihitung sekali; ghost VHS digambar per huruf
    # pada posisi yang sama (ronde sebelumnya ghost digambar sebagai
    # satu string utuh tanpa tracking, jadi meluber dan kepotong).
    positions: list = []
    x = 52
    for ch in text:
        positions.append((ch, x, 52 + random.randint(-4, 4)))
        x += int(font.getlength(ch)) - (14 if ch != " " else 0)
    # Ghost VHS: salinan merah geser kiri, salinan lumut geser kanan.
    ghost = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ghost)
    for ch, cx, cy in positions:
        gd.text((cx - 4, cy), ch, font=font, fill=REC + (110,))
        gd.text((cx + 4, cy + 2), ch, font=font, fill=MOSS + (90,))
    img.alpha_composite(ghost)
    # Huruf utama.
    main = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    md = ImageDraw.Draw(main)
    for ch, cx, cy in positions:
        md.text((cx, cy), ch, font=font, fill=BONE + (255,))
    img.alpha_composite(main)
    # Tear band: satu pita horizontal digeser 7px ke kanan.
    band_y0, band_y1 = 118, 138
    band = img.crop((0, band_y0, w, band_y1))
    img.paste(Image.new("RGBA", (w, band_y1 - band_y0), (0, 0, 0, 0)), (0, band_y0))
    img.alpha_composite(band, (7, band_y0))
    # Scanlines: tiap baris ke-3 digelapkan.
    ov = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    for y in range(0, h, 3):
        od.line([(0, y), (w, y)], fill=(0, 0, 0, 60), width=1)
    img.alpha_composite(ov)
    speckle(img, 140, 35)
    img.save(OUT / "menu_logo.png")


def make_ledger() -> None:
    w, h = 460, 600
    img = Image.new("RGBA", (w, h), (36, 31, 24, 255))  # kertas gelap hangat
    # Noda lembap + belang kertas.
    blotches(img, 14, (16, 14, 10), 20, 55, 40, 130)
    blotches(img, 10, (90, 78, 52), 12, 30, 30, 90)
    # Glow lampu dari pojok kiri atas: satu sumber cahaya.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(260, 0, -4):
        a = int(70 * (1 - r / 260))
        gd.ellipse([40 - r, 30 - r, 40 + r, 30 + r], fill=LAMP + (a,))
    glow = glow.filter(ImageFilter.GaussianBlur(30))
    img.alpha_composite(glow)
    # Garis aturan buku: samar, jarak 44px, mulai di bawah kepala.
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(150, h - 20, 44):
        d.line([(28, y), (w - 28, y)], fill=(12, 10, 8, 110), width=2)
    # Vignette: tepi lebih gelap.
    vig = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(46):
        a = int(150 * (1 - i / 46) ** 2)
        vd.rectangle([i, i, w - 1 - i, h - 1 - i], outline=(0, 0, 0, a))
    vig = vig.filter(ImageFilter.GaussianBlur(6))
    img.alpha_composite(vig)
    coffee_ring(img, 350, 540, 52)
    blotches(img, 3, (10, 8, 6), 40, 70, 20, 60)
    # Sudut terlipat kanan bawah: segitiga sedikit lebih terang + garis lipat.
    fold = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fold)
    fd.polygon([(w, h - 64), (w - 64, h), (w, h)], fill=(74, 62, 42, 200))
    fd.line([(w - 64, h), (w, h - 64)], fill=(12, 10, 8, 160), width=2)
    img.alpha_composite(fold)
    # Stempel POS 07, tinta merah pudar, miring. Di pojok kanan atas,
    # di atas logo (ronde 1 stempel di (358,96) tertutup huruf T logo
    # dan terbaca "PUS 07").
    stamp(img, "POS 07", 395, 42, -12, 30, REC, 170)
    speckle(img, 180, 30)
    # Tepi disobek.
    mask = torn_edge_mask(w, h, 4)
    img.putalpha(Image.composite(img.split()[3], Image.new("L", (w, h), 0), mask))
    img.save(OUT / "menu_ledger.png")


def make_button(name: str, fill: tuple, border_lamp: bool, pressed: bool) -> None:
    w, h = 460, 64
    img = Image.new("RGBA", (w, h), fill + (255,))
    blotches(img, 6, (12, 10, 8), 15, 40, 20, 70)
    # Jahitan putus-putus di tepi dalam: label kertas yang dijahit.
    d = ImageDraw.Draw(img, "RGBA")
    dash = 8
    for x in range(10, w - 10, dash * 2):
        d.line([(x, 8), (x + dash, 8)], fill=MOSS + (150,), width=2)
        d.line([(x, h - 9), (x + dash, h - 9)], fill=MOSS + (150,), width=2)
    for y in range(10, h - 10, dash * 2):
        d.line([(8, y), (8, y + dash)], fill=MOSS + (150,), width=2)
        d.line([(w - 9, y), (w - 9, y + dash)], fill=MOSS + (150,), width=2)
    if border_lamp:
        # Hover: garis lampu di tepi kiri, strip sedikit lebih terang.
        d.rectangle([0, 0, 5, h - 1], fill=LAMP + (230,))
        d.rectangle([0, 0, w - 1, 2], fill=LAMP + (90,))
    if pressed:
        # Pressed: cap merah samar di tepi kiri.
        stamp(img, "OK", 34, h // 2, -8, 20, REC, 120)
    speckle(img, 60, 30)
    mask = torn_edge_mask(w, h, 3)
    img.putalpha(Image.composite(img.split()[3], Image.new("L", (w, h), 0), mask))
    img.save(OUT / name)


def make_rec() -> None:
    s = 64
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for r in range(30, 10, -1):
        a = int(70 * (1 - (30 - r) / 20)) if r > 12 else 0
        d.ellipse([32 - r, 32 - r, 32 + r, 32 + r], fill=REC + (max(a, 0),))
    d.ellipse([20, 20, 44, 44], fill=REC + (255,))
    d.ellipse([20, 20, 44, 44], outline=(120, 20, 10, 255), width=2)
    d.ellipse([26, 26, 34, 34], fill=(255, 120, 90, 200))
    img.save(OUT / "menu_rec.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    make_logo()
    make_ledger()
    make_button("menu_btn.png", (46, 40, 32), border_lamp=False, pressed=False)
    make_button("menu_btn_hover.png", (62, 52, 38), border_lamp=True, pressed=False)
    make_button("menu_btn_pressed.png", (28, 24, 19), border_lamp=False, pressed=True)
    make_rec()
    for f in ["menu_logo.png", "menu_ledger.png", "menu_btn.png",
              "menu_btn_hover.png", "menu_btn_pressed.png", "menu_rec.png"]:
        p = OUT / f
        print(f, Image.open(p).size, p.stat().st_size, "bytes")


if __name__ == "__main__":
    main()
