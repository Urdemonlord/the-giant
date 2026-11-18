#!/usr/bin/env python3
## Generator halaman buku menu THE GIANT v24 (Opsi B, diegetic desk).
##
## v24 MENGGANTIKAN v22 untuk halaman buku (make_menu_book_v22.py
## tetap ada sebagai riwayat, jangan dijalankan lagi untuk halaman —
## ia menimpa file v24). Yang berubah, dari kritik desain 2026-11-18:
##
## (3a) Lipatan gelap diagonal di halaman kanan menabrak teks
##      Continue/Options (terbukti di zoom screenshot v26). Zona
##      teks kini DIRATAKAN dulu (blur + angkat ke median lokal,
##      tepi feather) sebelum teks di-bake, jadi tidak ada lipatan
##      gelap yang tersisa di bawah satu pun baris tulisan.
## (3b) Teks TIDAK LAGI Label3D yang ditempel rata di atas kertas
##      (terlihat seperti teks UI digital). Semua teks statis di-BAKE
##      ke dalam tekstur halaman dengan MULTIPLY tinta gelap — serat
##      kertas kelihatan menembus huruf, seperti ketikan mesin tik
##      sungguhan. Yang tetap Label3D hanya sub-teks dinamis
##      ("22:00, Sanity 100") karena isinya berubah-ubah.
##      Kertas persegi di-squash vertikal 0,6875 di 3D (lihat
##      main_menu.gd), jadi huruf di tekstur harus 1,4545x lebih
##      TINGGI dari lebar normalnya — digambar di layer kecil
##      dengan font normal lalu di-stretch HANYA vertikal (lihat
##      text_mask). Pemetaan dunia -> tekstur (dari
##      rotasi SpriteRegistry.flat: -90 X lalu 180 Z):
##        U = (x_kanan_halaman - x) / 0,96 * 1024
##        V = (1,61 - z) / 0,66 * 1024
##      (V=0 = tepi jauh halaman, U=0 = sisi +x halaman.)
##      Logo "THE GIANT" (menu_logo_v20) ikut di-bake dengan tinta
##      gelap dari mask alpha-nya saja — ghost merah/biru bawaan
##      sprite logo (yang bikin judul kelihatan ber-CA) hilang,
##      karena warnanya tidak dipakai, hanya bentuk hurufnya.
##      Garis merah di bawah judul juga di-bake (dulu quad 3D).
## (1)  Lentera pindah ke pojok kiri meja (kode, main.gd) — bukan
##      di generator. (2) CA shader sudah 0 sejak v23, tidak ada
##      yang diubah di sini; pinggiran merah yang tersisa di v26
##      hanya ghost bawaan logo, yang dihapus oleh baking ini.
## (4)  Jendela + siluet (kode, main.gd + balance.gd) — bukan di sini.
##
## REFERENSI PER SPRITE (sama seperti v20/v22, jangan ganti sumber):
##   menu_book_page_l_v24.png — halaman kiri (judul):
##     Foto asli: parchment_vecteezy.jpg di tools/ref/ (Vecteezy
##     free photo 57329614, "distressed paper texture", 3497x1960).
##     Crop tengah (300,250,1324,1274), grade TERANG (darken 0.88,
##     green 1.02). Teks di-bake multiply tinta gelap.
##   menu_book_page_r_v24.png — halaman kanan, Continue AKTIF:
##     Base = halaman kiri di-flip horizontal (satu sumber, kreasi
##     beda, seperti v22). Empat baris menu di-bake multiply.
##   menu_book_page_r_disabled_v24.png — halaman kanan, Continue MATI:
##     Sama, tapi Continue tinta redup 0,22 + garis coret + sub
##     "no record on file" di-bake. Ditukar saat runtime oleh
##     main_menu.gd _refresh_continue().
##   menu_form_page.png — lembar formulir Options (sama seperti v22).
##
## STATUS: masih kelas PLACEHOLDER (aturan aset Arya): kertas foto stok
## + teks typeset, bukan art final gambar tangan.
##
## Jalankan: python3 tools/make_menu_book_v24.py
## (seed tetap = hasil tetap; referensi di tools/ref/)

import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
REF = HERE / "ref"
OUT = HERE.parent / "assets" / "sprites"
FONT = HERE.parent / "assets" / "fonts" / "DejaVuSansMono-Bold.ttf"
LOGO = HERE.parent / "assets" / "sprites" / "menu_logo_v20.png"
random.seed(24)

PARCHMENT = REF / "parchment_vecteezy.jpg"
GRAIN_TILE = REF / "grain_mb000.png"

# Tinta (0..255), sama dengan konstanta main_menu.gd.
INK = (33, 26, 18)          # 0.13, 0.10, 0.07 — tinta aktif
INK_DISABLED = (56, 48, 41)  # 0.22, 0.19, 0.16 — tinta baris mati
INK_BODY = (56, 48, 38)      # 0.22, 0.19, 0.15 — tinta isi/sub
INK_RULE = (115, 33, 20)     # 0.45, 0.13, 0.08 — garis merah tinta

# Kertas di-squash vertikal 0,6875 di 3D: huruf di tekstur harus
# 1,4545x lebih tinggi dari lebar normalnya (lihat text_mask).
SQUASH = 0.6875
VSTRETCH = 1.0 / SQUASH        # 1,4545

# Pemetaan dunia -> tekstur (halaman 0,96 x 0,66 m).
PAGE_W_M = 0.96
PAGE_D_M = 0.66
Z_FAR = 1.61


def u_of(x: float, x_right: float) -> float:
    return (x_right - x) / PAGE_W_M * 1024.0


def v_of(z: float) -> float:
    return (Z_FAR - z) / PAGE_D_M * 1024.0


def px_per_m() -> float:
    return 1024.0 / PAGE_W_M


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
    desaturasi ringan, sedikit gelapkan, geser hangat."""
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


def flatten_zones(img: Image.Image, zones) -> None:
    """Ratakan zona teks: blur kuat + angkat SEDIKIT ke median lokal,
    tepi feather lebar — lipatan gelap diagonal tidak boleh tersisa
    di bawah satu pun baris tulisan (kritik 3a), tapi zonanya sendiri
    tidak boleh kelihatan sebagai tempelan terang (angkat dijaga
    ringan, 0,15; zona mengikuti lebar teks, bukan selebar halaman).
    Grain diterapkan sesudahnya, jadi kertas tetap terasa kertas."""
    w, h = img.size
    for (cx, cy, zw, zh) in zones:
        x0 = max(0, int(cx - zw / 2))
        y0 = max(0, int(cy - zh / 2))
        x1 = min(w, int(cx + zw / 2))
        y1 = min(h, int(cy + zh / 2))
        region = img.crop((x0, y0, x1, y1)).convert("RGB")
        blurred = region.filter(ImageFilter.GaussianBlur(18))
        # Median lokal per kanal.
        px = list(region.getdata())
        med = tuple(sorted(c[i] for c in px)[len(px) // 2] for i in range(3))
        flat = Image.blend(blurred, Image.new("RGB", region.size, med), 0.15)
        # Mask feather lebar: ratakan penuh di tengah, luruh ke tepi.
        m = Image.new("L", (w, h), 0)
        md = ImageDraw.Draw(m)
        md.rectangle([x0, y0, x1, y1], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(40))
        base = img.convert("RGB")
        base.paste(flat, (x0, y0), m.crop((x0, y0, x1, y1)))
        img.paste(base.convert("RGBA"), (0, 0))


def zone_for(text: str, u: float, v: float, em_px: float,
             pad_x: int = 50, pad_y: int = 35):
    """Zona rata mengikuti lebar teks (+ padding), bukan selebar
    halaman — supaya tidak kelihatan seperti strip tempelan terang.
    Tinggi mengikuti tinggi huruf yang sudah di-stretch vertikal."""
    w = len(text) * 0.602 * em_px + pad_x * 2
    h = em_px * VSTRETCH + pad_y * 2
    return (u, v, w, h)


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
            h1 = (x * 73 + y * 131) % 11
            if d_edge < h1:
                px[x, y] = 0
            elif d_edge < depth:
                px[x, y] = int(255 * (d_edge - h1 + 1) / (depth - h1 + 1))
    img.putalpha(a)


def text_mask(items) -> Image.Image:
    """Mask teks 1024x1024. items: (teks, u_tengah, v_tengah, font_em_px).
    Kertas di-squash vertikal 0,6875 di 3D, jadi huruf harus
    1,4545x lebih TINGGI dari lebar normalnya di tekstur — tapi
    LEBARNYA harus tetap normal (advance font). Menggambar dengan
    font 1,4545x lebih besar salah: lebar ikut membesar dan teks
    terpotong tepi (bug ronde 1). Caranya: gambar tiap baris di
    layer kecil dengan font ukuran normal, lalu stretch layer itu
    HANYA vertikal 1,4545x, lalu tempel di tengah (u, v)."""
    mask = Image.new("L", (1024, 1024), 0)
    for (text, u, v, em_px) in items:
        f = ImageFont.truetype(str(FONT), int(round(em_px)))
        probe = ImageDraw.Draw(Image.new("L", (8, 8)))
        bbox = probe.textbbox((0, 0), text, font=f, anchor="mm")
        w = bbox[2] - bbox[0] + 8
        h = bbox[3] - bbox[1] + 8
        tmp = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(tmp)
        d.text((w // 2, h // 2), text, font=f, fill=255, anchor="mm")
        stretched = tmp.resize((w, round(h * VSTRETCH)), Image.LANCZOS)
        mask.paste(stretched, (int(round(u - stretched.width / 2)),
                               int(round(v - stretched.height / 2))), stretched)
    return mask


def rect_mask(rects) -> Image.Image:
    """Mask persegi panjang (garis/corot) langsung di 1024x1024.
    rects: (u_tengah, v_tengah, lebar_px, tinggi_px)."""
    m = Image.new("L", (1024, 1024), 0)
    d = ImageDraw.Draw(m)
    for (u, v, w, h) in rects:
        d.rectangle([u - w / 2, v - h / 2, u + w / 2, v + h / 2], fill=255)
    return m


def bake_ink(img: Image.Image, mask: Image.Image, ink) -> None:
    """Tinta multiply: piksel kertas * warna tinta, di mana mask
    putih; kertas asli di tempat lain. Serat kertas menembus huruf."""
    rgb = img.convert("RGB")
    solid = Image.new("RGB", img.size, ink)
    inked = ImageChops.multiply(rgb, solid)
    out = Image.composite(inked, rgb, mask)
    img.paste(out.convert("RGBA"), (0, 0))


def logo_mask() -> Image.Image:
    """Mask logo dari alpha sprite menu_logo_v20 (920x240): hanya
    bentuk huruf yang dipakai (ambang 60 buang ghost paling samar),
    warnanya TIDAK dipakai — ghost merah/biru bawaan logo hilang,
    yang tinggal huruf tinta. Di-stretch vertikal 1,4545 dan
    diposisikan di tengah halaman kiri (U 512, V 372)."""
    logo = Image.open(LOGO).convert("RGBA")
    alpha = logo.getchannel("A").point(lambda p: 255 if p >= 60 else 0)
    w = 917
    h = round(240 * (917 / 920) * VSTRETCH)  # 348
    m = alpha.resize((w, h), Image.LANCZOS)
    out = Image.new("L", (1024, 1024), 0)
    out.paste(m, (512 - w // 2, 372 - h // 2))
    return out


def em(label3d_font_size: int) -> float:
    """Label3D font_size F, pixel_size 0,0022 -> tinggi em px tekstur."""
    return label3d_font_size * 0.0022 * px_per_m()


def make_book_pages() -> None:
    photo = Image.open(PARCHMENT).convert("RGB")
    crop = photo.crop((300, 250, 1324, 1274))
    left = grade_paper_light(crop, 1024, 1024, darken=0.88, green=1.02)
    # Zona teks halaman kiri (U,V) — mengikuti lebar tiap baris
    # teks. Logo TIDAK diratakan: hurufnya tebal, lipatan di
    # belakangnya tidak mengganggu keterbacaan, dan zonanya yang
    # selebar halaman justru kelihatan seperti tempelan (bug ronde
    # 2). Garis merah juga tidak diratakan (tebal, tidak butuh).
    zones_l = [
        zone_for("Buku jaga, Pos 07", 512, 620, em(30)),
        zone_for("Taman Nasional", 512, 853, em(30)),
        zone_for("Malayunesia.", 512, 962, em(30)),
    ]
    flatten_zones(left, zones_l)
    # Teks tinta gelap halaman kiri.
    bake_ink(left, text_mask([
        ("Buku jaga, Pos 07", 512, 620, em(30)),
        ("Taman Nasional", 512, 853, em(30)),
        ("Malayunesia.", 512, 962, em(30)),
    ]), INK)
    bake_ink(left, logo_mask(), INK)
    bake_ink(left, rect_mask([(512, 731, 917, 22)]), INK_RULE)
    torn_edges(left)
    apply_sampled_grain(left, strength=5)
    left.save(OUT / "menu_book_page_l_v24.png")
    print("menu_book_page_l_v24.png", left.size)

    # Halaman kanan: base polos dari crop yang sama, di-flip
    # horizontal (satu sumber, kreasi beda, seperti v22) — lalu
    # teks kanan di-bake di atasnya. (Tidak memakai flip halaman
    # kiri yang sudah berteks: teksnya ikut terbalik.)
    right_clean = grade_paper_light(crop, 1024, 1024, darken=0.88, green=1.02)
    right_clean = right_clean.transpose(Image.FLIP_LEFT_RIGHT)
    zones_r = [
        zone_for("Start", 512, 202, em(40)),
        zone_for("Continue", 512, 450, em(40)),
        zone_for("no record on file", 512, 566, em(22)),
        zone_for("Options", 512, 698, em(40)),
        zone_for("Exit", 512, 916, em(40)),
    ]
    flatten_zones(right_clean, zones_r)
    rows = [
        ("Start", 512, 202, em(40)),
        ("Continue", 512, 450, em(40)),
        ("Options", 512, 698, em(40)),
        ("Exit", 512, 916, em(40)),
    ]
    # --- Varian aktif (Continue hidup). ---
    active = right_clean.copy()
    bake_ink(active, text_mask(rows), INK)
    torn_edges(active)
    apply_sampled_grain(active, strength=5)
    active.save(OUT / "menu_book_page_r_v24.png")
    print("menu_book_page_r_v24.png", active.size)
    # --- Varian mati (Continue mati: tinta redup + coret + sub). ---
    disabled = right_clean.copy()
    bake_ink(disabled, text_mask([
        ("Start", 512, 202, em(40)),
        ("Options", 512, 698, em(40)),
        ("Exit", 512, 916, em(40)),
    ]), INK)
    bake_ink(disabled, text_mask([
        ("Continue", 512, 450, em(40)),
    ]), INK_DISABLED)
    bake_ink(disabled, rect_mask([(512, 450, 853, 19)]), INK)
    bake_ink(disabled, text_mask([
        ("no record on file", 512, 566, em(22)),
    ]), INK_BODY)
    torn_edges(disabled)
    apply_sampled_grain(disabled, strength=5)
    disabled.save(OUT / "menu_book_page_r_disabled_v24.png")
    print("menu_book_page_r_disabled_v24.png", disabled.size)


def make_form_page() -> None:
    photo = Image.open(PARCHMENT).convert("RGB")
    crop = photo.crop((1800, 900, 2568, 1924))
    img = grade_paper_light(crop, 768, 1024, darken=0.92, green=1.0)
    # Tenangkan tengah (sama seperti v22).
    w, h = img.size
    region = img.crop((90, 90, w - 90, h - 90))
    region = region.filter(ImageFilter.GaussianBlur(9))
    img.paste(region, (90, 90))
    apply_sampled_grain(img, strength=4)
    img.save(OUT / "menu_form_page.png")
    print("menu_form_page.png", img.size)


if __name__ == "__main__":
    make_book_pages()
    make_form_page()
