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
