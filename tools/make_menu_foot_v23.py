#!/usr/bin/env python3
"""Kaki Giant menu v23 — potongan dari FOTO ASLI (bukan sprite sheet).
Sumber: foto kaki gajah di lumpur, sudut rendah (Wetu), yang sama
dengan Tile K moodboard v2 — ref-foot-mud.webp, diunduh 2026-11-16
lewat image-search. Provenance: tools/ref/REFERENCES.md.
Alasan: giant_foot.png (crop kaki gajah depan sheet Arya) terbukti
kebaca BATANG POHON di jendela menu v22 — kolom berkerut seragam,
tanpa telapak, tanpa kuku. Foto ini punya yang tidak dimiliki
sprite itu: telapak melebar + kuku kaki di depan bawah + lumpur
yang menempel di telapak. Dipakai HANYA di backdrop menu (kaki di
jendela); event kaki 03:30 di permainan tetap pakai giant_foot.png.
Teknik: crop vertikal kaki depan + alpha dari luminansi (latar
foto blur terang, kaki gelap) + grade malam (gelap, desat hijau-
abu, sesuai palet). Seed tetap: output deterministik, tidak ada
random. Nol aset AI, nol gambar generate.
"""
from PIL import Image, ImageEnhance

SRC = "/home/hatch/workspace/your_files/the-giant-moodboard/.src/media/ref-foot-mud.webp"
OUT = "assets/sprites/giant_foot_photo_v23.png"
PREVIEW = "/tmp/foot_v23_preview.png"

# Crop: kaki depan + telapak. Kaki kedua di belakang (x > 700)
# dibuang; lumpur bawah (y > 640) dibuang, telapak bawah ada di
# y ~600 (kuku depan bawah di x ~330-480, y ~480-600).
BOX = (230, 0, 700, 640)

im = Image.open(SRC).convert("RGB").crop(BOX)
w, h = im.size
lum = im.convert("L")
px = im.load()
lx = lum.load()
out = Image.new("RGBA", (w, h))
op = out.load()
# Alpha dari luminansi: kaki gelap (<95) penuh, latar blur terang
# (>150) hilang, ramp di antaranya supaya tepi kerut tidak keras.
# Ambang atas 150 (bukan 175): latar di antara kedua kaki + tepi
# kaki kedua yang terang ikut hilang, bukan jadi noda abu-abu.
# Rim hangat tipis di tepi kaki ikut pudar — disengaja, rim diganti
# tint terang sprite di main.gd.
for y in range(h):
    for x in range(w):
        L = lx[x, y]
        if L <= 95:
            a = 255
        elif L >= 150:
            a = 0
        else:
            a = int(255 * (150 - L) / 55)
        op[x, y] = px[x, y] + (a,)

# Grade malam: gelap + desat ke hijau-abu sakit (palet moodboard).
grade = ImageEnhance.Brightness(out).enhance(0.62)
g = grade.convert("RGB")
gp = g.load()
ap = grade.split()[3]
for y in range(h):
    for x in range(w):
        r, gg, b = gp[x, y]
        l = int(0.299 * r + 0.587 * gg + 0.114 * b)
        r = int(l * 0.92 + r * 0.0) if False else int(r * 0.55 + l * 0.92 * 0.45)
        gg = int(gg * 0.55 + l * 1.0 * 0.45)
        b = int(b * 0.55 + l * 0.88 * 0.45)
        gp[x, y] = (min(r, 255), min(gg, 255), min(b, 255))
grade = g.convert("RGBA")
grade.putalpha(ap)
grade.save(OUT)
print("saved", OUT, grade.size)

# Preview: di atas latar nyaris hitam (seperti jendela malam).
bg = Image.new("RGB", (w, h), (8, 10, 8))
bg.paste(grade, (0, 0), grade)
bg.save(PREVIEW)
print("preview", PREVIEW)
