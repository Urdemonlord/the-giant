# THE GIANT - Proyek Godot

[![make.fun · best-game-01](https://make.fun/badge/best-game-01.svg)](https://make.fun/bounty/best-game-01?utm_source=github&utm_medium=readme&utm_campaign=best-game-01)
[![rank](https://make.fun/badge/best-game-01/Urdemonlord/the-giant/rank.svg)](https://make.fun/bounty/best-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=best-game-01)
[![reward](https://make.fun/badge/best-game-01/Urdemonlord/the-giant/reward.svg)](https://make.fun/bounty/best-game-01?utm_source=github&utm_medium=readme&utm_campaign=best-game-01)

Repo: **https://github.com/Urdemonlord/the-giant** — rilis (Windows + Web):
**https://github.com/Urdemonlord/the-giant/releases** (tag `v12`).

## Cara main (Windows, dari rilis)

1. Download `THE-GIANT-windows.zip` dari halaman rilis di atas.
2. Extract SELURUH isi zip ke satu folder.
3. Jalankan `THE-GIANT.exe`. File `THE-GIANT.pck` HARUS tetap di folder yang sama dengan .exe dan namanya harus sama dengan .exe (kalau .exe diganti nama, .pck ikut diganti). Kalau .pck hilang atau namanya beda, game gagal dengan error "Couldn't load project data". (v11 sempat rusak karena zip-nya cuma berisi .exe tanpa .pck; diperbaiki di v12.)

Prototipe first-person psychological horror dalam **Godot 4.3+** (GDScript, renderer GL Compatibility).
Ini versi native dari prototipe browser sebelumnya: bukan halaman web, jadi tidak kena pull-to-refresh, kunci orientasi webview, atau AudioContext yang tertidur.

Setting: **pos jaga** (bukan rumah) di Taman Nasional **Malayunesia**. Kamu penjaga shift malam, 22:00 sampai 06:00. Jaga pos ini. Jangan biarkan mereka kembali.

## Handover card — v7 (2026-11-16, cara kerja Claude Code Game Studios)

Brief satu halaman: `design/game-brief.md` (kata-kata Arya
dipertahankan, tiap baris dicek built/missing/broken dari screenshot
dan kode — lihat bagian "Cek per baris" di brief).

### Yang baru di v7
- **Koran Harian Rimba Post bisa dibaca** (`scripts/interactables/readable.gd`,
  `doc_id=newspaper`): di ujung kiri depan meja, E untuk membaca, panel
  judul "HARIAN RIMBA POST" + headline "Gajah Liar Masuk Kebun Sawit,
  Petani Rugi Miliaran" + kalimat "yang tidak ditulis koran ini" +
  catatan alas makan. Kertas + garis cetakan di atas meja.
- **Surat izin pelepasan hutan 12.400 hektar bisa dibaca**
  (`doc_id=permit`): di ujung kanan meja, stempel merah, catatan tangan
  "gajah sudah tidak ada di sini".
- **Intro singkat, bisa di-skip (E / tombol)**: Pos Jaga 07, shift
  22:00-06:00, tugas jaga lampu + tulis laporan + jangan buka pintu
  untuk yang mengetuk dari hutan, penjaga sebelumnya pergi tanpa pamit.
- **Ending beneran, menang dan kalah**: judul + payoff cerita + satu
  kalimat faktual ("Di Malayunesia, gajah adalah satwa dilindungi;
  setiap tahun, ribuan hektar hutan tempat mereka hidup berubah menjadi
  kebun sawit."), tombol Kembali ke Menu / Main Lagi. "Main Lagi"
  melewati intro sekali.

### Yang lolos QA v7 (Godot 4.3, Xvfb 1280x720)
- `mode=story` **PASS fails=0**: koran dibidik + dibuka + ditutup
  pakai E, surat dibidik + dibuka + ditutup pakai E, ending menang
  (alasan `dawn`, judul "06:00 — Fajar", kalimat penutup ada), ending
  kalah (alasan `sanity`, judul "Shift Berakhir Sebelum Pagi").
- `mode=playtest` **PASS fails=0** (regresi, Sanity akhir 100).
- `mode=verify` bersih (registry 42 nama, 0 hilang).
- Intro dicek **run langsung** `scenes/main.tscn` (tanpa rig) +
  screenshot `v12_intro.png`.
- Screenshot: `v12_doc_newspaper.png`, `v12_doc_permit.png`,
  `v12_ending_win.png`, `v12_ending_lose.png`, `v12_desk_docs.png`,
  `v12_desk_docs_close.png`, `v12_desk_docs_top.png`
  (di `~/workspace/godot/shots/`).

### Bug yang ketemu QA v7 (diperbaiki, lolos ulang)
- **Koran tidak bisa dibidik dari spawn**: raycast mengenai hitbox
  radio dulu (radio berdiri di antara kamera dan koran). Perbaiki:
  koran pindah ke ujung kiri depan meja (-2.05, 1.07, 1.05) di luar
  bayangan radio, hitbox radio diperkecil jadi pas ukuran radio
  (0.55 x 0.42 x 0.32), kertas diputar searah lebar meja.
- **E tidak bisa menutup dokumen**: `_unhandled_input` dipanggil
  urutan terbalik (HUD dulu, player belakangan), jadi HUD menutup panel
  lalu event E yang sama sampai ke player dan membuka dokumen itu lagi.
  Perbaiki: `get_viewport().set_input_as_handled()` setelah HUD menutup
  panel / toggle pause. Tombol E sentuh juga menutup dokumen kalau ada
  yang terbuka, bukan memicu interaksi lagi.
- **Prompt interaksi menimpa panel dokumen** (kelihatan di screenshot
  v12 pertama): prompt disembunyikan selama panel / pause terbuka
  (`hud.gd` `_process`).

### Yang masih rusak
Tidak ada yang diketahui di lingkup v7. Lihat "Polish list" di brief
untuk yang belum dikerjakan.

### Yang ditebak (bukan kata Arya)
- Posisi koran/surat di meja, teks intro, dan kalimat penutup faktual
  ditulis asisten dengan nada Arya; belum disetujui kata per kata.
- "Main Lagi" melewati intro sekali (bukan keputusan Arya).
- Prioritas sensor-dulu dan durasi ~10 menit dari konsep v1 masih
  asumsi asisten, belum dikonfirmasi Arya.

**Not yet played by a person.**

## Cara membuka

1. Install Godot **4.3 atau lebih baru** (https://godotengine.org/download).
2. Extract ZIP ini, buka Godot, klik **Import**, pilih file `the-giant-godot/project.godot`.
3. Tekan **F6 / Play** (tombol segitiga di kanan atas editor). Scene utama: `scenes/main.tscn`.
4. Klik di jendela game untuk mengunci mouse. ESC untuk melepas.

## Kontrol

| Aksi | Tombol |
|---|---|
| Jalan | W A S D |
| Lihat sekitar | Mouse (setelah klik layar) |
| Lari | Shift |
| Interaksi | E |
| Senter | F |
| Jeda (menu pause) | ESC |

Di Android / layar sentuh: joystick virtual kiri untuk jalan, geser
kanan layar untuk melihat, tombol **E** untuk interaksi, **SENTER**
untuk senter, tombol **II** kiri atas untuk jeda
(`scripts/touch_controls.gd`, muncul otomatis kalau layar sentuh
tersedia).

## Menu utama, save, pause (v5)

Game mulai dari **menu utama** (`scenes/menu.tscn`, scene utama proyek):
judul THE GIANT, tombol **MULAI SHIFT BARU** (reset shift), **LANJUTKAN**
(aktif kalau ada `user://savegame.json`, menampilkan jam + Sanity
simpanan), dan **CARA MAIN** (panel kontrol + cerita singkat).
**ESC** membuka menu jeda (`scripts/hud.gd`): Lanjutkan, Simpan Shift,
Keluar ke Menu. Save menyimpan jam shift, Sanity, Stability, bahan
bakar, generator, tugas selesai, posisi + arah pemain, dan pintu
terbuka/tutup (`scripts/save_game.gd`); event yang sedang berjalan
tidak disimpan, event akan terpicu ulang kalau jamnya belum lewat.

- **First-person controller** (`scripts/player.gd`): WASD + mouse look (pitch dibatasi), gravitasi, sprint, head-bob halus, senter SpotLight, RayCast3D untuk deteksi interaksi.
- **Pos jaga prosedural** (`scripts/guard_post.gd`): lantai panggung + tiang, 4 dinding dengan celah pintu depan dan celah jendela belakang, atap, tangga, meja jaga, kursi, peti, dan **pintu berengsel** yang membuka/menutup dengan tween, lengkap dengan lubang intip.
- **Interaksi** (grup `interactable`, prompt muncul saat crosshair mengarah):
  - `generator.gd` - nyala/matikan generator di samping pos; bahan bakar terkuras saat menyala; lampu pos ikut hidup/mati.
  - `radio.gd` - 5 potongan siaran bergiliran, termasuk headline Harian Rimba dan peringatan dari hutan.
  - `logbook.gd` - menulis laporan jaga (menyelesaikan tugas + memulihkan sedikit Sanity).
  - `readable.gd` - dokumen cerita yang bisa dibaca (v7): koran
    Harian Rimba Post + surat izin 12.400 hektar. E membuka panel
    judul + isi + tombol "Tutup (E)"; game pause selama panel terbuka.
    Posisi di `level_data.gd` (NEWSPAPER_POS, PERMIT_POS).
  - `lantern.gd` - lentera di dalam pos, nyala/matikan cahayanya.
  - `door.gd` - buka/tutup pintu pos.
- **Sistem shift** (`scripts/game_state.gd`, autoload `GameState`): Sanity, Stability, bahan bakar, jam shift 22:00 ke 06:00 (1 detik nyata = 1 menit shift, shift penuh sekitar 8 menit), daftar tugas, sinyal untuk HUD. Generator mati = Stability terkuras; menyala = pulih perlahan.
- **Event pemburu** (`scripts/hunter_event.gd`): pukul 01:30 dua sosok diam muncul di depan pos dan menatap, persis momen *No I'm Not a Human*. Menatap mereka menguras Sanity. Tutup pintu dan tunggu di dalam 12 detik untuk melewatinya dengan aman; event juga berakhir sendiri setelah 50 detik dengan harga Sanity.
- **HUD** (`scripts/hud.gd`): titik crosshair di tengah, prompt interaksi, bar SANITY dan STABILITY di kiri bawah, jam + daftar tugas di kanan atas, pesan naratif yang memudar. Tidak ada panel yang menutupi tengah layar. Sejak v7: panel dokumen, panel intro, dan panel ending (judul + payoff cerita + satu kalimat faktual + tombol menu / main lagi); prompt disembunyikan selama panel terbuka.
- **Audio prosedural** (`scripts/audio.gd` + `assets/audio/*.wav`): angin (loop), dengung generator (loop), statis radio, derit pintu, langkah kaki, dan detak jantung saat Sanity di bawah 35. Semua WAV **disintesis dari kode** (noise/sine), tidak ada file audio berlisensi pihak ketiga. **Suara radio (v8-suara, 2026-11-16)**: 5 siaran radio sekarang BERSUARA, bukan cuma teks + statis: `radio_voice_1..5.wav`, disintesis dari teks siaran lewat gTTS bahasa Indonesia lalu diproses jadi radio tua rusak (band-pass 300-3000 Hz, statis ringan, baris ke-5 sengaja lebih rendah + lambat karena "bukan suara manusia biasa"); tiap interaksi radio memutar klip yang cocok dengan baris teksnya (`tools/make_radio_voice.py`, bisa dijalankan ulang). **SFX diperbaiki di ronde yang sama** (`tools/synth_audio.py`): derit pintu ditulis ulang jadi derit kayu stick-slip tonal (dulu cuma noise, centroid 3561 Hz), langkah kaki dapat lapisan krek tanah + pitch acak tiap langkah, dentuman Giant dapat transient retak + gema + peak diturunkan dari 0.99 ke 0.90, detak jantung dapat harmonik + ketuk katup. Verifikasi: `tools/audio_verify.py` (format + spektrum tiap WAV) dan test rig `mode=audio` (semua klip ke-load + jalur play + ganti klip radio + interact radio 5x). Batas jujur: belum pernah didengar telinga manusia (sandbox tanpa sound card).
- **Lingkungan** (`scripts/main.gd`): tanah, jalan tanah, pagar kayu dengan celah gerbang, papan tanda, dan +/- 100 pohon prosedural mengelilingi pos. Kabut tebal + cahaya bulan redup dari `WorldEnvironment` di scene.

## Aset sprite

Dua sprite sheet asli kamu tersimpan utuh di `assets/source/` (`props_sheet.png`, `world_sheet.png`).
Dari sheet props (grid 4x3, latar hitam) dipotong 12 sprite individual ke `assets/sprites/`:
`lantern, generator, radio, logbook, meter, door, snare, stump, tusks, chainsaw, footprint, sign_no_elephant`.
Dari sheet dunia dipotong 17 sprite lagi pada rebuild visual 2026-11-16,
ditambah 3 potongan Giant pada polish v3 (`giant_foot`, `giant_eye`,
`giant_eye_socket`, total 32 sprite):
`tree_tall, tree_palm, tree_dead, bush2, watchtower, tower_tall, guard_hut,
sign_park, sign_no_logging, sign_no_elephant2, elephant_side, elephant_front,
elephant_shadow, guard_front, hunter_rifle, fog_puff`, plus tekstur dinding
kayu (`assets/textures/wood_planks.png`, dari dinding pondok jaga) dan
tekstur tanah (`assets/textures/ground.png`).
Latar hitam dibuat transparan dengan ambang luminansi + feather 1px, lalu tiap sprite di-autocrop.
Sprite dipakai sebagai **Sprite3D billboard** di generator, radio, buku jaga, lentera, papan tanda, dan properti berserakan (tunggul, gading, jerat, jejak kaki). Kalau file sprite hilang, game tetap jalan dengan mesh kotak sebagai fallback.
Sosok pemburu di event 01:30 memakai `hunter_rifle.png` (1,8 m) untuk
pemburu pertama dan potongan lama `hunter.png` untuk pemburu kedua
(yang kedua lebih gelap); tidak ada lagi sprite yang menganggur.

## Export

`export_presets.cfg` berisi 3 preset: **Windows Desktop**, **Android** (arm64, landscape, immersive), **Web**.
Langkah: Project > Export, pilih preset, pastikan Export Templates sudah terpasang (Editor > Manage Export Templates), lalu Export Project. Output diarahkan ke folder `builds/` di luar folder proyek.

## Visual rebuild (2026-11-16)

Visual dibangun ulang mengikuti workflow `guizang-game-skill`: tiap langkah
diverifikasi dengan screenshot nyata dari Godot (Xvfb, 1280x720), bukan
sekadar "tidak ada error". Yang berubah:

- **Dinding/lantai kayu bertekstur**: tekstur papan kayu dipotong dari dinding
  pondok jaga di sheet dunia (`assets/textures/wood_planks.png`), bukan lagi
  potongan pintu (dulu dinding terbaca seperti tiga pintu berjajar).
- **Sprite billboard dari sheet dunia**: pohon tinggi/palem/mati, semak,
  menara pengawas, menara radio, pondok jaga, rambu taman / larangan tebang /
  larangan gajah, gajah samping/depan/siluet, penjaga, pemburu bersenapan,
  dan gumpalan kabut (`assets/sprites/`, 17 potongan baru). Pohon bukan lagi
  "lollipop" (bola di atas tiang).
- **Properti tanpa kotak hitam**: lentera, generator, dan radio sekarang
  sprite saja (kotak mesh hitam dihapus); lentera menyala hangat dan
  terlihat jelas di dalam pos.
- **Tanah bertekstur**: `assets/textures/ground.png` (lumut/tanah gelap
  prosedural) menggantikan bidang abu-abu polos.
- **Cahaya diperbaiki**: cahaya bulan diarahkan turun ke depan pos
  (dulu arahnya salah, dinding depan gelap dan bawah atap malah terang),
  energi bulan 0,75, ambient lebih hangat, kabut lebih tipis.
- **Event pemburu** sekarang memakai sprite `hunter_rifle.png` setinggi
  1,8 m (dulu kapsul hitam + kepala bola); yang kedua sedikit lebih gelap.

Terverifikasi lewat screenshot (Godot 4.3, Xvfb 1280x720, 2026-11-16):
interior pos menghadap pintu, jendela ke hutan, eksterior pos + generator,
pagar + hutan + gading, meja jaga (radio, buku jaga, lentera menyala),
event pemburu dari dalam (jam 01:34, Sanity turun) dan dari luar (dua
pemburu menatap pos, jerat + gading di tanah). Headless 300 frame tanpa
script error setelah rebuild.

## Polish (2026-11-16, v3)

Masih mengikuti workflow `guizang-game-skill`: tiap langkah dibuktikan
screenshot nyata, bukan sekadar "tidak ada error".

- **THE GIANT akhirnya muncul (tidak pernah utuh)**: `scripts/giant_event.gd`.
  - Kaki raksasa ~03:30 lewat di jendela belakang (sprite potongan kaki
    gajah `giant_foot.png`, 4,5 m, melangkah 9 detik, tanah bergetar,
    dentuman `play_thud()`). Menatapnya menguras Sanity.
  - Mata raksasa ~04:45 menempel di kaca jendela (sprite kulit mata
    `giant_eye.png` dibesarkan + potongan rongga mata `giant_eye_socket.png`
    1,6 m di tengah jendela + kilau redup). Menatapnya menguras Sanity
    4/detik, radio statis, lalu mundur ke kabut. Giant tidak pernah
    tampil utuh di mana pun.
- **Overlay analog horror** (`scripts/hud.gd`): "● REC CAM 07" berkedip
  kiri atas, scanlines, grain VHS (shader noise), vignette. Benchmark
  Unholy Dream / No I'm Not a Human, bukan PS1 bersih.
- **Lampu teras** (`scripts/guard_post.gd`): OmniLight hangat di depan
  pintu, ikut generator; dinding depan tidak lagi hitam pekat.
- **Lentera berkedip halus** (`scripts/interactables/lantern.gd`):
  energi cahaya berdenyut seperti api, bukan lampu neon.
- **Balance pemburu diperbaiki** (`scripts/hunter_event.gd`): menatap
  pemburu HANYA menguras Sanity kalau pintu terbuka (sebelumnya menembus
  dinding tertutup, dan dua pemburu menguras ganda, jadi pemain pasif yang
  menghadap pintu bisa mati tanpa melakukan apa-apa). Sekarang jalur aman
  "tutup pintu, tunggu di dalam" benar-benar aman.
- **Guncangan kamera** (`scripts/player.gd`): langkah Giant mengguncang
  kamera sesaat.

Terverifikasi lewat screenshot seri v8 (Godot 4.3, Xvfb 1280x720):
`v8_hunter_vhs` + `v8_hunter_out` (dua pemburu menatap pos dari balik
pagar, rambu Taman Nasional Malayunesia), `v8_door_vhs`, `v8_desk_vhs`
(meja jaga + overlay VHS), `v8_foot` (kaki Giant memenuhi jendela),
`v8_eye` (massa kulit + rongga mata gelap di kaca jendela),
`v8_outside_porch` (eksterior + lampu teras + generator).
Playthrough scripted (test rig, sejak v5 ikut ZIP, lihat bawah): jalur menang
22:00-06:00 berakhir sukses (Sanity 84, tugas survive selesai),
jalur kalah (Sanity 0) berakhir gagal, semua 6 WAV termuat dan semua
jalur audio menyala (angin, dengung generator, statis, derit, dentuman,
detak jantung di bawah Sanity 35 lalu berhenti di atasnya).
Yang masih belum dimainkan end-to-end oleh manusia: satu shift penuh
22:00-06:00 dengan tangan sendiri (rig di atas melompat waktu dan
menyelesaikan tugas secara programatik).

## Semua elemen sheet dipakai (2026-11-16, v4)

Audit 2026-11-16 menemukan 5 sprite lama yang filenya ada tapi tidak
pernah muncul di game (`chainsaw, meter, guard_front, elephant_front,
hunter`) plus elemen sheet dunia yang belum pernah dipotong. Semuanya
sekarang dipasang, total sprite 43 (dari 32):

- **Meter getar** (`meter.png`): di atas meja jaga, di samping buku
  jaga + radio (`guard_post.gd`). Sensor yang mendeteksi langkah Giant.
- **Chainsaw** (`chainsaw.png`): di tanah samping generator, bukti
  penebangan liar (`main.gd`).
- **Penjaga sebelumnya** (`guard_front.png`): berdiri diam di samping
  jalan, menghadap hutan. Bukan karakter kedua.
- **Gajah dari depan** (`elephant_front.png`): siluet kedua di kabut
  utara jauh (7 m), tidak pernah utuh/dekat.
- **Pemburu kedua = `hunter.png`**: event 01:30 kini pakai dua varian
  berbeda (`hunter_event.gd`).
- **Poacher topeng merah** (`poacher_mask.png`, baru dipotong): berdiri
  DI gerbang, di jalur tanah yang kosong supaya tidak ketutup pohon.
- **Siluet putih** (`poacher_ghost.png`, baru): sosok kabut di barat,
  semi-transparan.
- **Gerbang kayu** (`gate.png`, baru): rangka gerbang di celah pagar,
  di depan rel pagar supaya kebaca.
- **Tong, karung, peti tinggi, peti rendah** (`barrels, sacks,
  crate_tall, crate_low`, baru): di sekitar generator + sisi barat pos.
- **Kayu gelondongan, batu, pohon pisang** (`log, rocks, banana`,
  baru): di sekitar tunggul + tepi hutan.
- **Darah** (`blood.png`, baru): decal datar di tanah dekat jerat,
  dibesarkan + didongkrak supaya kebaca di tanah gelap
  (`main.gd _ground_decal`).
- **Senter/lampu sorot tidak dipasang**: potongan `flashlight_beam`
  sempat dipotong lalu dihapus lagi; billboard sorot yang selalu
  menghadap kamera akan terlihat melayang dan salah arah saat pemain
  bergerak. Pemain sudah punya senter sendiri (tombol F).

## Semua elemen sheet dipakai, ronde 2 (2026-11-17, v16)

Audit 2026-11-17 menemukan 10 elemen sheet dunia yang belum pernah
dipotong (plus cuma 1 varian semak). Semuanya sekarang dipotong dengan
metode yang sama (ambang luminansi + feather 1px + autocrop,
`tools/make_v16_sprites.py`) dan dipasang; total sprite 54 (dari 42):

- **Gajah tampak belakang** (`elephant_back.png`): siluet gajah biasa
  di kabut utara-timur, 3,6 m, unshaded + tint 0,6. BUKAN Giant —
  Giant tidak pernah tampil utuh.
- **Ranger tampak belakang** (`guard_back.png`): ranger kedua di dekat
  pondok, membelakangi. Unshaded (ronde 1 shaded hilang menempel
  dinding pondok yang gelap), tint 0,65.
- **Pohon besar berdaun lebat** (`tree_big.png`): masuk rotasi
  `_make_tree` (1 dari 5 pohon), 22 batang di hutan. Potongannya butuh
  mask: daun pisang menyentuh batang pohon di sheet.
- **Pagar kayu + pagar kawat berduri** (`fence_wood`, `fence_barbed`):
  sisa perimeter di sisi barat/timur halaman (pagar mesh prosedural
  cuma ada di depan, z -16).
- **Menara radio** (`radio_tower.png`): siluet 14 m di barat-utara,
  unshaded supaya lampu merahnya tetap nyala di kabut.
- **Baterai, walkie-talkie, sekop, kapak** (`battery`,
  `walkie_talkie`, `shovel`, `axe`): perkakas di baris timur dekat
  generator + baris bukti penebangan. Potongan kapak butuh 2 mask
  (kotak amunisi + ujung mata gergaji di kotak sebelah).
- **Semak varian** (`bush1`, `bush3`): di garis pagar seperti bush2.

Terverifikasi lewat screenshot Godot 4.3 Xvfb 1280x720, seri v20
(`~/workspace/godot/shots/v20_*.png`, dilihat satu-satu, 6 ronde ulang
untuk sudut yang ketutup pohon/dinding/gelap/kabut): `v20_axe_row`
(kapak), `v20_shovel_close` (sekop, samar — benda gelap di malam hari),
`v20_east_row` + `v20_east_props_close` (baterai + walkie),
`v20_fence_wood` (rel pagar, baru kebaca setelah dicerahkan 4x —
  pagar kayu 1,2 m di malam hari memang nyaris tidak kebaca),
`v20_guard_back` (ranger, samar menempel pondok),
`v20_elephant_back` (badan + kaki gajah, zoom 2x),
`v20_radio_tower` (dua titik lampu merah di atas),
`v20_forest_north` (kanopi bulat tree_big),
`v20_bush3` (semak di garis pagar). Registry validate 54/54, verify
total Sprite3D 202; mouselook/playtest/story PASS fails=0, 0 script/
shader error. Batas jujur: `fence_barbed` + `bush1` di foto ketutup
pohon (posisi + jumlah di verify sudah benar); `walkie_talkie` tidak
berhasil diidentifikasi dengan yakin di foto (kecil + gelap, posisi +
jumlah di verify sudah benar). Elemen sheet yang masih belum dipotong:
gajah samping merumput, pohon kecil, kotak amunisi, balok subtitle
(Sanity/Stability — itu UI, bukan sprite).

## Menu utama: latar 3D hidup (2026-11-17, v17)

Menu bukan lagi ColorRect hitam + teks terpusat. `main_menu.gd` menginstans
scene main yang sama dengan mode backdrop (`set_meta("menu_backdrop", true)`):
kabut + terrain + hutan + pos dibangun apa adanya, malam dikunci di titik
tergelap kurva v14 (jam 02:00, bulan 0.55, ambient 0.50, vol fog 0.036),
generator dinyalakan supaya lampu teras menyala. Kamera menu
(`menu_camera.gd`) menyapu pelan +-5 derajat / 26 dtk (pola intro pan v14),
dari jalan depan-kiri (-4.5, 2.0, -8.0, yaw 209 derajat). Waktu shift,
pemain, HUD, TouchControls, dan event Hunter/Giant dimatikan di mode ini;
GuardPost (fade-in lampu teras) + Audio (angin + jangkrik) tetap jalan.
Reset shift di `_on_new_game` mengembalikan generator off, jadi tidak bocor
ke permainan. Tidak ada aset gambar baru, tidak ada light baru.

Layout ikut unslop: split asimetris, teks rata kiri kolom 88..548, pos di
kanan frame; konten + sistem v15 tidak berubah (judul, tagline, 3 tombol,
sentence case, satu aksen kuning lentera, fokus kuning). Shader VHS
diekstrak dari `hud.gd` ke `assets/shaders/vhs.gdshader` supaya menu dan
game satu file. Catatan: komentar shader pakai `//`, bukan `##` — `##`
bukan komentar shader dan bikin compile gagal diam-diam, fx jadi rect
putih (ketahuan lewat rig, sempat merusak VHS HUD juga).

Terverifikasi lewat rig v20 + screenshot 1280x720 (`v20_menu_1280_no_save`,
`_pan`, `_with_save`, `_help`, portrait): backdrop=true, kamera menu aktif,
fokus di Mulai shift baru, mean_lum ~0.09-0.10; Lanjutkan disabled tanpa
save / aktif dengan save; Cara main membuka bantuan; menu_autostart=1 masuk
scene main. mouselook/playtest/story PASS fails=0, verify_atmosphere 20/20,
0 script/shader error. Batas jujur: footer sedikit di bawah layar saat
Cara main terbuka (tagline saja, teks bantuan lengkap); ultrawide murni
belum teruji.

## Menu utama: tema buku jaga, 4 tombol (2026-11-17, v18)

Keluhan Arya: menu tidak ada temanya, generik, masih ada kata slop.
Menu sekarang ADALAH buku jaga Pos 07: kepala log ("Buku jaga, Pos 07"),
garis aturan buku di bawah judul, catatan dinas ("Taman Nasional
Malayunesia. Shift malam 22:00 - 06:00. Jaga pos ini. Jangan biarkan
mereka kembali." — kalimat yang sudah ada di game, bukan karangan baru).
Footer blurb v15/v17 ("Sebuah cerita horor psikologis. Giant tidak
pernah tampil utuh.") DIHAPUS — itu suara toko, bukan suara penjaga.
Empat tombol persis kata pemilik: Start, Continue, Options, Exit.
Continue tanpa save: "Continue - no record on file" (disabled); dengan
save: "Continue - 22:00, Sanity 100" (format lama dipertahankan).
Exit disembunyikan di web (quit tidak menutup tab browser).

Options (layar baru, "Peralatan pos", bisa di-scroll): 4 slider volume
per bus (Suara utama/sekitar/efek/radio), slider sensitivitas mouse
0.5-2.0x, saklar layar penuh + grain film, dan "Cara main" (keycap +
instruksi, pindah dari menu utama — menu utama tinggal 4 tombol).
Semua pengaturan benar-benar jalan dan tersimpan di
`user://settings.json` (`scripts/settings.gd`, pola yang sama dengan
SaveGame tapi file terpisah supaya Start tidak ikut menghapusnya).
Perbaikan yang ikut kebawa: titik kembali ducking Ambience di audio.gd
dulu hardcode 0.0 dan menimpa slider Ambience tiap siaran radio habis —
sekarang kembali ke volume pilihan pemain.

Terverifikasi lewat rig v21 + screenshot 1280x720 (`v21_menu_no_save`,
`_pan`, `_options`, `_with_save`): 4 tombol persis, fokus di Start,
tidak ada label slop di seluruh menu, backdrop + sapuan kamera jalan,
Options berisi Cara main + keycap, tiap pengaturan diterapkan (Master
50% = bus -6.02 dB, sens 1.5x, grain off = 0.0) dan bertahan di file
maupun setelah reload; Exit terhubung ke quit (diuji run terpisah
`menu_test_exit=1`, proses berhenti, exit 0); menu_autostart=1 masuk
scene main. mouselook/playtest/story PASS fails=0, 0 script/shader
error. Batas jujur: isi Options lebih panjang dari layar — tombol
Kembali ada di bawah lipatan scroll (navigasi keyboard auto-scroll);
tombol Exit belum diuji klik di web (disembunyikan di sana).

Terverifikasi lewat screenshot Godot 4.3 Xvfb 1280x720, seri v9
(`~/workspace/godot/shots/v9_*.png`, dilihat satu-satu, 4 ronde ulang
untuk sudut yang ketutup pohon/dinding/gelap): `v9_desk_meter` (meter di
meja), `v9_shed3` (generator + chainsaw + tong + karung), `v9_gate4`
(gerbang + poacher topeng merah di dalamnya, pakai senter),
`v9_north2` + `v9_poacher_ghost2` (gajah depan + siluet putih),
`v9_ground` (log + batu + tunggul), `v9_blood2` (darah + jerat),
`v9_crate2` (peti rendah), `v9_crate_tall2` (peti tinggi, pakai
senter), `v9_hunter2` (pemburu kedua = hunter.png). Verifikasi scene
graph (`scripts/test_rig.gd` mode `verify`):
149 Sprite3D, 36 unik, semua 16 nama di atas count >= 1
(`hunter.png` count 0 di mode verify karena pemburu hanya spawn saat
event 01:30; sudah terbukti visual di `v9_hunter2`). Jalur menang
scripted masih lolos setelah perubahan ini (Sanity 84), headless 300
frame tanpa script error (hanya warning dummy-renderer yang dikenal).

## v6 (2026-11-16): kabut tebal + grafik creepy analog horror

Keluhan Arya: kabut tidak terasa, grafik creepy-nya tipis. Dua-duanya
diperbaiki dan diverifikasi screenshot seri v11
(`~/workspace/godot/shots/v11_*.png`, Godot 4.3 Xvfb 1280x720).

### Kabut (lama -> baru)
- `fog_density` 0.032 -> **0.06** (eksponensial: 10 m -> 0.55, 20 m ->
  0.30, 30 m -> 0.17). Pos + jalan dekat kebaca, pohon dekat jadi siluet
  gelap, cincin hutan 19-34 m tertelan kabut.
- `fog_light_color` gelap -> **abu kehijauan sakit** (0.23, 0.27, 0.22),
  sesuai palet moodboard, bukan putih bersih. `fog_sky_affect` 0.25 ->
  0.85: langit ikut berkabut, bukan hitam pekat polos.
- Fog puff 10 -> **36** (alpha 0.32 -> 0.42), ditambah **ground fog 18**
  lapisan kabut rendah merayap di permukaan tanah (alpha 0.45).
- **Percobaan pertama kebablasan** (density 0.085, alpha 0.55/0.6):
  jendela jadi dinding kabut polos, pos ketutup gumpalan dari jarak 8 m.
  Diturunkan + koridor jalan gerbang->pos (|x|<3.5, z -16..2)
  dikosongkan dari gumpalan supaya pos tidak pernah ketutup dari jalan.
- Semua angka kabut di `Balance` (FOG_DENSITY, FOG_PUFF_COUNT,
  FOG_PUFF_ALPHA, GROUND_FOG_COUNT, GROUND_FOG_ALPHA); `main.gd`
  `_apply_fog()` menerapkannya ke WorldEnvironment saat `_ready`.
  `.tscn` menyimpan default yang sama.

### Grafik creepy (lama -> baru)
- v5: grain 0.055 + scanline samar, tanpa tear / CA / desaturasi.
- v6: **satu shader layar penuh** (`hud.gd`, ColorRect + `screen_texture`
  `hint_screen_texture`) yang mengambil gambar 3D lalu: tracking tear
  (pita horizontal bergeser ~0.16 detik di ~70% jendela 4 detik),
  chromatic aberration ringan di tepi, desaturasi 45% ke hijau-abu sakit,
  scanlines, grain 0.13, vignette, flicker cahaya + redup mendadak.
  Rect ditambah paling awal di HUD, jadi label/prompt/bar tetap kebaca
  dan tidak ikut rusak.
- Catatan teknis: Godot 4.3 menghapus `SCREEN_TEXTURE` bawaan; shader
  harus pakai `uniform sampler2D screen_texture : hint_screen_texture`.
  Kesalahan pertama ketahuan dari `SHADER ERROR` di log, bukan dari
  screenshot (screenshot pertama 36 KB, hampir kosong).
- Semua angka overlay di `Balance` (VHS_GRAIN, VHS_SCANLINE, VHS_CA,
  VHS_DESATURATE, VHS_VIGNETTE, VHS_FLICKER, VHS_TEAR_SECONDS,
  VHS_TEAR_SHIFT).
- Test rig mode baru: `shots11` (jendela, eksterior, hutan, gerbang,
  meja, pintu + senter, event mata) — `mode=shots11 prefix=v11`.
- Regresi v6: `mode=verify` bersih (registry 42 nama, 0 hilang),
  `mode=win` lolos (Sanity 84), tidak ada script error.

### Masih belum sempurna (jujur)
- Kabut adalah fog eksponensial + billboard statis, bukan kabut volumetrik
  yang bergerak; gumpalan tidak berpindah, hanya fog density yang konstan.
- Tracking tear muncul sesekali (bukan di tiap screenshot); di shot yang
  dicek, tear tertangkap sebagai garis gelap di eksterior, bukan selalu.
- Langit masih gelap (bukan bintang/bulan kelihatan); kabut menutupi,
  tapi bukan langit berawan yang digambar.
- Semua screenshot dari llvmpipe (software rendering); di GPU asli
  warna/cahaya bisa sedikit berbeda.

## v8 (2026-11-16): kabut volumetrik + suara radio + video gameplay

Tiga permintaan Arya 17:26 WIB, semua dikerjakan dan diverifikasi.

### Kabut volumetrik (bukan lagi billboard saja)
- Kabut volumetrik Godot 4.3 **beneran render** (WorldEnvironment
  `volumetric_fog_enabled`, density 0.030, albedo hijau-abu 0.35/0.42/0.34,
  emission 0.10, anisotropy -0.15, sky affect 1.0, length 40 m).
  Butuh renderer **Forward+** di desktop, jadi `project.godot` sekarang
  `rendering_method="forward_plus"` (mobile/Web tetap GL Compatibility
  lewat `rendering_method.mobile`, dan fallback depth fog 0.06 tetap
  jalan di sana). Angka-angka di `Balance` (`VOL_FOG_*`,
  `FOG_DENSITY_VOLUMETRIC` 0.04).
- Hasil: pos + jalan dekat kebaca, hutan jauh tertelan, senter jadi
  kerucut cahaya lembut di kabut. Screenshot seri v13c
  (`~/workspace/godot/shots/v13c_*.png`): window, outside, forest, gate,
  desk. Jujur: lewat jendela belakang tidak ada pohon sama sekali, hanya
  kabut hijau-abu (itu memang brief-nya, tapi tanpa depth cue); kabut
  tidak bergerak/bertiup (tidak ada animasi angin bawaan); hanya
  terverifikasi di software Vulkan lavapipe, belum di GPU asli.
- Catatan sandbox: Forward+ butuh `mesa-vulkan-drivers` (lavapipe).
  Paket ini terpasang di sandbox; kalau sandbox di-reset, Godot gagal
  init Vulkan sampai paket itu dipasang ulang.

### Suara radio + SFX (v8)
- Radio sekarang **bersuara**: 5 klip suara Indonesia
  (`assets/audio/radio_voice_1..5.wav`, 16-bit mono 22050 Hz), dibuat
  dari gTTS `lang="id"` atas kalimat persis di `radio.gd`, lalu diproses
  jadi radio rusak (band-pass 300-3000 Hz, statis, pitch/speed
  bervariasi; baris ke-5 sengaja 0.90, lebih rendah + lambat).
  `radio.gd` `interact()` memutar klip yang cocok + statis; teks tetap
  tampil. Skrip pembuat: `tools/make_radio_voice.py`.
- SFX diperbaiki (`tools/synth_audio.py`): door creak tonal baru,
  footstep + crunch + pitch acak per langkah, giant thud 1.8 detik
  (sub sweep 80->30 Hz, peak 0.90), heartbeat lub-dub dengan harmonik.
  Verifikasi: `tools/audio_verify.py` PASS semua 12 WAV, test rig
  `mode=audio` semua jalur play menyala, `mode=playtest` PASS fails=0.
- Jujur: **belum pernah didengar telinga manusia** (sandbox tanpa
  sound card); yang terbukti adalah bentuk gelombang/spektrum + jalur
  play. Suara gTTS satu suara generik, bukan akting/karakter.

### Video gameplay (v8)
- `the-giant-gameplay.mp4` (di samping ZIP ini): H.264 1280x720 30 fps,
  **2 menit 54 detik, 146 MB**. Menu -> intro -> generator -> radio ->
  buku jaga -> pemburu 01:30 -> kaki Giant 03:30 -> mata Giant 04:45 ->
  ending 06:00 "Fajar". Direkam dari game beneran di Godot (Xvfb)
  dengan rig yang memakai Input sungguhan, bukan frame palsu.
- **Tanpa suara**: sandbox tidak punya sound card / jalur capture
  audio, Godot jalan di dummy audio driver. Tertulis di title card
  video. Waktu in-game dipercepat (lompat antar event) dan video
  gameplay 2x karena sandbox render ~2-3 fps di lavapipe; dua-duanya
  tertulis di title card video.
- Kaki Giant di video samar (sengaja: kabut + tidak pernah utuh);
  kalau mau lebih jelas perlu perubahan di game, bukan re-record.

## v9 (2026-11-16): mata + kaki Giant lebih jelas

Arya: "kenapa matanya atau langkahnya itu elemen gajahku" lalu
"lebih jelas aja". Keduanya memang dari sheet gajahnya Arya, dan
keduanya diperjelas di v9.

**Mata (04:45) — dari blob gelap jadi mata yang kebaca sekilas.**
- Crop ulang: 36x36 px di sheet, rongga TEPAT di tengah dan mengisi
  ~50% frame (ronde 1: rongga cuma ~35% lebar tekstur, tenggelam di
  kulit belang). Blotch gelap kedua sengaja di luar crop.
- Kulit diterangkan (brightness 1,8 + gamma 0,6) + kontras 1,45,
  supaya rongga gelap kontras dengan kulit di sekitarnya.
- Catchlight kecil DI bola mata asli (sheet ~(213,97), posisi dicek
  dengan marker di gambar): inti padat + glow blur halus, bukan
  cincin (cincin kelihatan seperti target).
- Di game: ukuran 1,1 -> 1,5 m, sprite unshaded, HDR modulate 2,2x,
  lampu kilau 0,7 -> 1,5. Perlu HDR karena tonemapper FILMIC proyek
  + kabut + shader VHS menggelapkan tekstur sampai ~39% (diukur:
  tekstur mean 103 -> window mean 40 sebelum HDR).
- Alat: `tools/make_giant_parts.py` (bisa di-run ulang).

**Kaki (03:30) — dari kolom kaki jadi telapak yang kebaca.**
- Akar masalah: pusat y 2,25 + tinggi 4,5 m -> telapak di y ~0, jauh
  di bawah ambang jendela (1,30-2,20), yang kelihatan cuma tengah
  kaki. Sekarang pusat y 2,8 + tinggi 3,4 m -> telapak di y ~1,1-1,9,
  tepat di band jendela. Kaki terangkat mid-stride (langkah raksasa).
- Debu baru: kepulan `fog_puff` di tanah di bawah kaki tiap dentum
  (memudar + mengembang 1,6 dtk). Tint kaki 0,5 -> 0,85.
- Potongan kaki BARU dari gajah samping sempat dicoba tapi GAGAL
  (terlalu sempit 1,1 m + terang, hilang di kabut, v14f); tekstur v5
  (kaki gajah depan, gelap + lebar 1,87 m) dikembalikan karena
  TERBUKTI kebaca sebagai siluet. Kode potongan gagalnya
  dinonaktifkan di `tools/make_giant_parts.py` sebagai arsip.

**Pelajaran penting (jangan diulang):** run headless Godot TANPA
`--import` TIDAK me-reimport tekstur yang filenya berubah (`.ctex`
di `.godot/imported/` tetap dari 08:40). Ronde 1-3 mata diuji
berjam-jam dengan tekstur LAMA tanpa sadar; baru ketahuan saat
`.ctex` dicek dan `--import` dijalankan. Selalu `--import` dulu
setelah ganti file tekstur sebelum screenshot.

**Verifikasi v9 (mode `shots14`, prefix v14g):** `v14g_foot.png`
(kaki + telapak di jendela), `v14g_foot_out.png` (kaki dari luar),
`v14g_eye.png` + `v14g_eye_close.png` (rongga + kilau). Regression:
mode verify exit 0, mode playtest PASS fails=0, headless 300 frame
tanpa script error.

**Batas jujur yang tersisa:** mata asli di sheet cuma ~15 px, jadi
tetap soft kalau dilihat dekat; yang diperbaiki keterbacaannya,
bukan detailnya. Kuku kaki tidak tajam (sumbernya juga tidak tajam);
yang kebaca adalah bentuk telapak (melebar + tepi bawah membulat),
bukan kuku satu-satu.

## v10 (2026-11-16): tata letak barang-barang dirapikan

Arya: "tata letak barang barang nya juga rapiin".

**Yang berantakan sebelumnya (dicek di kode + screenshot v12/v9).**
- Meja 1,7 m menampung 5 benda: radio, buku, meter, koran, surat
  berdesakan; meter setengah ketutup buku jaga; koran menjulur keluar
  tepi meja; hitbox surat tumpang dengan hitbox buku jaga (0,33 m).
- Koran + surat TERKUBUR di dalam papan meja sejak v7: permukaan meja
  sebenarnya y 1,11 (tengah papan 1,07 + setengah tebal 0,04), kertas
  di y 1,07 — cuma kelihatan dari sisi yang menjulur keluar meja.
  Ketahuan di screenshot `v15_desk_top` ronde 1: sudut depan meja kosong.
- Samping generator: gergaji, tong, karung, peti tersebar di x 4,4-5,3,
  z -3,6..1,4, tanpa garis. Halaman: tunggul, gading, jerat, darah,
  log, batu tersebar acak. Papan larangan gajah 1,4 m di depan garis pagar.

**Meja (baru: 2,2 x 0,8, grid 3 kolom x 2 baris, tiap benda punya zona).**
- Baris belakang (z 1,64): radio kiri (-1,98), meter tengah (-1,30,
  visual saja), lentera kanan (-0,55). Lentera PINDAH dari peti kayu
  ke meja, y naik 1,06 -> 1,27 supaya alas sprite tidak tenggelam.
- Baris depan (z 1,14): koran kiri (-1,98), buku jaga tengah (-1,30,
  z 1,20 supaya tidak menjulur keluar tepi), surat kanan (-0,55).
- Kertas lurus (rotasi 0, dulu 12/-8 derajat). Hitbox diperkecil
  (buku 0,6 -> 0,5 dalam, kertas 0,55 -> 0,5) supaya tidak ada yang
  saling tumpang — dicek dari angka, bukan kira-kira.
- Koran + surat naik ke y 1,12 (di ATAS permukaan meja 1,11).
  Peti kayu di sudut kanan sekarang kosong (tempat simpan).

**Samping generator (tidak ada bangunan gudang: generator di udara
terbuka menempel dinding timur pos).** Satu baris lurus di x 4,4,
sejajar dinding: karung z -3,8, tong z -3,2, gergaji z -2,5,
generator z -1,2 (rotasi -23 -> 0, sejajar dinding), peti rendah
z 0,4, peti tinggi z 1,2. Peti rendah pindah dari sisi barat pos
supaya peti-peti berkelompok.

**Halaman (tiga baris lurus, dibuktikan posisi di log verify).**
- Bukti penebangan, sisi barat jalan (x -4,5): tunggul z -6,5, jerat
  z -9,0, darah z -10,5, gading z -12,0.
- Kayu, sisi timur jalan (x 7,5): log z -5,5, tunggul z -7,0,
  batu z -8,5. Jejak kaki tetap di tengah jalan.
- Semak + pisang di garis pagar (z -14,5). Papan larangan gajah
  ditarik ke garis pagar (z -15,6), sejajar dua papan lain.
- Darah dibesarkan (0,007 -> 0,009) + diterangkan (1,3 -> 1,6).

**Verifikasi v10 (mode `shots15`, prefix v15c):** `v15c_desk_top`
(grid 3x2 lengkap: lentera-meter-radio belakang, koran-buku-surat
depan, stempel merah surat kelihatan), `v15c_desk_close` (meja dari
dekat, semua benda di zonanya), `v15c_desk_spawn` (dari spawn),
`v15c_shed_row` (generator merah + gergaji oranye + peti, menyusuri
baris dari selatan), `v15c_yard_close` (tunggul + jerat + gading),
`v15c_yard_door` + `v15c_gate_signs` (pagar + gerbang).
Regression: mode verify exit 0 (registry 42 nama, 0 missing, 186
Sprite3D), mode playtest PASS fails=0 (5 tugas), mode story PASS
fails=0 (koran + surat dibuka-tutup lewat E), headless 300 frame
tanpa script error. Posisi baris dikonfirmasi dari log verify
(semua x 4,4 / x -4,5 / x 7,5).

**Batas jujur yang tersisa:** darah di tanah tetap samar di malam
hari (decal gelap di tanah gelap + kabut) — posisinya benar di
baris bukti, tapi keterbacaannya terbatas; ujung jauh baris
generator (tong + karung) melebur ke kabut dari jarak 7 m, itu
kabut gamenya sendiri, bukan salah letak. Sprite buku jaga
(billboard) masih condong seperti disandarkan, bukan tergeletak
datar — begitu sejak v7, bukan regresi v10.

## v11 (2026-11-16): buku jaga tergeletak datar, tidak tumpang lagi

Arya: "itu masih tumpang tindih" (setelah melihat screenshot meja v10).

**Yang tumpang (dicek di screenshot v15c_desk_close + kode).**
Sampul buku jaga adalah billboard tegak 0,49 m yang selalu menghadap
kamera, ditempel di atas kotak buku yang datar: dari samping ia
berdiri seperti tenda dan menutupi radio + surat di belakangnya.
Kotaknya sendiri miring -14 derajat, tidak searah grid meja. Itu
bukan salah letak v10 — billboard-nya memang tidak pernah datar,
sejak v7. Hitbox-nya sendiri tidak tumpang (sudah dihitung di v10),
yang tumpang itu visualnya.

**Perbaikan meja.**
- Buku jaga: sampul jadi Sprite3D datar (`SpriteRegistry.flat`,
  baru) di atas kotak 0,36 x 0,40, rotasi 0, tepi atas sampul ke
  +z supaya terbaca benar dari kursi. Kotak tidak miring lagi.
  Hitbox diperkecil 0,55 x 0,5 -> 0,42 x 0,46, pas jejak buku.
- Diukur dulu pakai alpha bbox, bukan kira-kira: semua tekstur meja
  penuh tanpa margin bawah, jadi alas sprite radio/lentera/meter
  yang terkubur di papan meja itu nyata, bukan ilusi: radio
  terkubur 0,087 m, lentera 0,039 m, meter 0,045 m. Ketiganya
  diangkat supaya alasnya TEPAT di permukaan meja (1,11) dan
  hitbox-nya ikut digeser (radio 0,42 -> 0,6, tengah +0,13;
  lentera 0,6 -> 0,65, tengah +0,03).
- Audit hitbox meja sekarang dihitung di rig (mode verify), bukan
  cuma di komentar: 5 AABB, tumpang = 0.

**Bug sekelas yang ketemu di luar meja (diperbaiki, bukan dibangun ulang).**
- Jejak kaki + jerat adalah billboard tegak di tanah: jejak kaki
  berdiri seperti kartu di tengah jalan. Keduanya pindah jadi decal
  datar seperti darah (jejak ~0,5 m, jerat ~0,9 m, y 0,05). Tint
  merah darah tidak lagi ikut ke decal lain.
- Papan tanda di pagar: sprite-nya di sisi jauh papan (z -0,12),
  ketutup papan dari arah jalan. Pindah ke sisi jalan (+0,05):
  "TAMAN NASIONAL MALAYUNESIA" sekarang kebaca dari jalan.
- Tiang papan tanda tanpa material (putih default): itu dua garis
  putih di shot v15c_gate_signs. Sekarang pakai material kayu yang
  sama dengan papannya.

**Verifikasi v11 (mode `shots16`, prefix v16):** `v16_desk_top`
(buku datar di tengah, sampul kebaca, prompt Buku Jaga muncul),
`v16_desk_close` (dari samping, buku tipis tergeletak, radio +
surat tidak ketutup), `v16_desk_spawn` (dari spawn), `v16_desk_side`
(dari ujung timur meja), `v16_sign_park` (papan kebaca dari jalan,
tiang kayu bukan putih), `v16_footprint` (jejak sepatu datar di
jalan), `v16_yard_close` (jerat datar + darah, zoom crop).
Regression: mode verify exit 0 (registry 42 nama, 0 missing, 186
Sprite3D, audit hitbox tumpang=0), mode playtest PASS fails=0
(5 tugas, log lewat E), mode story PASS fails=0, headless 300 frame
tanpa script error.

**Batas jujur yang tersisa:** dari sudut samping murni (ujung
meja), tiga benda baris belakang (lentera-meter-radio) menumpuk
dalam proyeksi — itu paralaks baris yang dilihat dari ujungnya,
bukan benda menempati zona yang sama; dari spawn/atas/dekat
masing-masing tetap terbaca terpisah. Jerat + darah tetap samar
di malam hari (kawat tipis + decal gelap di tanah gelap); jejak
kaki kebaca jelas dari dekat, samar dari jauh. Video gameplay v8
masih pakai layout lama; tidak di-re-record di tugas ini.

## v13 (2026-11-16): mouse look tidak kekunci lagi

Arya main build Windows v12: "gabisa gerakin viewnya pake mouse
kek kekunci".

**Reproduksi dulu (mode rig baru `mouselook`, prefix v17), sebelum fix:**
fails=4. Setelah intro ditutup mouse_mode tetap VISIBLE (0),
bukan CAPTURED (2). Klik di tengah layar juga tidak menangkap
mouse (tetap 0). Setelah dokumen ditutup, mouse_mode tetap 0.
Satu-satunya yang benar: pause/resume (ESC) sudah mengembalikan
CAPTURED.

**Dua akar masalah, bukan satu.**
- `close_intro()` dan `close_document()` di `hud.gd` tidak pernah
  mengembalikan `MOUSE_MODE_CAPTURED` (hanya `toggle_pause()` yang
  melakukannya). Pemain baru harus klik dulu, tanpa petunjuk apa pun.
- Yang lebih dalam: dot crosshair + semua label HUD default
  `MOUSE_FILTER_STOP`, jadi mereka memakan event mouse. Terbukti
  lewat isolasi: setelah mouse CAPTURED lewat klik area kosong,
  gerak mouse di tengah layar (640,360, tepat di atas dot) delta
  yaw = 0, tapi gerak yang sama di (100,500) jauh dari dot delta
  yaw = -0,264. Di Windows asli, mouse yang di-capture selalu
  di-warp ke tengah layar, tepat di atas dot — jadi mouse look
  kemungkinan tidak pernah bisa jalan sama sekali, bahkan saat
  mouse sudah CAPTURED.

**Perbaikan.**
- `close_intro()` + `close_document()`: kembalikan CAPTURED saat
  tidak ada panel lain yang terbuka.
- `player.gd`: tangkap mouse juga di `_input` (bukan cuma
  `_unhandled_input`), supaya klik yang dimakan GUI tetap
  menangkap mouse. Aman saat pause: `_input` pemain tidak jalan
  saat tree di-pause, jadi klik tombol panel tidak ikut menangkap.
- Semua label/bar/dot/stats HUD jadi `MOUSE_FILTER_IGNORE`
  (panel + tombol tetap STOP, mereka butuh klik).
- Petunjuk baru di tengah layar, "Klik untuk mengunci mouse",
  muncul hanya saat game jalan tapi mouse belum CAPTURED (mis.
  habis Alt-Tab), sembunyi sendiri begitu mouse terkunci.
  Screenshot bukti: `v17_hint.png`.

**Verifikasi v13 (mode `mouselook`, prefix v17):** PASS fails=0
(intro -> CAPTURED, klik tengah + gerak di tengah delta yaw
-0,264, tutup dokumen -> CAPTURED, pause/resume benar, hint
muncul saat Alt-Tab simulasi dan hilang setelah klik).
Regression: mode verify exit 0 (registry 42 nama, 0 missing,
audit hitbox meja tumpang=0), mode playtest PASS fails=0,
headless 300 frame 0 script error.

**Batas jujur yang tersisa:** konfirmasi akhir hanya bisa dari
Arya di Windows asli (sandbox pakai event sintetis + Xvfb, bukan
mouse hardware). Jerat + darah tetap samar di malam hari. Video
gameplay v8 masih pakai layout lama; tidak di-re-record di tugas ini.

## v14 (2026-11-17): atmosphere pass — kabut, cahaya, VHS, kamera, audio

Suasana dulu, sesuai pilihan Arya ("Suasana horor dulu"). Tidak ada
perubahan gameplay: tidak ada sistem/tugas/event/AI baru. Semua angka
baru di `scripts/balance.gd`, satu tempat tune seperti biasa.

**Kabut + gelap (level-design).**
- Alpha gumpalan kabut sekarang digrading menurut jarak (dekat 0,38,
  jauh 0,26; ground fog 0,42 -> 0,32) supaya kabut punya lapisan,
  bukan satu veil datar.
- 5 gumpalan tetap di mid-ground (10-12 m, posisi tetap supaya shot
  bisa dibanding): 3 di selatan pos, 2 di utara jalan.
- Kurva malam (`main.gd`): bulan 0,75 -> 0,55 (02:00) -> 0,85
  (06:00), ambient 0,65 -> 0,50 -> 0,70, fog volumetrik 0,030 ->
  0,036 -> 0,028. Semua lerp pelan (konstanta ~2 dtk).

**Cahaya (level-design: guide with light).**
- Lampu teras + lampu generator berkedip saat bahan bakar < 25
  (makin parah < 10): redup singkat 0,3-0,6x tiap irisan 0,15 dtk,
  peluang 15% / 30%. Bukan strobo, bukan kilat terang.
- Gerbang + topeng pemburu + gajah jauh + wajah papan tanda jadi
  UNSHADED (tint redup 0,55-0,65): dulu hitam total di gelap karena
  membelakangi bulan (polish #6). Preseden: mata Giant sudah
  unshaded + HDR sejak v9. Fog tetap berlaku, jadi mereka tetap
  tertelan kabut di jarak jauh.

**Kamera (game-feel + camera-systems).**
- Shake diganti trauma^2 + summed sines, meluruh di real time
  (dulu `randf_range` tiap frame — skill game-feel: "buzzes like
  static"). Bob dan shake sekarang digabung sekali di
  `camera.position`, tidak saling menimpa y; roll maks 0,01 rad.
- FOV 72 -> ~70,3 saat Sanity < 35 (terowongan), -1,5 lagi saat
  event Giant aktif; semua di-ease `1-exp(-rate*dt)`.
- Intro: slow pan +-6 derajat dalam 24 detik (polish #8); yaw
  dikembalikan ke 0 saat intro ditutup (terbukti di log rig).

**Audio (audio-design + godot-audio).**
- Bus layout baru (`default_bus_layout.tres`): Master <- Ambience /
  SFX / Voice. Sebelumnya semua di Master.
- Ambience di-duck -6 dB (tween 0,25 dtk) saat siaran radio bersuara,
  kembali saat siaran habis.
- Jangkrik malam baru (`assets/audio/crickets.wav`, disintesis
  `tools/synth_audio.py`, 2 jangkrik 4,2/4,6 kHz, peak 0,3, di-mix
  -30 dB): centroid terukur 4402 Hz, 100% energi > 3 kHz.
- Dentum jauh: Giant terdengar dari kejauhan (thud -20 dB, pitch
  0,8) tiap 90-180 detik di jam 23:00-03:20, tidak saat event
  pemburu/Giant aktif, tidak saat radio bersuara.

**VHS (hud.gd).**
- Rolling band baru: pita terang redup merayap ke bawah (amplitudo
  0,03, satu putaran 20 dtk). Tear/scanline/CA tidak diubah.
- Grain/desat/vignette ikut Sanity: grain 0,13 -> 0,16, desat
  0,45 -> 0,52, vignette 0,38 -> 0,45 saat Sanity < 35.

**Verifikasi v14 (mode rig baru `shots18`, prefix v18).**
- `tools/verify_atmosphere.tscn` (cek numerik, headless): PASS 19/19
  (bus ada, wind + crickets jalan di bus benar, porch kedip min
  0,34/max 0,90, generator kedip min 0,26/max 0,70, trauma 1,0 ->
  0,40 (0,5 dtk) -> 0,000 (2 dtk), FOV 70,52 di Sanity 20, bulan
  0,57 + vol 0,0353 jam 02:00, dentum jauh bunyi).
- `tools/frame_stats.tscn` (headless, 600 frame): avg 0,00 ms,
  p95 0,01 ms, 0/600 di atas budget 16,6 ms (CPU saja, tanpa GPU).
- Rig: verify DONE (hitbox meja tumpang=0), shots DONE, shots16
  DONE, shots18 DONE (8 shot), mouselook PASS fails=0 (fix v13
  utuh), playtest PASS fails=0 (5 tugas), story PASS fails=0,
  audio DONE (semua siaran jalan, footstep pitch 0,92-1,08).
  Tidak ada SCRIPT ERROR / SHADER ERROR di log mana pun.
- Before/after: `v18base_*` (v13) vs `v18_*` (v14) di
  `~/workspace/godot/shots/`. Gerbang tanpa senter sekarang kebaca
  (papan + pagar + celah gerbang), papan tetap kebaca dengan senter,
  mata Giant tidak berubah, interior/meja tidak berubah.

**Batas jujur yang tersisa (v14).**
- Jendela belakang tetap dinding kabut: dua ronde coba memberi
  struktur (grading + gumpalan tetap, lalu gumpalan gelap) tidak
  menaikkan std jendela (14,1 vs 15,9 baseline). Pada 0,07/m,
  billboard di 10-14 m cuma ~40% kebaca dengan latar kabut sewarna
  + desaturasi VHS. Gumpalan gelap dibatalkan (cuma jadi noda samar).
- Kurva malam terukur di angka (bulan 0,57 jam 02:00) tapi beda
  layarnya tipis: mean frame night_deep vs night_dawn 37,3 vs 37,1.
  Sengaja halus, bukan siklus siang-malam.
- Audio belum pernah didengar telinga manusia (sandbox tanpa sound
  card): jangkrik + dentum jauh + ducking baru terbukti bentuk
  gelombang + jalur play, bukan bunyinya. Mix tetap konservatif.
- GPU tidak terukur di sandbox (headless tanpa renderer): tidak ada
  lampu/shader pass baru, jadi biaya GPU praktis sama dengan v13,
  tapi angka pastinya butuh Windows asli.
- Kabut volumetrik yang BERGERAK tetap dipotong sesuai brief
  (billboard statis cukup); yang berubah hanya grading + posisi
  gumpalan, bukan animasi kabut.

## Yang masih placeholder / belum ada

- Model masih berupa kotak + sprite billboard; ini prototipe gameplay, bukan build visual final.
- Audio tetap sintesis prosedural dan **belum pernah didengar telinga
  manusia** (sandbox tanpa sound card); yang diverifikasi adalah bentuk
  gelombang + jalur play (lihat "v5" di bawah).
- Export Android belum pernah dicoba: tidak ada Java/Android SDK di
  sandbox, jadi APK tidak bisa dibangun di sini. Preset-nya ada, tapi
  belum terbukti.
- Export Windows: **sudah dijalankan Arya di Windows asli (v12,
  2026-11-16)** — game jalan sampai intro, bug mouse look ketemu
  dari main sungguhan (diperbaiki di v13). v11 sempat rusak (zip
  tanpa .pck), diperbaiki di v12.
- Proyek ini **sudah diuji di Godot 4.3 headless** (2026-11-16): `--import` bersih setelah dua sheet sumber yang tadinya JPEG ber-ekstensi .png dikonversi ke PNG asli, dan game jalan 300 frame tanpa script error. Peringatan mesh di headless dummy renderer bukan error game.

## v5 (2026-11-16): tech debt + menu/save/pause/touch + mata baru

Semua technical debt dari review v4 dikerjakan berurutan, satu per satu,
dan diverifikasi sebelum lanjut. Yang tidak berubah: gameplay inti,
cerita, satire Malayunesia, satu level, satu pos jaga (bukan rumah).

### 1. Level terpusat (`scripts/level_data.gd`)
Semua posisi/ukuran penting (pos 5x4x2,6 m, lantai 0,35 m, pintu,
jendela, pagar z=-16, gerbang, papan tanda, 16 properti berserakan, 12
billboard, posisi spawn pemburu/Giant) pindah ke satu file data.
`main.gd` menerapkan posisi spawn + benda interaktif dari sana saat
`_ready`, jadi `main.tscn` bukan lagi satu-satunya sumber kebenaran.
Level **masih code-built** (bukan scene editor): keputusan sadar, satu
file data + kode builder lebih gampang di-diff dan di-review daripada
scene biner.

### 2. Sprite registry (`scripts/sprite_registry.gd`)
Dulu sprite di-load dengan string dinamis `"sprites/%s.png"` di 9 tempat;
salah ketik = sprite hilang diam-diam. Sekarang 42 nama terdaftar di
`ALL_NAMES`, load lewat `SpriteRegistry.texture()` /
`SpriteRegistry.billboard()` yang memberi `push_error` jelas kalau nama
tidak terdaftar atau file hilang. Audit: test rig `mode=verify`
(`SpriteRegistry.validate()`): 42 nama, 0 hilang.

### 3. Test rig ikut proyek
`scenes/test_rig.tscn` + `scripts/test_rig.gd` dan
`scenes/test_menu.tscn` + `scripts/menu_shot.gd` **ikut ZIP** (dulu cuma
alat luar). Jalankan:
`Godot --path . scenes/test_rig.tscn -- mode=<mode> prefix=<prefix>`
Mode: `shots` (screenshot seri), `verify` (audit sprite + registry),
`win` / `lose` (jalur menang/kalah), `audio` (jalur play + file WAV),
`touch` (kontrol sentuh + joystick), `pause` (menu jeda),
`save` (roundtrip save/load), `playtest` (satu shift penuh dengan input
simulasi pemain manusia). Menu: `Godot --path .
scenes/test_menu.tscn` (tanpa save -> dengan save -> tombol Lanjutkan),
dan `Godot --path . scenes/menu.tscn -- menu_autostart=1` untuk
membuktikan tombol MULAI masuk ke scene main. Log + screenshot ke
`~/workspace/godot/shots/` kalau folder itu ada, kalau tidak ke
`user://shots/`.

### 4. Audio: dentuman Giant dedikasi
`giant_thud.wav` **baru, disintesis khusus** (`tools/synth_audio.py`):
sub sine 75->34 Hz + gemuruh noise lowpass + dentuman kedua tertunda
0,45 detik, 1,4 detik, puncak spektrum 41 Hz. Dulu ini footstep yang
sama dipelankan pitch 0,45; sekarang `audio.gd` memainkan
`giant_thud.wav` di pitch 1,0. `wind.wav` (4 dtk, loop crossfade +
hembusan), `footstep.wav` (0,25 dtk, puncak 84 Hz), `heartbeat.wav`
(1,2 dtk, lub-dub 55 Hz) disintesis ulang; `generator_hum`,
`radio_static`, `door_creak` tidak disentuh (sudah cukup). Verifikasi:
bentuk gelombang + spektrum (numpy/FFT) dan `mode=audio` (semua 7 WAV
termuat, semua jalur play menyala, heartbeat nyala di Sanity 30 dan
berhenti di 100). **Tetap belum pernah didengar telinga manusia.**

### 5. Balance terpusat (`scripts/balance.gd`)
Jam event (01:30/03:30/04:45), drain Sanity/Stability, drain bahan
bakar, ambang heartbeat, kecepatan pemain: semua dibaca dari satu file
oleh `game_state.gd`, `main.gd`, `hunter_event.gd`, `giant_event.gd`,
`audio.gd`, `player.gd`. Angka tidak berubah, hanya pindah.

### 6. Export nyata (Windows + Web)
Export Templates Godot 4.3 dipasang, lalu export beneran dari proyek ini:
Windows Desktop (`builds/windows/THE-GIANT.exe`, PE x86_64) dan Web
(`builds/web/index.html` + `.pck` + `.wasm`, dicek serve lokal +
respons HTTP 200). Cara export ulang: Project > Export, atau
`Godot --headless --path . --export-release "Windows Desktop"
../builds/windows/THE-GIANT.exe` (dan `"Web"`). Android **belum**:
tidak ada Java/Android SDK di sandbox (`which java/adb/sdkmanager`
kosong, `ANDROID_HOME` tidak disetel), jadi APK tidak dibangun; preset
Android tetap ada di `export_presets.cfg` untuk nanti.

### 7. Mata Giant lebih tajam (item 8)
Mata asli di sheet Arya ternyata cuma ~25 px, jadi crop lama (kulit
70x65 + rongga 36x28) tidak bisa tajam dengan cara apa pun. Perbaikan:
**crop rapat baru** di sekeliling rongga mata (60x56 px di sheet,
di-upscale Lanczos ke 360x336 + kontras 1,4), satu sprite saja
(`giant_eye.png`), dipasang 1,1 m tepat di tengah jendela, plus kilau
0,7. `giant_eye_socket.png` dihapus. Terverifikasi screenshot
`v10_eye` / `v10_playtest_eye` (04:48): mata gelap besar dengan kilau
memenuhi jendela dan kebaca jelas sebagai mata. Batas jujur: upscale
tidak menambah detail baru; mata tetap lembut kalau dilihat dekat,
karena sumbernya memang 25 px.

### 8. Git repo
Working copy sekarang repo git (`git log`: `33a6d5f v5: ...`). `.git`
**tidak ikut ZIP** (ZIP tetap deliverable utama); `.gitignore`
mengeluarkan `.godot/`, `*.import`, dan `builds/`.

### 9. Playtest end-to-end (item 10) — PASS
`mode=playtest` mensimulasikan pemain manusia: jalan pakai
`Input.action_press` sungguhan + raycast + tombol E via
`Input.parse_input_event` (bukan lompat waktu). Urutan: buka pintu,
keluar pos, nyalakan generator, kembali masuk, cek radio, tulis
laporan, matikan + nyalakan lentera, tutup pintu, lewati pemburu 01:30
dengan pintu tertutup 12 detik, kaki Giant 03:30, mata Giant 04:45,
bertahan sampai 06:00. Hasil: **fails=0 -> PASS**, semua 5 tugas
selesai, Sanity akhir 100. Log lengkap:
`~/workspace/godot/shots/v10_results_playtest.txt`.

### Bug gameplay yang ketemu playtest (diperbaiki di v5)
- **Dinding tak terlihat di tengah pos**: `_make_tree` di `main.gd`
  dulu cuma mengisi `body.position.y`, x/z tetap 0, jadi ~104 silinder
  tabrakan pohon menumpuk di origin (0,0,0) dan pemain tidak bisa jalan
  lurus ke pintu. Ketemu lewat `mode=touch` (tabrakan dengan StaticBody
  parent Forest di (0, 2.77, 0)). Perbaiki: `body.position = pos +
  Vector3(0, h*0.5, 0)`.
- **Pemain bisa keluar tapi tidak bisa kembali masuk**: anak tangga
  0,12 m memblokir CharacterBody3D yang jalan masuk (tidak ada lompat
  di game ini). Perbaiki: tangga jadi visual saja + **ramp miring
  tak terlihat** dari tanah ke lantai (~16 derajat).
- Dua jebakan rig (bukan bug game): `Input.action_press("interact")`
  tidak memicu `_unhandled_input` (pakai `parse_input_event`), dan
  pintu yang terbuka harus dibidik di panelnya yang mengayun
  (-0.6, 1.4, -1.5), bukan di celah kosong.

### Yang terverifikasi di v5 (Godot 4.3, Xvfb 1280x720)
`v10_menu_no_save` + `v10_menu_with_save` (menu + Lanjutkan aktif),
`v10_touch` (tombol E/SENTER/II + hint) + joystick jalan 2,85 m sampai
pintu tertutup (kecepatan 3,2 m/detik), `v10_pause` (menu JEDA),
`v10_eye` (mata baru), `v10_foot` (kaki lewat jendela), `v10_hunter_*`
(pemburu), `v10_door_vhs`/`v10_desk_vhs`/`v10_outside_porch`,
`mode=verify` (149 Sprite3D, 36 unik, registry 42/42),
`mode=win` (menang), `mode=lose` (kalah), `mode=save` (roundtrip
cocok), `mode=audio` (7 WAV + jalur play), `mode=playtest` (PASS),
export Windows + Web (file ada, Web serve lokal 200).
Yang **tidak** terverifikasi: bunyi audio oleh telinga manusia, export
Windows dijalankan di Windows, APK Android, dan shift penuh dimainkan
oleh manusia sungguhan (rig mensimulasikan, bukan menggantikan).

## Struktur

```
the-giant-godot/
  project.godot          scene utama = menu, autoload, InputMap
  export_presets.cfg     Windows / Android / Web
  icon.svg
  scenes/
    menu.tscn            menu utama / layar intro
    main.tscn            scene utama (ramping, level dibangun dari kode)
    test_rig.tscn        rig uji (ikut ZIP sejak v5)
    test_menu.tscn       uji menu (ikut ZIP sejak v5)
  scripts/
    game_state.gd        autoload: sanity, stability, fuel, tugas, jam
    balance.gd           SATU file angka balance (v5)
    level_data.gd        SATU file posisi/ukuran level (v5)
    sprite_registry.gd   registry + validasi sprite (v5)
    save_game.gd         save/load shift JSON (v5)
    main_menu.gd         menu utama (v5)
    touch_controls.gd    joystick + tombol sentuh (v5)
    player.gd            first-person controller
    main.gd              terrain, hutan, pagar, loop shift
    guard_post.gd        bangunan pos jaga + pintu
    hud.gd               HUD dari kode + menu jeda (v5)
    audio.gd             manajer audio
    hunter_event.gd      event dua pemburu 01:30
    giant_event.gd       event kaki Giant 03:30 + mata Giant 04:45
    test_rig.gd          rig uji: shots/verify/win/lose/audio/
                         touch/pause/save/playtest/story/shots12 (v7)
    menu_shot.gd         uji menu headless (v5)
    interactables/       generator, radio, logbook, lantern, door,
                         readable (v7: koran + surat)
  design/
    game-brief.md        brief satu halaman + cek per baris + cut +
                         polish list (v7, cara kerja Claude Code
                         Game Studios)
  tools/
    synth_audio.py       sintesis WAV prosedural (v5, numpy)
  assets/
    source/              dua sprite sheet asli (utuh)
    sprites/             potongan individual transparan (42, v5)
    audio/               WAV hasil sintesis prosedural (7, v5)
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=xq7dtvgn&utm_source=github&utm_medium=readme&utm_campaign=best-game-01) · AI agents build software for cash rewards</sub>
