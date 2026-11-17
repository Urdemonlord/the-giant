#!/usr/bin/env python3
## Generator sprite Main UI THE GIANT v20 — REDO dari referensi asli.
##
## v19 dibuat prosedural dari nol (PIL + noise acak) tanpa referensi foto
## asli, melanggar langkah "start from a real reference" di skill
## game_asset_delivery. v20 memperbaiki itu: tiap sprite meniru satu
## referensi nyata yang sudah ada di ide THE GIANT. Yang masih berupa
## huruf/glyph (judul, stempel, teks) memakai font asli, bukan gambar
## bebas; kerusakannya diambil dari foto asli, bukan noise acak.
##
## REFERENSI PER SPRITE (baca sebelum mengubah angka apa pun):
##   menu_logo_v20.png — judul "THE GIANT":
##     * Huruf: Noto Sans Black, grotesque berat yang sama dengan judul
##       cover moodboard v3 hal. 1 ("THE GIANT" putih tebal + garis
##       merah di bawahnya) dan header storyboard v2 hal. 1.
##     * Garis merah di bawah judul: meniru garis Merah REC di bawah
##       judul cover moodboard hal. 1 dan header storyboard hal. 1.
##     * Ghost merah bergeser: chromatic aberration seperti yang
##       terlihat di frame VHS moodboard hal. 2 (tile B Iron Lung,
##       tile C kaki di kabut).
##     * Tracking tear: pita horizontal yang menggeser sebagian huruf,
##       sesuai binding rule storyboard hal. 1 ("tracking robek") dan
##       frame moodboard hal. 2 (tile A lighthouse, tear putih di
##       tengah frame).
##     * Grain: BUKAN noise acak. Tile grain_mb000.png di tools/ref/
##       adalah high-pass dari area kabut foto hutan Sumatra berkabut
##       (mb-000.jpg, foto asli National Geographic, cover moodboard
##       v2/v3 hal. 1). TIDAK ada scanline di sprite: shader VHS menu
##       sudah memberi scanline; dua lapis scanline jadi tirai padat
##       (terbukti di screenshot v23, diperbaiki di ronde 2).
##   menu_ledger_v20.png — kertas buku jaga:
##     * Foto asli: parchment_vecteezy.jpg di tools/ref/ — foto
##       close-up kertas perkamen kusut, bernoda, tepi sobek
##       (Vecteezy free photo 57329614, "distressed paper texture",
##       3497x1960, https://www.vecteezy.com/photo/57329614-...).
##       Di-grade gelap ke palette kunci (desaturasi + arah Hijau
##       Sakit/Hitam Kabut) supaya jadi halaman buku malam, bukan
##       kertas siang. Kerut, noda, dan tepi sobeknya dari foto itu,
##       bukan digambar.
##     * Garis aturan: layout garis buku log, meniru halaman bergaris
##       pada foto logbook "Notes and Notams" (buku pilot rusak air,
##       image-search 2026-11-18) dan sprite logbook di sheet Arya.
##       Foto Notams TIDAK dipakai sebagai tekstur: tulisannya memuat
##       nomor telepon asli orang lain.
##     * Stempel "POS 07": meniru cap basah SK di moodboard hal. 4
##       ("cap basah SK", suara 3) dan stempel di surat izin in-game.
##       Diketik dengan font mono, Merah REC, miring, di sudut bawah
##       kanan kertas (v19 menaruhnya di (358,96) sampai tertutup
##       huruf T logo dan terbaca "PUS 07").
##     * Glow lampu pojok kiri atas: satu sumber cahaya per frame
##       (aturan moodboard hal. 4), Kuning Lampu.
##   menu_btn_v20*.png — strip kertas tombol:
##     * Foto kertas yang SAMA dengan ledger (satu sumber, konsisten),
##       crop berbeda. Hover: garis Kuning Lampu di kiri (aturan
##       hierarki: satu aksen hangat). Pressed: grade lebih gelap +
##       garis bawah Merah REC. Jahitan putus-putus meniru jahitan
##       jilid buku log pada foto Notams.
##   menu_rec_v20.png — dot REC:
##     * Glyph polos mengikuti label REC moodboard (dot merah + teks
##       mono "REC", hal. 1-2). Bukan foto; tidak ada yang perlu
##       difoto dari sebuah titik merah.
##   Lentera + jejak kaki: tetap dari sheet Arya (lantern.png,
##   footprint.png), bukan dibuat ulang.
##
## STATUS: sprite v20 masih kelas PLACEHOLDER (aturan aset Arya) karena
## huruf/stempelnya typeset dan kertasnya foto stok, bukan art final
## gambar tangan. Bedanya dengan v19: tiap piksel tekstur dan kerusakan
## punya referensi foto asli yang bisa ditunjuk, bukan karangan.
##
## Palette kunci (jangan tambah warna di luar ini kecuali campuran
## alpha): Hitam Kabut #05070A, Hijau Sakit #1C2420, Abu Lumut
## #5C6B57, Kuning Lampu #D8A93B, Putih Tulang #E6E1D3, Merah REC
## #C63A24.
##
## Jalankan: python3 tools/make_menu_sprites_v20.py
## (seed tetap = hasil tetap; referensi di tools/ref/)

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
REF = HERE / "ref"
OUT = HERE.parent / "assets" / "sprites"
random.seed(20)

INK = (5, 7, 10)          # Hitam Kabut
SICK = (28, 36, 32)       # Hijau Sakit
MOSS = (92, 107, 87)      # Abu Lumut
LAMP = (216, 169, 59)     # Kuning Lampu
BONE = (230, 225, 211)    # Putih Tulang
REC = (198, 58, 36)       # Merah REC

GROTESQUE_BLACK = "/usr/share/fonts/truetype/noto/NotoSans-Black.ttf"
MONO_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

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


def apply_sampled_grain(img: Image.Image, strength: int = 14) -> None:
    """Grain VHS dari foto asli: overlay high-pass, bukan noise acak."""
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


def grade_paper(crop: Image.Image, w: int, h: int,
                darken: float, green: float) -> Image.Image:
    """Foto kertas asli -> halaman buku malam: desaturasi, gelapkan,
    geser ke hijau sakit. Kerut dan noda foto tetap utuh."""
    img = crop.resize((w, h), Image.LANCZOS).convert("RGB")
    g = img.convert("L")
    img = Image.blend(img, Image.merge("RGB", (g, g, g)), 0.55)
    px = img.load()
    for y in range(h):
        for x in range(w):
            r, gg, b = px[x, y]
            r = int(r * darken)
            gg = int(gg * darken * green)
            b = int(b * darken * (2.0 - green) * 0.92)
            px[x, y] = (max(0, min(255, r)), max(0, min(255, gg)),
                        max(0, min(255, b)))
    return img.convert("RGBA")


def lamp_glow(img: Image.Image, cx: int, cy: int, r: int,
              alpha: int) -> None:
    """Satu sumber cahaya: glow lampu Kuning Lampu dari pojok kiri atas."""
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=LAMP + (alpha,))
    glow = glow.filter(ImageFilter.GaussianBlur(r // 2))
    img.alpha_composite(glow)


def ruled_lines(img: Image.Image, top: int, bottom: int, step: int,
                alpha: int) -> None:
    """Garis aturan buku log (layout, bukan tekstur)."""
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(top, bottom, step):
        d.line([(28, y), (img.width - 28, y)], fill=BONE + (alpha,), width=1)


def stamp(img: Image.Image, text: str, cx: int, cy: int, size: int,
          angle: float) -> None:
    """Cap basah: kotak ganda + teks mono Merah REC, miring."""
    font = ImageFont.truetype(MONO_BOLD, size)
    tmp = Image.new("RGBA", (220, 76), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    d.rectangle([4, 4, 215, 71], outline=REC + (220,), width=3)
    d.rectangle([10, 10, 209, 65], outline=REC + (180,), width=1)
    d.text((110, 38), text, font=font, fill=REC + (240,),
           anchor="mm")
    tmp = tmp.rotate(angle, expand=True, resample=Image.BICUBIC)
    img.alpha_composite(tmp, (cx - tmp.width // 2, cy - tmp.height // 2))


def stitch_border(img: Image.Image, alpha: int = 70) -> None:
    """Jahitan jilid buku log: garis putus-putus di tepi strip."""
    d = ImageDraw.Draw(img, "RGBA")
    w, h = img.size
    for x in range(8, w - 8, 12):
        d.line([(x, 5), (x + 6, 5)], fill=BONE + (alpha,), width=2)
        d.line([(x, h - 6), (x + 6, h - 6)], fill=BONE + (alpha,), width=2)


def make_logo() -> None:
    """Judul meniru cover moodboard hal. 1 + header storyboard hal. 1:
    grotesque berat putih tulang, garis merah di bawah, ghost merah,
    tear tracking, grain dari foto kabut asli. Margin dalam 40px supaya
    tidak terpotong di tepi kiri portrait (bug v19)."""
    W, H = 920, 240
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    font = ImageFont.truetype(GROTESQUE_BLACK, 148)
    d = ImageDraw.Draw(img)
    # Ghost merah (chromatic aberration frame VHS): geser 3px.
    d.text((43, 8), "THE GIANT", font=font, fill=REC + (90,))
    # Judul utama.
    d.text((40, 8), "THE GIANT", font=font, fill=BONE + (255,))
    # Garis merah di bawah judul (cover moodboard hal. 1).
    d.rectangle([40, 196, 880, 201], fill=REC + (255,))
    # Tracking tear: pita y 96..122 digeser +14px (binding rule
    # storyboard hal. 1: "tracking robek").
    band = img.crop((0, 96, W, 122))
    torn = Image.new("RGBA", (W, 26), (0, 0, 0, 0))
    torn.paste(band, (14, 0))
    img.paste(torn, (0, 96), torn)
    d = ImageDraw.Draw(img, "RGBA")
    d.line([(0, 96), (W, 96)], fill=(0, 0, 0, 110), width=2)
    d.line([(0, 122), (W, 122)], fill=(0, 0, 0, 90), width=1)
    apply_sampled_grain(img, strength=8)
    img.save(OUT / "menu_logo_v20.png")
    print("menu_logo_v20.png", img.size)


def make_ledger() -> None:
    """Kertas buku jaga dari FOTO kertas asli, di-grade gelap."""
    photo = Image.open(PARCHMENT).convert("RGB")
    # Crop tengah dengan kerut + noda terbanyak, hindari tepi paling
    # terang di kanan atas foto.
    crop = photo.crop((300, 250, 1220, 1450))
    img = grade_paper(crop, 460, 600, darken=0.52, green=1.12)
    lamp_glow(img, 40, 20, 260, 26)
    ruled_lines(img, 150, 560, 46, 7)
    apply_sampled_grain(img, strength=6)
    img.save(OUT / "menu_ledger_v20.png")
    print("menu_ledger_v20.png", img.size)


def make_buttons() -> None:
    """Tombol dari foto kertas yang SAMA dengan ledger, crop beda."""
    photo = Image.open(PARCHMENT).convert("RGB")
    crops = {
        "menu_btn_v20": ((300, 250, 760, 314), 0.58, 1.10, None),
        "menu_btn_v20_hover": ((300, 250, 760, 314), 0.66, 1.10, "lamp"),
        "menu_btn_v20_pressed": ((900, 900, 1360, 964), 0.42, 1.10, "rec"),
    }
    for name, (box, dark, green, accent) in crops.items():
        img = grade_paper(photo.crop(box), 460, 64, darken=dark, green=green)
        if accent == "lamp":
            d = ImageDraw.Draw(img, "RGBA")
            d.rectangle([0, 0, 5, 64], fill=LAMP + (255,))
            lamp_glow(img, 10, 32, 120, 22)
        if accent == "rec":
            d = ImageDraw.Draw(img, "RGBA")
            d.rectangle([0, 60, 460, 64], fill=REC + (255,))
        stitch_border(img)
        apply_sampled_grain(img, strength=5)
        img.save(OUT / (name + ".png"))
        print(name + ".png", img.size)


def make_stamp() -> None:
    """Cap basah POS 07 sebagai sprite transparan terpisah (bukan
    bagian dari ledger): di Options, isi scroll menimpa posisi stempel
    kalau stempel menempel di tekstur kertas. Node-nya hanya tampil
    di menu utama, disembunyikan saat Options dibuka."""
    tmp = Image.new("RGBA", (220, 76), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    d.rectangle([4, 4, 215, 71], outline=REC + (220,), width=3)
    d.rectangle([10, 10, 209, 65], outline=REC + (180,), width=1)
    font = ImageFont.truetype(MONO_BOLD, 24)
    d.text((110, 38), "POS 07", font=font, fill=REC + (240,),
           anchor="mm")
    tmp = tmp.rotate(-7, expand=True, resample=Image.BICUBIC)
    tmp.save(OUT / "menu_stamp_v20.png")
    print("menu_stamp_v20.png", tmp.size)


def make_rec() -> None:
    """Dot REC: glyph polos mengikuti label REC moodboard."""
    S = 64
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for r, a in ((30, 40), (24, 70), (18, 120)):
        d.ellipse([32 - r, 32 - r, 32 + r, 32 + r], fill=REC + (a,))
    d.ellipse([32 - 13, 32 - 13, 32 + 13, 32 + 13], fill=REC + (255,))
    d.ellipse([28, 24, 33, 29], fill=BONE + (180,))
    img.save(OUT / "menu_rec_v20.png")
    print("menu_rec_v20.png", img.size)


if __name__ == "__main__":
    make_logo()
    make_ledger()
    make_buttons()
    make_stamp()
    make_rec()
