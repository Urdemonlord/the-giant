#!/usr/bin/env python3
"""Grade keluarga v28 THE GIANT — SATU grade untuk semua sprite.

Diagnosis (diukur dari screenshot menu v29, 1280x720):
  kabut di jendela L36, pohon L19, papan L50, kepala Zunisha L71-96.
  Kepala 35-60 poin LEBIH TERANG dari kabutnya sendiri — itu yang
  bikin ia terbaca seperti gambar ditempel, bukan siluet di kabut.
  Penyebab: tint runtime tersebar sebagai literal (kepala 1.2-1.3,
  papan 0.9, puff 0.62/0.68/0.58, wajah papan 0.55, pohon 0.8, props
  0.85, darah 1.6) + grade PNG v26 yang mencerahkan kepala 2.2-2.7x.

Perbaikan (Luci: create-game-assets — satu family, normalisasi
deterministik, iterasi di aset sumber):
  1. Kepala v28: DIBALIK dari v26. Target AKHIR (setelah kabut menu,
     transmisi ~0.53 di z 12,5, kabut L36): kubah ~48, telinga ~44,
     belalai ~52, gading ~68. Mundur ke PNG: kubah ~58, telinga ~51,
     belalai ~66, gading ~96 (PNG_L = (target - 0.47*36) / 0.53).
     Pengali zona dari luminansi sumber (kubah 54, telinga 47/42,
     belalai 51, gading 75/67): 1.1 / 1.1 / 1.3 / 1.35 — SETENGAH
     dari v26 (2.2/2.2/2.7/2.55). Runtime tint kepala juga turun
     1.2-1.3 -> GRADE_FAR_TINT (Balance), jadi PNG-lah grade-nya.
     TUNING v28 (screenshot v31): pengali pertama terlalu gelap
     (kubah L39, belalai L36 = kabut L36, kepala hampir tenggelam),
     naik +0.2 jadi 1.3 / 1.3 / 1.5 / 1.55 — target akhir kubah
     ~50, telinga ~43, belalai ~49, gading ~57, masih jauh di bawah
     v29 (71-96).
  2. Papan kuburan v28: PNG v25 x0.85 + geser dingin (L50 -> ~44).
  3. Pohon (tree_tall/palm/dead/big): feather tepi saja, kecerahan
     TIDAK diubah (PNG-nya sudah gelap, L~19 di frame).
  4. Props area generator (generator/chainsaw/barrels/sacks/
     crate_low/crate_tall): PNG x0.72 + desat dingin — di shot
     v30_path_dark mereka menyala samar di gelap (sprite unshaded
     x tint 1.0, kabut hampir tidak menjangkau jarak dekat).
     Darah TIDAK disentuh (aksen merah, satu-satunya).
  5. contact_shadow.png baru: elips radial gelap untuk bayangan
     kontak di bawah generator/papan/gerbang (main.gd).

Sumber kepala: assets/sprites/elephant_front.png (366x398) — sel
dari sheet Arya (1536x1024). TIDAK ADA sumber yang lebih besar:
crop v26 350x270 sudah hampir selebar selnya. Upscale 2x Lanczos
di sini hanya menghaluskan tepi, BUKAN menambah detail — batas
resolusi ini jujur dicatat di README + REFERENCES.md.

Feather (create-game-assets gotcha halo): alpha di-blur Gaussian
lalu warna tepi di-bleed ke piksel transparan, supaya tidak ada
fringe terang/gelap saat sprite di atas latar kontras.

File baru berversi: giant_head_zunisha_v28.png, menu_sign_graveyard_v28.png,
contact_shadow.png. Pohon + props di-grade DI TEMPAT (deterministik,
generator ini sumbernya; kalau make_v16_sprites.py di-run ulang,
jalankan grade ini lagi sesudahnya).

Jalankan: python3 tools/grade_family_v28.py (deterministik).
"""
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

HERE = Path(__file__).resolve().parent
SPR = HERE.parent / "assets" / "sprites"


def zone_lum(im: Image.Image, box) -> int:
    """Rata-rata L piksel opak di kotak (x0, y0, x1, y1)."""
    px = im.load()
    vals = []
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            r, g, b, a = px[x, y]
            if a > 10:
                vals.append(int(0.299 * r + 0.587 * g + 0.114 * b))
    return sum(vals) // len(vals) if vals else 0


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


def feather_alpha(im: Image.Image, radius: float) -> Image.Image:
    """Lembutkan tepi alpha + bleed warna tepi ke piksel transparan
    (anti-halo saat sprite di atas latar kontras)."""
    a = im.getchannel("A").filter(ImageFilter.GaussianBlur(radius))
    # Bleed: warna RGB di-blur, lalu dipakai di mana alpha kecil.
    rgb = im.convert("RGB").filter(ImageFilter.GaussianBlur(radius))
    out = Image.merge("RGBA", (*rgb.split(), a))
    return out


def make_head() -> None:
    src = Image.open(SPR / "elephant_front.png").convert("RGBA")
    print("head source:", src.size)
    head = src.crop((0, 0, 350, 270))
    head = head.filter(ImageFilter.GaussianBlur(1.0))
    head = grade_fog(head, 1.0, (0.85, 0.92, 1.02))
    w, h = head.size
    px = head.load()
    # Zona (koordinat crop 350x270, sama dengan v26): gading dulu,
    # lalu belalai, telinga, dasar kubah/wajah.
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if ((5 <= x <= 75 and y >= 140)
                    or (175 <= x <= 200 and y >= 130)) and lum >= 30:
                f = 1.55  # gading: paling terang, tapi bukan garis putih
            elif abs(x - 152) < 24 and y >= 55:
                f = 1.5  # belalai
            elif (35 <= x <= 130 or 200 <= x <= 330) and 20 <= y <= 165:
                f = 1.3  # telinga
            else:
                f = 1.3  # kubah + wajah
            px[x, y] = (min(255, int(r * f)), min(255, int(g * f)),
                        min(255, int(b * f)), a)
    # Upscale 2x Lanczos (haluskan tepi di skala 20 m; BUKAN detail
    # baru — sumber tetap 350 px) + feather tepi.
    head = head.resize((700, 540), Image.LANCZOS)
    head = feather_alpha(head, 2.0)
    head.save(SPR / "giant_head_zunisha_v28.png")
    print("giant_head_zunisha_v28.png", head.size,
          "zona L kubah/telinga/belalai/gading (koordinat 700x540):",
          zone_lum(head, (240, 20, 400, 140)),
          zone_lum(head, (80, 50, 250, 320)),
          zone_lum(head, (260, 110, 350, 540)),
          zone_lum(head, (10, 280, 150, 520)))


def make_sign() -> None:
    src = Image.open(SPR / "menu_sign_graveyard_v25.png").convert("RGBA")
    print("sign source:", src.size)
    sign = grade_fog(src, 0.85, (0.9, 0.95, 1.0))
    sign = feather_alpha(sign, 2.0)
    sign.save(SPR / "menu_sign_graveyard_v28.png")
    print("menu_sign_graveyard_v28.png", sign.size)


def feather_trees() -> None:
    for name in ["tree_tall", "tree_palm", "tree_dead", "tree_big"]:
        p = SPR / (name + ".png")
        im = Image.open(p).convert("RGBA")
        out = feather_alpha(im, 2.0)
        out.save(p)
        print("feathered", name, im.size)


def grade_props() -> None:
    for name in ["generator", "chainsaw", "barrels", "sacks",
                 "crate_low", "crate_tall"]:
        p = SPR / (name + ".png")
        im = Image.open(p).convert("RGBA")
        before = zone_lum(im, (0, 0, im.size[0], im.size[1]))
        out = grade_fog(im, 0.72, (0.9, 0.95, 1.0))
        out = feather_alpha(out, 1.0)
        out.save(p)
        after = zone_lum(out, (0, 0, out.size[0], out.size[1]))
        print(f"graded {name}: mean L {before} -> {after}")


def make_contact_shadow() -> None:
    w, h = 256, 128
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y in range(h):
        for x in range(w):
            dx = (x - w / 2) / (w / 2)
            dy = (y - h / 2) / (h / 2)
            d = min(1.0, (dx * dx + dy * dy) ** 0.5)
            a = int(150 * max(0.0, 1.0 - d) ** 1.6)
            px[x, y] = (0, 0, 0, a)
    im.save(SPR / "contact_shadow.png")
    print("contact_shadow.png", im.size)


if __name__ == "__main__":
    make_head()
    make_sign()
    feather_trees()
    grade_props()
    make_contact_shadow()
    print("grade_family_v28 OK")
