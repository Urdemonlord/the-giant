#!/usr/bin/env python3
"""Aset menu v25 THE GIANT — kepala Zunisha + elemen tempat.
Sumber:
  * Kepala gajah: assets/sprites/elephant_front.png — sheet Arya
    (gajah depan, kepala + telinga + belalai + gading). Crop kepala
    (10, 0, 340, 270), grade kabut malam pucat supaya terbaca
    sebagai siluet raksasa di balik jendela. BUKAN siluet kera di
    mockup Arya (gambar 1) — yang dipakai bentuknya kepala gajah.
  * Papan "KAWASAN KUBURAN GAJAH": crop dari gambar tempat Arya
    (1000488176_6_n0hn.png, 1672x941), papan + kaki (545, 772,
    745, 941). Alpha dari luminansi (latar checkerboard terang).
  * Panel kuburan gajah: crop dari gambar tempat yang sama
    (0, 465, 700, 765) — kerangka + gading + siluet gajah jauh di
    kabut. Tepi di-feather supaya melebur ke kabut halaman.
STATUS: PLACEHOLDER — kedua gambar Arya kelihatan seperti concept
art AI-generated; semua potongan dari sana kelas placeholder,
bukan art final. Kepala gajahnya sendiri dari sheet Arya (aset
asli), tapi grade + skalanya kolosal (Zunisha) tetap placeholder.
Provenance: tools/ref/REFERENCES.md.
Jalankan: python3 tools/make_menu_head_v25.py (deterministik).
"""
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "assets" / "sprites"
SHEET2 = Path("/home/hatch/workspace/user/files/1000488176_6_n0hn.png")
FRONT = HERE.parent / "assets" / "sprites" / "elephant_front.png"


def alpha_from_lum(im: Image.Image, lo: int, hi: int) -> Image.Image:
    """Alpha dari luminansi: gelap penuh, terang hilang, ramp."""
    lum = im.convert("L")
    w, h = im.size
    lp = lum.load()
    out = Image.new("RGBA", (w, h))
    op = out.load()
    ip = im.convert("RGB").load()
    for y in range(h):
        for x in range(w):
            L = lp[x, y]
            if L <= lo:
                a = 255
            elif L >= hi:
                a = 0
            else:
                a = int(255 * (hi - L) / (hi - lo))
            op[x, y] = ip[x, y] + (a,)
    return out


def grade_fog(im: Image.Image, bright: float, cool: tuple) -> Image.Image:
    """Grade kabut malam: desaturasi + cerahkan + geser dingin."""
    g = im.convert("RGB")
    gray = g.convert("L")
    g = Image.blend(g, Image.merge("RGB", (gray, gray, gray)), 0.55)
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


def make_head() -> None:
    src = Image.open(FRONT).convert("RGBA")
    # Crop kepala: kubah y 0, telinga x 35..330, belalai tengah
    # sampai y ~270, gading menyapu ke samping. Kaki dipotong
    # (di bawah y 270) — yang kelihatan lewat jendela hanya kepala.
    head = src.crop((10, 0, 340, 270))
    # Latar sheet SUDAH transparan (alpha 0 di luar gajah) — jangan
    # diganti alpha luminansi (itu membalik: pernah bikin gajahnya
    # jadi gelap dan berlubang). Grade saja, alpha dipertahankan.
    head = head.filter(ImageFilter.GaussianBlur(1.2))
    # Siluet PUCAT melawan kabut GELAP (mockup: siluet biru-abu
    # terang lawan kabut gelap). Kabut menu L~50 — siluet GELAP
    # (ronde 2) kontrasnya NOL lawan kabut sewarna; yang terbaca
    # adalah yang lebih TERANG dari kabut. Gading tetap paling
    # terang. Ronde 1 gagal bukan karena pucat, tapi karena puff
    # kabut di (1,5, 12) menutupi belalai + jarak z 28 (75% kabut).
    # v25 ronde 3: kepala didekatkan ke z 12 + koridor pandang
    # jendela dikosongkan dari puff (main.gd).
    head = grade_fog(head, 1.45, (0.82, 0.90, 1.02))
    # Ronde 3: belalai melebur jadi blob kabut — pipi di kiri-kanan
    # belalai sama terangnya, jadi kolom belalai tidak punya tepi.
    # Gelapkan SEMUA kecuali kolom belalai (|x-155| < 32, belalai
    # di crop x 130-180) + piksel sangat terang (gading, L>=170):
    # belalai jadi SATU kolom terang lawan wajah gelap, gading
    # putih di kiri-kanannya. Satu elemen terang (unslop).
    w, h = head.size
    px = head.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if abs(x - 155) < 32 or lum >= 170:
                continue
            px[x, y] = (int(r * 0.5), int(g * 0.5), int(b * 0.5), a)
    # Ronde 6 (diukur, bukan ditebak): belalai di foto sumbernya
    # GELAP (L~34, bayangan) — grade 1,45 hanya membawanya ke
    # L~49, SAMA dengan kabut L~50, jadi kontras NOL. Preview di
    # latar hitam menipu (L 49 terbaca terang lawan hitam).
    # Angkat kolom belalai x3,0 (49 -> ~120) + zona gading x2,5,
    # supaya lawan kabut L~50 tetap terbaca setelah kabut 0,04/m
    # di z 12 (transmisi 0,62: 0,62*120+0,38*50 = 93 lawan 50).
    # Pipi tetap gelap (25) — kepala terbaca sebagai belalai +
    # gading saja (never whole + satu elemen terang).
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if abs(x - 155) < 32:
                f = 3.0
            elif (10 <= x <= 70 or 140 <= x <= 190) and y >= 140:
                f = 2.5  # zona gading (kiri + kanan, y bawah)
            else:
                continue
            px[x, y] = (min(255, int(r * f)), min(255, int(g * f)),
                        min(255, int(b * f)), a)
    head.save(OUT / "giant_head_zunisha_v25.png")
    print("giant_head_zunisha_v25.png", head.size)
    # Preview di latar KABUT (60,65,60), bukan hitam — latar hitam
    # menipu kecerahan (pelajaran ronde 6).
    bg = Image.new("RGB", head.size, (60, 65, 60))
    bg.paste(head, (0, 0), head)
    bg.save("/tmp/head_v25_preview.png")
    print("preview /tmp/head_v25_preview.png")


def make_sign() -> None:
    sheet = Image.open(SHEET2).convert("RGB")
    sign = sheet.crop((545, 772, 745, 941))
    sign = alpha_from_lum(sign, 160, 205)
    sign = grade_fog(sign, 0.85, (0.95, 0.97, 1.0))
    sign.save(OUT / "menu_sign_graveyard_v25.png")
    print("menu_sign_graveyard_v25.png", sign.size)
    bg = Image.new("RGB", sign.size, (16, 22, 26))
    bg.paste(sign, (0, 0), sign)
    bg.save("/tmp/sign_v25_preview.png")
    print("preview /tmp/sign_v25_preview.png")


def feather_edges(im: Image.Image, depth: int = 30) -> None:
    """Alpha luruh ke tepi supaya panel persegi melebur ke kabut."""
    w, h = im.size
    a = im.getchannel("A")
    px = a.load()
    for y in range(h):
        for x in range(w):
            d = min(x, w - 1 - x, y, h - 1 - y)
            if d < depth:
                f = (d + 1) / (depth + 1)
                px[x, y] = int(px[x, y] * f)
    im.putalpha(a)


def defog_checker(im: Image.Image) -> Image.Image:
    """Langit panel kuburan di sheet-nya SENDIRI checkerboard
    (latar transparan yang ke-render sebagai kotak-kotak).
    Ganti piksel terang (L > 190) dengan kabut halus; yang
    175-190 di-blend. Gajah jauh (L < 170) dan pepohonan gelap
    tidak tersentuh."""
    fog = (172, 180, 184)
    rgb = im.convert("RGB")
    lum = rgb.convert("L")
    w, h = rgb.size
    lp = lum.load()
    rp = rgb.load()
    out = Image.new("RGBA", (w, h))
    op = out.load()
    ap = im.getchannel("A").load()
    for y in range(h):
        for x in range(w):
            L = lp[x, y]
            r, g, b = rp[x, y]
            if L > 190:
                r, g, b = fog
            elif L > 175:
                t = (L - 175) / 15.0
                r = int(r * (1 - t) + fog[0] * t)
                g = int(g * (1 - t) + fog[1] * t)
                b = int(b * (1 - t) + fog[2] * t)
            op[x, y] = (r, g, b, ap[x, y])
    return out.filter(ImageFilter.GaussianBlur(0.8))


def make_skeleton() -> None:
    sheet = Image.open(SHEET2).convert("RGB")
    # Crop mulai y 478 (bukan 465): tepi atas panel bergelombang,
    # di y 465-478 masih ada piksel checkerboard latar sheet.
    # v25 ronde 4: crop DIPERSempit ke kerangka (x 80-470,
    # y 500-700) — panel lebar sebelumnya membuat kerangka kecil
    # di tengah panel dan papan di depannya menutupi kerangka.
    # Sekarang kerangka MENGISI panel; gajah jauh di kabut tetap
    # di belakangnya (y ~520-600).
    panel = sheet.crop((80, 500, 470, 700)).convert("RGBA")
    panel = defog_checker(panel)
    feather_edges(panel, 30)
    panel = grade_fog(panel, 0.8, (0.88, 0.95, 1.0))
    panel = panel.filter(ImageFilter.GaussianBlur(0.8))
    panel.save(OUT / "menu_skeleton_v25.png")
    print("menu_skeleton_v25.png", panel.size)
    bg = Image.new("RGB", panel.size, (16, 22, 26))
    bg.paste(panel, (0, 0), panel)
    bg.save("/tmp/skel_v25_preview.png")
    print("preview /tmp/skel_v25_preview.png")


if __name__ == "__main__":
    make_head()
    make_sign()
    make_skeleton()
