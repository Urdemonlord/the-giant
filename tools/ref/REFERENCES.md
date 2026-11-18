# Referensi build-time untuk sprite Main UI v20 (tools/ref/)

File-file di sini BUKAN aset game (tidak dipakai langsung oleh scene);
mereka sumber yang dibaca generator `tools/make_menu_sprites_v20.py`
saat membangun sprite menu. Jangan hapus tanpa mengganti generatornya.

## parchment_vecteezy.jpg
- Foto asli kertas perkamen kusut/bernoda/tepi sobek, 3497x1960.
- Sumber: Vecteezy free photo 57329614, "distressed paper texture
  showcasing wrinkles, stains and imperfections".
  https://www.vecteezy.com/photo/57329614-distressed-paper-texture-showcasing-wrinkles-stains-and-imperfections-a-rich-backdrop-for-vintage-or-aged-designs-evoking-a-sense-of-history-free-photo.jpg
- Dipakai sebagai base `menu_ledger_v20.png` dan `menu_btn_v20*.png`
  (di-grade gelap ke palette kunci game). Kerut, noda, dan tepi
  sobeknya dari foto ini, bukan digambar.

## grain_mb000.png
- Tile grain 256x256, high-pass dari area kabut foto hutan Sumatra
  berkabut `mb-000.jpg` (foto asli National Geographic, cover
  moodboard v2/v3 hal. 1, `~/workspace/your_files/the-giant-moodboard/`).
- Dipakai sebagai grain VHS pada `menu_logo_v20.png`,
  `menu_ledger_v20.png`, dan tombol. Bukan noise acak.
- Foto hutannya sendiri TIDAK disalin ke repo (milik National
  Geographic, dipakai sebagai referensi moodboard); hanya tile
  high-pass-nya yang disimpan di sini.

## Referensi yang TIDAK dipakai sebagai tekstur (dicatat supaya tidak diulang)
- Foto logbook "Notes and Notams" (buku pilot rusak air, ditemukan
  lewat image-search 2026-11-18, https://cyber-amber.com/map/60Eik35PkR5PkR18N0a):
  bentuk dan garis bukunya ditiru untuk layout garis aturan + jahitan
  jilid, tapi fotonya TIDAK dipakai sebagai tekstur karena tulisan
  tangannya memuat nomor telepon asli orang lain.
- Frame storyboard v2 (rekaman kamera pos rusak): treatment VHS-nya
  (tracking tear, grain tebal) ditiru untuk logo, tapi frame-nya
  sendiri dibangun dari gambar generate, jadi TIDAK dipakai sebagai
  sumber piksel.

## Menu v23: kaki Giant dari foto asli (2026-11-18, list Luci)
- `giant_foot_photo_v23.png` — potongan FOTO ASLI kaki gajah di
  lumpur, sudut rendah (Wetu, Tile K moodboard v2):
  https://wetu.com/ImageHandler/1344x756/174053/190731_sco_4313.jpg
  (file sumber: `~/workspace/your_files/the-giant-moodboard/.src/
  media/ref-foot-mud.webp`, diunduh 2026-11-16 lewat image-search).
  Crop kaki depan + telapak (x 230..700, y 0..640 dari foto
  1136x756), alpha dari luminansi (latar blur terang dihapus),
  grade malam 0,62 + desaturasi hijau-abu
  (`tools/make_menu_foot_v23.py`, deterministik, tanpa random).
  Alasan: `giant_foot.png` (crop kaki gajah depan sheet Arya)
  dicek zoom 3x — kolom berkerut seragam, tanpa telapak dan tanpa
  kuku, jadi di jendela memang batang pohon. Foto ini punya
  telapak melebar + dua kuku bulat + lumpur di telapak.
  Dipakai di backdrop menu (`main.gd _setup_menu_window_giant`) DAN,
  sejak v24, di event kaki 03:30 dalam game (`giant_event.gd
  _start_foot`, unshaded + tint 1,5 yang sama — follow-up v23 selesai;
  `giant_foot.png` kini tidak dipakai lagi). Nol aset AI, nol gambar
  generate.

## Menu v21: Giant di kabut + kertas sobek (2026-11-18)
- `menu_giant_v21.png` — siluet Giant di backdrop menu: `elephant_shadow`
  dari sheet Arya dibalik horizontal (kepala menghadap pos/pemain, karena
  Sprite3D billboard tidak bisa flip) + grade malam 0.8 + desaturasi ke
  Hijau Sakit (`tools/make_menu_giant_v21.py`). Bukan gambar baru.
- `menu_ledger_v21.png` — dari `menu_ledger_v20.png` yang sama (foto
  perkamen Vecteezy 57329614): tepi sobek alpha + cahaya hangat Kuning
  Lampu di tepi kanan (lampu teras pos) + burned edge
  (`tools/make_menu_sprites_v21.py`).
- Penempatan Giant/kabut dihitung dari kamera menu (-4.5, 2, -8, yaw 209,
  FOV 72) di `main.gd _setup_menu_giant()` — hanya backdrop menu, tidak
  ada di permainan. Kaki raksasa + kilau mata dicoba dan DIBUANG (kaki
  dibaca batang pohon/lalu hilang; mata tampil sebagai kotak abu-abu
  melayang seperti glitch).

## Menu v24: halaman buku dengan teks di-bake (2026-11-18)
- `menu_book_page_l_v24.png`, `menu_book_page_r_v24.png`,
  `menu_book_page_r_disabled_v24.png` (1024x1024) — dari foto
  perkamen asli yang SAMA dengan v20/v22 (Vecteezy 57329614, crop
  (300,250,1324,1274), grade darken 0,88, green 1,02). Semua teks
  statis di-bake dengan multiply tinta gelap (generator
  `tools/make_menu_book_v24.py`, seed 24, deterministik): logo
  "THE GIANT" dari mask alpha `menu_logo_v20` saja (warnanya tidak
  dipakai, jadi ghost merah/biru VHS v20-nya hilang), header "Buku
  jaga, Pos 07", garis merah, "Taman Nasional Malayunesia.",
  baris Start/Continue/Options/Exit; varian mati: Continue tinta
  redup (56,48,41) + coret + "no record on file". Zona teks
  diratakan dulu (blur 18, angkat 0,15 ke median lokal, feather 40,
  zona mengikuti lebar teks) supaya lipatan gelap diagonal tidak
  menabrak tulisan. Huruf di-stretch HANYA vertikal 1,4545x (kertas
  di-squash 0,6875 di 3D) — digambar di layer kecil dengan font
  normal lalu di-stretch vertikal, bukan font lebih besar (itu
  melebarkan teks dan memotong tepi). Font DejaVu Sans Mono Bold.
  Nol aset AI, nol gambar generate.

## Menu v25: mockup Arya + kepala Zunisha + bar merah (2026-11-18)
STATUS: PLACEHOLDER — dua gambar referensi Arya (mockup main UI +
sheet elemen tempat, 2026-11-18 14:34 WIB, file
`workspace/user/files/1000488175_5_s0qi.png` dan
`1000488176_6_n0hn.png`) kelihatan seperti concept art AI-generated.
Semua aset yang dipotong dari sana kelas placeholder, bukan art final.
Kepala gajahnya sendiri dari sheet Arya (aset asli), tapi grade +
skala kolosalnya tetap placeholder.
- `giant_head_zunisha_v25.png` (330x270) — crop kepala (10, 0, 340,
  270) dari `elephant_front.png` sheet Arya (kepala + telinga +
  belalai + gading). Grade kabut pucat (desat 0,55, brightness 1,45,
  dingin 0,82/0,90/1,02), pipi digelapkan 0,5, kolom belalai (|x-155|
  < 32) diangkat x3,0, zona gading x2,5 (`tools/make_menu_head_v25.py`,
  deterministik). Dipakai di backdrop menu, 20 m di z 12
  (`main.gd _setup_menu_window_giant`, tint 1,2/1,25/1,3, unshaded).
  Siluet kera di mockup TIDAK dipakai. Yang kelihatan lewat jendela
  hanya belalai + gading (kubah + telinga di atas frame — geometri
  kusen, lihat README v25). Nol gambar generate baru; sumbernya
  sprite sheet Arya.
- `menu_book_page_l_v25.png`, `menu_book_page_r_v25.png`,
  `menu_book_page_r_disabled_v25.png` (1024x1024) — foto perkamen
  asli yang SAMA dengan v20/v22/v24 (Vecteezy 57329614, crop
  (300,250,1324,1274), grade darken 0,88, green 1,02). Siluet kepala
  gajah kecil di atas judul (mask alpha kepala Zunisha, tinta gelap,
  150 px, V 100); sub Continue mati kini "no record on this slot"
  (bahasa mockup). Generator `tools/make_menu_book_v25.py` (seed 25).
  Logo `menu_logo_v20.png` sebagai sumber generator dipulihkan dari
  git (aba5263) ke `tools/ref/menu_logo_v20.png` — v24 menghapusnya
  dari `assets/` tapi generator membutuhkannya; ia sumber build saja,
  bukan sprite runtime.
- `menu_bar_{start,continue,options,exit}_v25.png` (900x150) — bar
  tinta merah INK_RULE + teks terang (235,228,210) di posisi yang
  sama dengan teks bake gelap + segitiga play hanya di Start
  (`tools/make_menu_book_v25.py`, `make_bar_textures()`).
- `menu_sign_graveyard_v25.png` (200x169) — crop papan + kaki
  (545, 772, 745, 941) dari gambar tempat Arya (1000488176_6_n0hn.png,
  1672x941), alpha dari luminansi (checkerboard terang -> hilang),
  grade malam 0,85 (`tools/make_menu_head_v25.py`). Dipakai di
  backdrop menu, 2 m di x 5,5, z 9. PLACEHOLDER (gambar sumber
  kelihatan AI-generated).
- `menu_skeleton_v25.png` (390x200) — crop kerangka (80, 500, 470,
  700) dari gambar tempat Arya yang sama; langit checkerboard di
  sumber diganti kabut halus (piksel L>190 -> kabut), tepi
  di-feather, grade malam 0,8 (`tools/make_menu_head_v25.py`).
  DIPOTONG dari menu ronde 8 (kepala 20 m menutupi seluruh jendela)
  — aset tetap ada untuk penempatan DALAM permainan nanti.
  PLACEHOLDER (gambar sumber kelihatan AI-generated).
