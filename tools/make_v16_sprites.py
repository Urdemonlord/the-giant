#!/usr/bin/env python3
"""Potong 10 elemen sheet dunia yang belum pernah jadi sprite (v16)
+ 2 varian semak, dari assets/source/world_sheet.png ke assets/sprites/.

Metode SAMA seperti potongan lama (README + tools/make_giant_parts.py):
latar hitam -> transparan dengan ambang luminansi (L<22 -> 0, L>60 -> 255,
ramp di antaranya), feather Gaussian 0.8 px, lalu autocrop ke bbox alpha>0.
Kotak potong diukur dari analisis komponen piksel non-hitam (lum>12)
atas sheet 1536x1024; dua potongan butuh mask tambahan:
- tree_big: daun pisang menyentuh batang pohon (satu komponen) -> untuk
  y>520, hanya x<=100 yang dipertahankan (batang + semak bawah).
- axe: kotak amunisi kecil di sebelahnya (x 303-366, y 851-890) -> zona
  itu di-nol-kan, gagang kapak di y itu ada di x ~245-275 jadi aman.
Jalankan dari root repo: python3 tools/make_v16_sprites.py
"""
from PIL import Image, ImageFilter
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SHEET = os.path.join(ROOT, "assets/source/world_sheet.png")
OUT = os.path.join(ROOT, "assets/sprites")

# name -> (box (x0,y0,x1,y1), [(mx0,my0,mx1,my1), ...] area yang di-nol-kan,
#          ukuran target di game (tinggi meter) untuk catatan pixel_size)
CUTS = {
    # gajah tampak belakang, baris atas sheet (komponen 603-707, 50-232)
    "elephant_back": ((603, 50, 707, 232), [], 3.6),
    # ranger tampak belakang, baris atas (komponen 935-1003, 55-302)
    "guard_back": ((935, 55, 1003, 302), [], 1.8),
    # pohon besar berdaun lebat, kiri tengah (kanopi 14-170, batang 57-92)
    "tree_big": ((14, 400, 172, 722), [(100, 520, 172, 722)], 6.5),
    # pagar kayu, kiri bawah (komponen 17-180, 722-813)
    "fence_wood": ((17, 722, 180, 813), [], 1.2),
    # pagar kawat berduri, kiri bawah (komponen 233-510, 718-824)
    "fence_barbed": ((233, 718, 510, 824), [], 1.2),
    # menara radio lampu merah, kanan bawah (komponen 1462-1526, 749-1003)
    "radio_tower": ((1462, 749, 1526, 1003), [], 14.0),
    # radio genggam, baris bawah (komponen 376-420, 836-995)
    "walkie_talkie": ((376, 836, 420, 995), [], 0.3),
    # sekop, baris bawah (komponen 464-526, 852-1013)
    "shovel": ((464, 852, 526, 1013), [], 1.2),
    # kapak bergagang panjang, baris bawah (komponen 240-343, 843-1000).
    # Mask kedua: ujung mata gergaji di kotak sebelah (x 240-275,
    # y 925-958) ikut masuk kotak potong; gagang kapak di y itu ada di
    # x ~280-305 jadi mask ini aman.
    "axe": ((240, 843, 343, 1000), [(300, 843, 343, 895), (240, 918, 276, 964)], 1.0),
    # baterai, baris bawah (komponen 94-150, 939-998)
    "battery": ((94, 939, 150, 998), [], 0.25),
    # semak varian 1 (komponen 840-942, 616-689); bush2 = semak besar
    # (1061-1212), jadi varian baru ini bush1/bush3.
    "bush1": ((840, 616, 942, 689), [], 0.6),
    "bush3": ((1199, 629, 1287, 714), [], 0.6),
}

sheet = Image.open(SHEET).convert("RGB")

for name, (box, masks, target_h) in CUTS.items():
    crop = sheet.crop(box)
    # alpha dari luminansi, sama seperti make_giant_parts.py
    g = crop.convert("L")
    alpha = g.point(lambda v: 0 if v < 22 else (255 if v > 60 else int((v - 22) * 255 / 38)))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    rgba = crop.convert("RGBA")
    rgba.putalpha(alpha)
    # mask tambahan: nol-kan alpha di zona yang bukan bagian elemen
    if masks:
        from PIL import ImageDraw
        am = alpha.copy()
        d = ImageDraw.Draw(am)
        for (mx0, my0, mx1, my1) in masks:
            d.rectangle([mx0 - box[0], my0 - box[1], mx1 - box[0], my1 - box[1]], fill=0)
        rgba.putalpha(am)
        alpha = am
    # autocrop ke bbox alpha>0
    bbox = alpha.getbbox()
    if bbox is None:
        print(f"{name}: KOSONG, skip")
        continue
    rgba = rgba.crop(bbox)
    out = os.path.join(OUT, name + ".png")
    rgba.save(out)
    px = target_h / rgba.size[1]
    print(f"{name:14s} sheet box {box} -> {rgba.size[0]}x{rgba.size[1]} px, "
          f"target {target_h} m, pixel_size {px:.4f}")
