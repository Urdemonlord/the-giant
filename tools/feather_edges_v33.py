#!/usr/bin/env python3
"""Feather tepi alpha semua sprite THE GIANT (v33, Luci: create-game-assets).

Latar: screenshot v36 kasar — siluet pohon/patung bergerigi. Penyebab:
tepi alpha hasil potong sheet keras (transisi 0->255 dalam 1 px), tanpa
mipmap di impor (file .import TIDAK masuk git, jadi mipmap tidak bisa
dikirim lewat repo — blur di-bake ke PNG adalah pengganti yang awet),
tanpa MSAA (diurus di project.godot, bukan di sini).

v28 sudah feather: giant_head_zunisha_v28, menu_sign_graveyard_v28,
tree_tall/palm/dead/big, generator/chainsaw/barrels/sacks/crate_low/
crate_tall — file-file itu DI-SKIP di sini supaya tidak double-proses.
fog_puff + contact_shadow sudah radial lembut — di-skip.
elephant_front adalah sel MASTER untuk make_head() — di-skip supaya
rebuild kepala nanti tidak mewarisi blur.
File yang tidak dipakai lagi (giant_foot, giant_head v25/v26,
menu_giant_v21, menu_skeleton_v25) di-skip supaya diff tetap kecil.

Tier (radius Gaussian blur):
  FAR  2.0 — siluet jauh di kabut: gajah, menara, gerbang, pagar, gubuk.
  MID  1.5 — makhluk + semak + bukti logging di halaman.
  NEAR 1.0 — prop dekat/meja: RGB ikut blur tipis (baked minification).
  TEXT alpha-only 1.0 — tekstur berteks (buku, papan, bar): RGB TIDAK
         disentuh supaya huruf tidak blur, cuma alpha yang dilembutkan.

feather_alpha (blur RGB + alpha + bleed) dipakai untuk FAR/MID/NEAR;
untuk TEXT hanya alpha yang di-blur.

Idempotent-aman dalam praktik: skrip ini jalan SATU KALI dari state
git HEAD (e604473). Jangan di-run ulang tanpa restore dari git dulu —
blur kedua akan melebarkan tepi lagi (efek kecil, tapi tetap drift).

Jalankan: python3 tools/feather_edges_v33.py  (dari root repo)
"""
import sys
from pathlib import Path

from PIL import Image, ImageFilter

SPR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

FAR = ["elephant_back", "elephant_shadow", "elephant_side", "watchtower",
       "radio_tower", "tower_tall", "gate", "fence_wood", "fence_barbed",
       "guard_hut"]
MID = ["guard_front", "guard_back", "hunter", "hunter_rifle",
       "poacher_mask", "poacher_ghost", "giant_eye",
       "giant_foot_photo_v23", "bush1", "bush2", "bush3", "tusks",
       "stump", "log", "rocks", "snare", "footprint", "blood"]
NEAR = ["lantern", "radio", "logbook", "meter", "door", "axe", "battery",
        "shovel", "walkie_talkie", "banana"]
TEXT = ["menu_book_page_l_v24", "menu_book_page_r_v24",
        "menu_book_page_r_disabled_v24", "menu_book_page_l_v25",
        "menu_book_page_r_v25", "menu_book_page_r_disabled_v25",
        "menu_sign_graveyard_v25", "sign_park", "sign_no_elephant",
        "sign_no_elephant2", "sign_no_logging", "menu_bar_start_v25",
        "menu_bar_continue_v25", "menu_bar_options_v25",
        "menu_bar_exit_v25", "menu_ledger_v20", "menu_ledger_v21",
        "menu_stamp_v20", "menu_rec_v20", "menu_btn_v20",
        "menu_btn_v20_hover", "menu_btn_v20_pressed", "menu_form_page"]
SKIP = ["giant_head_zunisha_v28", "menu_sign_graveyard_v28",
        "tree_tall", "tree_palm", "tree_dead", "tree_big",
        "generator", "chainsaw", "barrels", "sacks", "crate_low",
        "crate_tall", "fog_puff", "contact_shadow", "elephant_front",
        "giant_foot", "giant_head_zunisha_v25", "giant_head_zunisha_v26",
        "menu_giant_v21", "menu_skeleton_v25"]


def transition_share(im: Image.Image) -> float:
    """Persen piksel alpha di zona transisi (8..247): proksi kehalusan tepi.
    0% = tepi keras 1 px; makin besar = transisi makin lebar/lembut."""
    a = im.getchannel("A")
    px = a.load()
    w, h = a.size
    trans = 0
    total = 0
    for y in range(h):
        for x in range(w):
            v = px[x, y]
            total += 1
            if 8 < v < 247:
                trans += 1
    return 100.0 * trans / max(1, total)


def feather_full(im: Image.Image, radius: float) -> Image.Image:
    """Blur alpha + bleed warna tepi (sama seperti v28)."""
    a = im.getchannel("A").filter(ImageFilter.GaussianBlur(radius))
    rgb = im.convert("RGB").filter(ImageFilter.GaussianBlur(radius))
    return Image.merge("RGBA", (*rgb.split(), a))


def feather_alpha_only(im: Image.Image, radius: float) -> Image.Image:
    """Cuma alpha yang di-blur; RGB (teks) tidak disentuh."""
    a = im.getchannel("A").filter(ImageFilter.GaussianBlur(radius))
    out = im.copy()
    out.putalpha(a)
    return out


def main() -> int:
    done = []
    for name, radius, mode in (
        [(n, 2.0, "full") for n in FAR]
        + [(n, 1.5, "full") for n in MID]
        + [(n, 1.0, "full") for n in NEAR]
        + [(n, 1.0, "alpha") for n in TEXT]
    ):
        p = SPR / (name + ".png")
        if not p.exists():
            print(f"SKIP (tidak ada file): {name}")
            continue
        im = Image.open(p).convert("RGBA")
        before = transition_share(im)
        out = feather_full(im, radius) if mode == "full" \
            else feather_alpha_only(im, radius)
        after = transition_share(out)
        out.save(p)
        done.append(name)
        print(f"{mode} r={radius} {name}: transisi {before:.2f}% -> "
              f"{after:.2f}%")
    print(f"feather_edges_v33 OK: {len(done)} sprite")
    return 0


if __name__ == "__main__":
    sys.exit(main())
