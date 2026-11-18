#!/usr/bin/env python3
"""Ukur kehalusan tepi + grain dari screenshot v36 vs v37 (v33, Luci:
camera-systems — ukur lewat proyeksi + luminance, bukan eyeballing).

Metrik per tepi (satu scanline, arah vertikal/horizontal):
  lebar transisi 10%-90% di sekitar lompatan luminance terbesar (px).
  Makin kecil = tepi makin tajam/keras; feather + MSAA HARUS menaikkan
  angka ini sedikit (transisi lebih landai) TANPA mengaburkan bentuk.
Metrik grain: energi frekuensi tinggi = std(piksel - blur 1.5px) di
zona datar (langit malam, pita kabut menu). Makin kecil = makin halus.

Crop zoom 3x (NEAREST, jujur per-piksel) disimpan ke shots/ sebagai
bukti visual: <prefix>_<nama>_crop.png.

Jalankan: python3 tools/measure_edges_v33.py
Membaca ~/workspace/godot/shots/v36_*.png vs v37_*.png.
"""
from pathlib import Path

from PIL import Image, ImageFilter

SHOTS = Path("/home/hatch/workspace/godot/shots")

# (nama, file, x0,y0,x1,y1, arah) — arah "v": scanline vertikal di x
# tengah; "h": scanline horizontal di y tengah.
EDGES = [
    ("menu_kubah", "menu_no_save", 470, 10, 570, 130, "v"),
    ("menu_palm_kiri", "menu_no_save", 30, 40, 230, 110, "h"),
    ("menu_kusen_bawah", "menu_no_save", 600, 330, 680, 395, "v"),
    ("malam_atap", "night_dark", 650, 195, 750, 275, "v"),
    ("malam_pohon_kanan", "night_dark", 1000, 260, 1200, 340, "h"),
    ("malam_senter_pintu", "night_flash", 560, 330, 700, 430, "v"),
]
# (nama, file, box) — zona datar untuk proksi grain.
FLAT = [
    ("grain_langit_malam", "night_dark", (500, 40, 800, 120)),
    ("grain_kabut_menu", "menu_no_save", (100, 380, 500, 450)),
    ("grain_kabut_malam", "night_dark", (100, 400, 500, 500)),
]


def lum(im, x, y):
    r, g, b = im.convert("RGB").getpixel((x, y))[:3]
    return 0.299 * r + 0.587 * g + 0.114 * b


def edge_width(im, box, direction):
    """Lebar transisi 10-90% (px) di lompatan terbesar.
    Profil dirata-rata dari 9 scanline sejajar (+-4 px) supaya grain
    VHS tidak menentukan hasil (satu scanline mentah menembak
    butir grain, bukan tepinya)."""
    x0, y0, x1, y1 = box
    n = (y1 - y0) if direction == "v" else (x1 - x0)
    acc = [0.0] * n
    for off in range(-4, 5):
        if direction == "v":
            x = (x0 + x1) // 2 + off
            prof = [lum(im, x, y) for y in range(y0, y1)]
        else:
            y = (y0 + y1) // 2 + off
            prof = [lum(im, x, y) for x in range(x0, x1)]
        for i, v in enumerate(prof):
            acc[i] += v
    prof = [v / 9.0 for v in acc]
    # lompatan terbesar
    bi, bv = 0, 0.0
    for i in range(len(prof) - 1):
        d = abs(prof[i + 1] - prof[i])
        if d > bv:
            bv, bi = d, i
    if bv < 8:
        return None, round(bv, 1)
    lo = min(prof[max(0, bi - 12):bi + 1])
    hi = max(prof[bi:bi + 13])
    if hi - lo < 8:
        return None, round(bv, 1)
    t10 = lo + 0.1 * (hi - lo)
    t90 = lo + 0.9 * (hi - lo)
    # dari bi ke kiri cari <=t10, ke kanan cari >=t90 (atau sebaliknya)
    asc = prof[bi + 1] >= prof[bi]
    i10, i90 = None, None
    j = bi
    while j >= 0:
        if (prof[j] <= t10) if asc else (prof[j] >= t10):
            i10 = j
            break
        j -= 1
    j = bi + 1
    while j < len(prof):
        if (prof[j] >= t90) if asc else (prof[j] <= t90):
            i90 = j
            break
        j += 1
    if i10 is None or i90 is None:
        return None, round(bv, 1)
    return abs(i90 - i10), round(bv, 1)


def hf_energy(im, box):
    """Std (img - blur) di zona datar: proksi grain/noise."""
    crop = im.convert("L").crop(box)
    blur = crop.filter(ImageFilter.GaussianBlur(1.5))
    px = list(crop.getdata())
    pb = list(blur.getdata())
    diffs = [a - b for a, b in zip(px, pb)]
    mean = sum(diffs) / len(diffs)
    var = sum((d - mean) ** 2 for d in diffs) / len(diffs)
    return round(var ** 0.5, 2)


def zoom_crop(im, box, out, scale=3):
    crop = im.crop(box)
    crop = crop.resize((crop.width * scale, crop.height * scale),
                       Image.NEAREST)
    crop.save(out)


def main():
    print(f"{'tepi':22} {'v36 lebar':>10} {'v37 lebar':>10}  lompat v36->v37")
    for name, tag, x0, y0, x1, y1, d in EDGES:
        row = []
        for prefix in ("v36", "v37"):
            p = SHOTS / f"{prefix}_{tag}.png"
            if not p.exists():
                row.append(("—", "—"))
                continue
            im = Image.open(p)
            w, _ = edge_width(im, (x0, y0, x1, y1), d)
            row.append((w if w is not None else "—", ""))
            zoom_crop(im, (x0, y0, x1, y1),
                      SHOTS / f"{prefix}_{name}_crop.png")
        print(f"{name:22} {str(row[0][0]):>10} {str(row[1][0]):>10}")
    print()
    print(f"{'zona grain':22} {'v36 HF':>8} {'v37 HF':>8}")
    for name, tag, box in FLAT:
        vals = []
        for prefix in ("v36", "v37"):
            p = SHOTS / f"{prefix}_{tag}.png"
            if not p.exists():
                vals.append("—")
                continue
            vals.append(hf_energy(Image.open(p), box))
        print(f"{name:22} {str(vals[0]):>8} {str(vals[1]):>8}")


if __name__ == "__main__":
    main()
