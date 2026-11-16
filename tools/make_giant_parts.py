#!/usr/bin/env python3
"""Potong ulang mata + kaki Giant dari sheet Arya (world_sheet.png).

MATA (giant_eye.png): crop rapat di rongga mata gajah depan (sheet),
bukan crop lebar v5. Mata asli cuma ~20x12 px, jadi yang bisa
diperbaiki: kulit sekitar diterangkan + kontras dinaikkan + tajam,
dan kilau yang SUDAH ADA di sumber diperkuat (bukan mata baru).
Kilau sumber ada di sheet ~(209,91); diperkuat dengan highlight
radial di titik yang sama.

KAKI (giant_foot.png): tekstur v5 DIPERTAHANKAN (kaki gajah depan,
gelap + lebar, terbukti kebaca sebagai siluet di kabut). Potongan baru
dari gajah samping sempat dicoba dan GAGAL di game, lihat catatan di
bagian kaki di bawah. Yang diperbaiki untuk kaki: STAGING + debu.
"""
from PIL import Image, ImageEnhance, ImageFilter, ImageDraw
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SHEET = os.path.join(ROOT, "assets/source/world_sheet.png")
OUT = os.path.join(ROOT, "assets/sprites")

sheet = Image.open(SHEET).convert("RGB")

# --- MATA: crop (186,70,238,120), 52x50 px, rongga TEPAT di tengah
# (rongga sheet 204-222, 88-106; blotch gelap kedua di (239,114)
# sengaja di luar crop supaya mata cuma satu). Bola mata asli di
# sheet ~(213,97) -> crop (27,27) -> skala 9x (243,243).
# Kilau = catchlight KECIL di titik itu (cahaya lampu jendela di bola
# mata basah), bukan mata baru. Posisi dicek dengan marker di gambar.
# v9 ronde 1: crop (198,82,258,128) menaruh mata di 25% kiri tekstur
# + blotch kedua ikut masuk, di game mata tidak kebaca sebagai satu
# mata; ronde 2 ini crop ulang + sprite unshaded (di game ronde 1
# mata terlalu gelap karena billboard menghadap menjauhi bulan). ---
eye = sheet.crop((196, 80, 232, 116))
# RONDE 4: crop JAUH lebih rapat, rongga mengisi ~50% frame. Ronde 3
# gagal di game bukan karena gelap (mean sudah naik) tapi karena
# rongga cuma ~35% lebar tekstur: di jendela 1,4 m rongga jadi kecil
# dan tenggelam di kulit belang-belang. Crop 36x36 px ini bikin rongga
# ~0,75 m di layar: bentuk mata langsung kebaca. Harga: tekstur makin
# soft (sumber cuma 36 px), tapi bentuk menang atas detail di sini.
# Blotch gelap kedua di luar crop (y>116 / x>232).
eye = ImageEnhance.Brightness(eye).enhance(1.80)
eye = eye.point(lambda v: int(255 * (v / 255.0) ** 0.6)) # angkat bayangan
eye = ImageEnhance.Contrast(eye).enhance(1.45)
eye = ImageEnhance.Color(eye).enhance(1.15)
eye = eye.resize((468, 468), Image.LANCZOS)
eye = ImageEnhance.Sharpness(eye).enhance(2.0)
eye = eye.filter(ImageFilter.UnsharpMask(radius=2, percent=120, threshold=2))
# Catchlight: inti padat kecil + glow HALUS (blur), bukan cincin
# konsentris (ronde 3 cincinnya kelihatan seperti target).
gx, gy = (213 - 196) * 13, (97 - 80) * 13
eye_rgba = eye.convert("RGBA")
glow = Image.new("RGBA", eye_rgba.size, (0, 0, 0, 0))
dg = ImageDraw.Draw(glow)
dg.ellipse([gx - 10, gy - 10, gx + 10, gy + 10], fill=(255, 244, 214, 200))
glow = glow.filter(ImageFilter.GaussianBlur(14))
eye_rgba = Image.alpha_composite(eye_rgba, glow)
core = Image.new("RGBA", eye_rgba.size, (0, 0, 0, 0))
dc = ImageDraw.Draw(core)
dc.ellipse([gx - 4, gy - 4, gx + 4, gy + 4], fill=(255, 250, 230, 255))
eye_rgba = Image.alpha_composite(eye_rgba, core)
eye_rgba.convert("RGB").save(os.path.join(OUT, "giant_eye.png"))
print("giant_eye.png 468x468, kilau di", (gx, gy))

# --- KAKI: DIBATALKAN, kembali ke tekstur lama (v5, kaki gajah depan).
# Potongan baru dari kaki depan gajah samping (44x136 px, 1,1 m di game,
# mean lum 66) GAGAL di game: terlalu sempit + terlalu terang, nyaris
# tidak kelihatan di kabut (v14f). Tekstur lama (120x218, mean lum 42,
# 1,87 m di game) TERBUKTI kebaca di v14: gelap + lebar = siluet jelas
# di kabut. Yang diperbaiki di v9 untuk kaki adalah STAGING-nya (telapak
# masuk jendela) + debu + tint, bukan potongannya. Jangan regenerate
# kaki dari script ini tanpa cek ulang di game. ---
# (kode di bawah ini DINONAKTIFKAN: hasilnya gagal di game, lihat
# catatan di atas. Disimpan sebagai arsip jejak percobaan.)
if False:
    foot = sheet.crop((458, 98, 502, 234))
    foot = ImageEnhance.Brightness(foot).enhance(1.20)
    foot = ImageEnhance.Contrast(foot).enhance(1.20)
    foot = foot.resize((foot.width * 4, foot.height * 4), Image.LANCZOS)
    foot = ImageEnhance.Sharpness(foot).enhance(1.5)
    # Hapus latar hitam -> transparan (lum < 22), feather 1 px.
    g = foot.convert("L")
    alpha = g.point(lambda v: 0 if v < 22 else (255 if v > 60 else int((v - 22) * 255 / 38)))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    foot_rgba = foot.convert("RGBA")
    foot_rgba.putalpha(alpha)
    foot_rgba.save(os.path.join(OUT, "giant_foot.png"))
    print("giant_foot.png", foot_rgba.size, "alpha min/max",
          alpha.getextrema())
