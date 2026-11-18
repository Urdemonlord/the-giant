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

## Android (APK, v18, 2026-11-17)

APK sudah dibangun dan terverifikasi di sandbox (bukan janji):

- **Release** `the-giant-v18-android-release.apk` (30,3 MB): package
  `id.meowlabs.thegiant`, versionCode 18, versionName 1.8.0, targetSdk
  34, minSdk 21, landscape, launchable activity `com.godot.game.GodotApp`.
  Di-sign keystore rilis Meow Labs, `apksigner verify` lolos, tidak
  debuggable.
- **Debug** `the-giant-v18-android-debug.apk` (31,6 MB): sama, tapi
  di-sign debug keystore Godot dan debuggable (untuk tes di HP).
- Kedua APK lolos `aapt2 dump badging` dan `unzip -t` (tidak korup).

**Cara install di HP (sideload):** kirim APK ke HP, ketuk file-nya,
izinkan "Install dari sumber tidak dikenal" kalau diminta, lalu
install. HP harus Android 5.0+ (API 21), arsitektur arm64. Mainkan
dalam posisi landscape; game berjalan immersive (layar penuh).
Kontrol sentuh sama seperti di atas: joystick kiri jalan, geser kanan
untuk melihat, E / SENTER / II.

**Batas jujur:** APK belum pernah di-install dan dimainkan di HP asli
(tidak ada device/emulator di sandbox); touch controls baru
diverifikasi rig (`mode=touch`), bukan jari manusia. Volumetric fog
butuh Forward+ dan tidak jalan di Android (GL Compatibility, fallback
ke exponential fog + billboard, sama seperti Web).

**Build ulang:** butuh JDK 17 (`~/jdk17`) + Android SDK
(`~/android-sdk`: cmdline-tools, platform-tools, build-tools 34.0.0,
platform android-34; `ANDROID_HOME=~/android-sdk`). Godot 4.3 headless:
`--export-debug "Android"` / `--export-release "Android"`. Keystore
rilis ada di `android-release.keystore` (alias `thegiant`, berlaku
sampai 2054-04-04, JANGAN hilang: update APK wajib pakai keystore
yang sama, dan file ini di-gitignore); password-nya di
`~/.local/share/godot/keystores/release-keystore-pass.txt` (mode 600,
di luar repo). Preset `export_presets.cfg` menyimpan path + alias
keystore, password-nya TIDAK di-commit dan diisi lewat env
`GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` saat export.

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

## Menu utama: sprite Main UI (2026-11-18, v19)

Keluhan Arya: menu masih jelek banget. Yang generik di v18: judul
"THE GIANT" Label font default Godot 64px, tombol StyleBoxFlat
polos, teks melayang di atas backdrop tanpa permukaan. Sekarang menu
punya sprite sendiri (`tools/make_menu_sprites.py`, bisa dijalankan
ulang, seed tetap):
- `menu_logo.png` (1000x280): judul huruf berat (Noto Serif Display
  Black) warna Putih Tulang, ghost merah/lumut geser (tracking VHS),
  satu pita tear, scanlines, debu.
- `menu_ledger.png` (460x600): kertas buku jaga gelap — glow lampu
  dari pojok kiri atas (satu sumber cahaya), garis aturan, noda
  kopi + lembap, sudut terlipat, stempel "POS 07" merah di pojok
  kanan atas. Seluruh kolom menu + Options duduk di atas kertas ini.
- `menu_btn.png` / `menu_btn_hover.png` / `menu_btn_pressed.png`
  (460x64): strip kertas berjahit putus-putus; hover ada garis
  Kuning Lampu di tepi kiri, pressed lebih gelap + cap merah.
- `menu_rec.png`: dot REC merah dengan glow, dipakai di samping
  teks "REC   CAM 07".
- Ikon lentera + jejak kaki TIDAK dibuat ulang: potongan sheet Arya
  (`lantern.png`, `footprint.png`). Lentera jadi ikon tombol
  Continue saat ada simpanan; jejak samar miring di bawah tombol Exit.
- Font seluruh menu diganti ke DejaVu Sans Mono Bold
  (`assets/fonts/`, lisensi bebas): suara UI kamera, sesuai design
  read. Font default Godot sudah tidak ada lagi di menu utama.

Semua sprite baru kelas PLACEHOLDER (aturan aset Arya: yang digambar
prosedural itu placeholder, bukan art final). Registry naik 54 ke 60
nama, 0 missing.

Dua bug ketemu dari screenshot, bukan dari teori: (1) TextureRect
Godot default `EXPAND_KEEP_SIZE` menggambar tekstur pada ukuran
aslinya dan mengabaikan `custom_minimum_size` — ronde 1 logo 1000px
meluber selebar layar dan lentera 311px. Perbaiki: semua TextureRect
menu pakai `EXPAND_IGNORE_SIZE`. (2) Stempel "POS 07" di (358,96)
tertutup huruf T logo dan terbaca "PUS 07" — pindah ke (395,42),
di atas logo. Lentera kecil di baris kepala dihapus: pada 16x32 ia
terbaca sebagai bintik debu, bukan lentera.

Terverifikasi lewat rig v22 + screenshot 1280x720 dan portrait
720x1280 (`v22_menu_no_save`, `_pan`, `_options`, `_with_save`,
desktop + portrait): logo utuh, tombol tidak tumpang tindih, tidak
ada elemen default yang lolos di menu utama, Continue aktif dengan
ikon lentera saat ada save. Mode verify PASS (registry 60, 0
missing, audit hitbox meja 0), mode playtest PASS fails=0 (5 tugas,
Sanity 100). Batas jujur: slider volume + CheckButton di Options
masih kontrol default Godot (fungsional, belum di-skin); HUD di
dalam game masih font default (menu saja yang diganti mono);
sprite-sprite ini placeholder, art final butuh gambar tangan.

## Menu utama: sprite Main UI REDO dari referensi asli (2026-11-18, v20)

v19 dibuat prosedural dari nol tanpa referensi foto asli — melanggar
langkah "start from a real reference" di skill game_asset_delivery.
v20 menggambar ulang semuanya dari referensi yang sudah ada di ide
THE GIANT (`tools/make_menu_sprites_v20.py`, referensi di
`tools/ref/REFERENCES.md`):
- `menu_logo_v20.png` (920x240): judul "THE GIANT" di Noto Sans
  Black, grotesque berat yang sama dengan judul cover moodboard v3
  hal. 1 + header storyboard v2 hal. 1. Garis Merah REC di bawah
  judul (cover moodboard), ghost merah (chromatic aberration frame
  VHS moodboard hal. 2), satu pita tracking tear yang menggeser
  sebagian huruf (binding rule storyboard hal. 1: "tracking
  robek"), grain dari high-pass area kabut foto hutan Sumatra
  berkabut (foto asli National Geographic, cover moodboard).
  Margin dalam 40px: logo tidak lagi terpotong di tepi kiri
  portrait (bug v19).
- `menu_ledger_v20.png` (460x600): FOTO kertas asli (Vecteezy free
  photo 57329614, kertas perkamen kusut/bernoda/tepi sobek),
  di-grade gelap ke palette kunci. Kerut, noda, dan tepi sobeknya
  dari foto itu. Garis aturan + jahitan jilid meniru foto logbook
  "Notes and Notams" (foto itu TIDAK dipakai sebagai tekstur:
  tulisannya memuat nomor telepon asli). Glow lampu pojok kiri
  atas (satu sumber cahaya).
- `menu_btn_v20*.png` (460x64): foto kertas yang SAMA dengan
  ledger, crop beda. Hover garis Kuning Lampu kiri, pressed lebih
  gelap + garis bawah Merah REC.
- `menu_stamp_v20.png`: cap basah "POS 07" sebagai node terpisah
  (bukan di tekstur ledger): di Options, teks instruksi yang
  di-scroll menimpa posisi stempel kalau stempel menempel di
  kertas. Node hanya tampil di menu utama.
- `menu_rec_v20.png`: dot REC mengikuti label REC moodboard.
- Sub-teks dipecah jadi baris pendek eksplisit ("Taman Nasional
  Malayunesia." / "Shift malam 22:00 - 06:00.") supaya tidak
  membungkus di tengah frasa (bug v19).

Dua bug ketemu dari screenshot v23: (1) Scanline di sprite +
scanline shader VHS menu = garis padat seperti tirai di seluruh
ledger/logo/tombol. Perbaiki: scanline dihapus dari sprite,
shader menu yang memberi scanline. Grain sprite juga dikurangi
separuh. (2) Stempel di tekstur ledger menimpa teks "Cara main"
di Options — pindah jadi node terpisah yang disembunyikan saat
Options dibuka.

Terverifikasi lewat rig v23 + screenshot desktop 1280x720 dan
portrait (`v23_menu_no_save`, `_options`, `_with_save`): logo utuh
penuh di desktop dan portrait (zoom crop dicek), sub-teks satu
baris per frasa, stempel terbaca penuh di menu utama dan hilang
di Options, tombol tidak tumpang tindih. Mode verify PASS
(registry 61, 0 missing). Mode playtest PASS fails=0 — TAPI hanya
di Xvfb; di headless murni playtest flaky di langkah radio
(fails 2-7, prompt radio kosong karena raycast belum update
setelah aim). Flaky ini SUDAH ADA di kode v19 (dibuktikan: stash
v20, playtest kode v19 murni juga fails=2) — bukan regresi v20,
dan bukan urusan sprite menu. Perlu perbaikan rig/playtest
terpisah (mis. tunggu physics frame setelah aim, bukan cuma 3
frame proses). Batas jujur: sprite v20 masih kelas PLACEHOLDER
(huruf/stempel typeset, kertas foto stok — tiap piksel tekstur
dan kerusakan punya referensi foto asli, tapi art final tetap
butuh gambar tangan); label kepala "Buku jaga, Pos 07" sedikit
terpotong 1px di render portrait letterbox (artefak skala,
di desktop utuh); slider + CheckButton Options dan HUD dalam
game masih default (belum di-skin).

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

## Menu utama: nyatu dengan background — Giant di kabut (2026-11-18, v21)

Keluhan Arya: menu v20 3/10, "ga nyatu ama background nya". Diagnosis dari
screenshot v23: kertas buku jaga fully opaque (alpha 255 di semua tepi)
jadi tampil sebagai persegi keras yang ditempel; backdrop 3D tidak punya
satu pun elemen gajah (kamera menu menghadap selatan, yaw 209, sedangkan
gajah level ada di utara, di belakang kamera) — menu terasa kosong.
Perbaikan, semua di scene 3D yang sama (kabut + VHS + cahaya bulan yang
sama), bukan hiasan UI:
- Siluet Giant di kabut selatan pos (`main.gd _setup_menu_giant()`,
  HANYA di backdrop menu): `menu_giant_v21.png` = elephant_shadow dari
  sheet Arya dibalik horizontal (kepala menghadap pos) + grade malam
  (`tools/make_menu_giant_v21.py`). 13 m, di kanan frame, badan terpotong
  tepi kanan (aturan: Giant tidak pernah utuh), kaki kelihatan di bawah
  (itu yang membuatnya terbaca sebagai hewan, bukan bukit).
- Kabut di tepi kanan kertas: dua fog_puff dekat kamera (d=4-5 m, UNSHADED,
  alpha 0.5) di garis x=548, melembutkan batas kertas dari samping.
- Kertas v21 (`tools/make_menu_sprites_v21.py`, dari foto yang sama):
  tepi sobek alpha (22.175 px transparan) + cahaya hangat Kuning Lampu di
  tepi kanan (lampu teras pos ada di kanan panel).
- GAGAL dan dibuang: kaki raksasa (ronde 1 dibaca batang pohon, ronde 2
  hilang); kilau mata giant_eye (crop persegi tampil sebagai kotak abu-abu
  melayang di langit seperti glitch — dihapus ronde 4, tanpa pengganti).
  Ronde gajah: 1) d=28 m shaded gelap = tidak kelihatan; 2) d=20 m unshaded
  pale = muncul tapi dibaca bukit (kaki ketutup pos); 3) geser kanan
  r=+17 m + mata = kaki kelihatan, mata gagal; 4) mata dihapus, final.

Terverifikasi lewat screenshot Godot 4.3 Xvfb, seri v24 (dilihat satu-satu,
4 ronde): desktop 1280x720 `v24_menu_with_save` + `_pan` (komposisi bertahan
sepanjang sapuan kamera +-5 derajat), portrait 720x1280 `v24_portrait/` (gajah
+ kabut tetap kelihatan di letterbox). Rig menu PASS (4 tombol, slop 0,
settings persist, Continue, Exit); mode verify PASS (registry 63, 0 missing);
mode playtest PASS fails=0 (5 tugas, Sanity 100, Stability 100);
menu_autostart=1 masuk scene main. Batas jujur: kepala/belalai Giant masih
halus (yang membuat terbaca sebagai hewan terutama kakinya di tepi kanan);
bank kabut tengah agak blobby dan menutupi sebagian kiri pos; tepi kanan
kertas masih cukup lurus di tengah; label kepala terpotong 1px di portrait
letterbox (bawaan v20); slider + CheckButton Options dan HUD dalam game
masih default. Sprite menu tetap kelas PLACEHOLDER.

## Menu utama v22: Opsi B diegetic, meja pos jaga (2026-11-18)

Kritik Arya 03:00 WIB (4 poin, semua dijawab): 1) tombol harus menonjol,
tekstur kusut di belakangnya terlalu ramai; 2) "Buku jaga, Pos 07" keluar
dari kertas dan tenggelam ke gelap, garis merah terlalu mepet; 3) jangan
campur CCTV (REC CAM 07 + grain) dengan kertas fisik, pilih SATU arah,
Arya pilih Opsi B: kamera menyorot meja kayu di depan jendela, buku jaga
tergeletak + lentera fisik di sampingnya, klik tulisan di kertas untuk
mulai; 4) cahaya datar, kabut merata, Giant kurang mengancam.
- Kamera di DALAM pos, utara meja, menghadap selatan (yaw 180, pitch -24,
  FOV 62, pos (-1.30, 2.10, 0.15), `Balance.MENU_DESK_CAM_*`). Buku jaga
  TERBUKA di atas meja adalah menu-nya: halaman kiri judul + logo, halaman
  kanan 4 baris (Start / Continue / Options / Exit) sebagai tinta gelap
  Label3D di atas kertas, klik baris (raycast ke bidang meja) atau keyboard
  (atas/bawah + Enter). Hover: highlight hangat redup di baris.
- Halaman buku v22 (`tools/make_menu_book_v22.py`, seed 22, dari foto
  perkamen asli yang sama dengan v20, `tools/ref/REFERENCES.md`): jauh
  lebih terang dari v20/v21 supaya tinta gelap terbaca (mean lum 146/147,
  form 166), tepi sobek alpha. Logo v20 dipakai ulang tapi ditintai tinta
  gelap (aslinya teks terang untuk latar gelap, tidak kelihatan di kertas
  terang). Halaman + logo pakai `ALPHA_CUT_DISCARD` (halaman transparan
  yang di-sort berdasarkan jarak sempat menutupi teks yang lebih jauh).
- Yang DIHAPUS dari menu: label REC CAM 07 + dot, overlay CCTV/scanline/
  tear, ikon lentera di Continue, coretan merah di bawah Exit, jejak kaki
  di bawah tombol, panel kertas tempel + tombol strip kertas. HUD dalam
  game BOLEH tetap VHS; yang dihapus hanya menu. Grain tinggal 0.05
  sebagai grade halus, bukan bingkai CCTV.
- Pencahayaan: ambient 0.30 (lebih gelap), bulan 0.80 dari barat daya
  jadi rim/back light, lentera diredupkan (dim_factor 0.6) tapi tetap
  titik fokus hangat di halaman. Kabut menu lebih tipis dari malam game
  (0.05/0.025) supaya Giant terbaca lewat jendela.
- Giant di jendela: BUKAN siluet utuh 13 m (tiga kali gagal: kaki
  selebar beberapa piksel dibaca batang pohon lewat kabut). Sekarang
  `giant_foot` close-up (sprite yang sama dengan event kaki 03:30),
  4 m di 6 m dari jendela, tint terang (2.0, 2.1, 2.0) supaya terpisah
  dari hutan gelap, di tengah jendela. Yang terbaca: kaki raksasa
  berkerut di kabut, bukan bukit. Puff kabut di kusen dihapus (menutupi
  kaki); radio disembunyikan di menu saja (badannya menutupi baris
  Start/Continue dari sudut kamera meja).
- Bug yang ditemukan lewat screenshot (bukan lewat log): halaman
  tertukar kiri-kanan (kamera menghadap selatan, +x adalah kiri pembaca);
  tinta shaded terbakar putih di bawah lentera (teks + logo jadi
  unshaded); CA 0.008 membuat teks berpinggiran merah/hijau (turun ke
  0.003); tepi dekat buku terpotong (kamera mundur/naik, FOV 62).
- Rig menu v25 (`scripts/menu_shot.gd`, PREFIX v25, portrait v25p):
  desktop 1280x720 PASS 27/0, portrait 720x1280 PASS 27/0 (klik
  sungguhan Options + Kembali, save dummy -> Continue hidup, tanpa
  save -> Continue mati "no record on file", tanpa CCTV, grain 0.05).
  Pelajaran rig: headless TIDAK menghasilkan screenshot (renderer
  dummy) — semua run pakai Xvfb; klik yang di-inject lewat
  `parse_input_event` masuk sebagai koordinat jendela lalu
  ditransformasi stretch ke kanvas, jadi di portrait posisi klik
  harus dikonversi kanvas -> jendela manual (skala + offset letterbox);
  `get_canvas_transform()` identitas di portrait, tidak bisa dipakai.
  Mode verify PASS (0 FAIL); mode playtest PASS fails=0 (5 tugas,
  Sanity 100); menu_autostart=1 masuk scene main (fog game 0.04/0.03
  setelah transisi, bukan fog menu).
- Batas jujur: di portrait 720x405 dasar lentera sedikit menyentuh
  huruf "T" logo (masih terbaca); kaki Giant terbaca sebagai kaki
  berkerut, bukan kaki gajah utuh dengan jari (telapaknya terpotong
  tepi bawah jendela); slider + CheckButton Options sudah di-skin
  (track gelap, grabber hangat), HUD dalam game masih font default.
  Sprite menu tetap kelas PLACEHOLDER.

## Menu utama v23: perbaikan 4 kritik v22 dengan skill list Luci (2026-11-18)

Perintah Arya 04:33 WIB: "iya pake list luci buat garap the giant".
Skill yang dibaca dari `~/workspace/makefun/skills/` (list Luci langsung,
BUKAN adaptasi custom-skills): router awesome-gamedev-agent-skills
(klasifikasi: disiplin game-ui-ux, game-feel, camera-systems,
create-game-assets + engine godot-ui-control); game-ui-ux (hierarki,
kontras teks >= 4,5:1, sinyal bukan cuma warna, focus saat buka, sweep
ukuran); game-feel (juice di event hook, kembali persis ke rest, jangan
over-juice aksi rutin); camera-systems (kamera melayani framing, pisah
look dari collision); create-game-assets (inspect dulu, target visual
yang disetujui dipertahankan, produksi sebagai family, validasi di
konteks ukuran native, provenance, nol aset AI); unslop (chrome diam,
satu elemen terang, teks di ruang tenang, urutan perbaikan spacing dulu);
anthropics frontend-design (tipografi bawa karakter, boldness di satu
tempat, kritik dari screenshot). Dua skill dibaca tapi JUJUR tidak
dipakai: canvas-design (untuk poster/statis, bukan menu Godot) dan
webapp-testing (Playwright untuk web app; verifikasi Godot pakai rig +
Xvfb sendiri).
- 1) Kaki Giant kebaca batang pohon -> aset dipotong ulang dari sumber.
  `giant_foot.png` (120x218) diperiksa 3x: kolom belang seragam tanpa
  telapak/kuku, memang batang pohon secara visual. Sumber
  `elephant_front.png` juga terpotong di tepi bawah, tidak ada kuku.
  Aset baru `giant_foot_photo_v23.png` (470x640) dipotong dari FOTO ASLI
  kaki gajah low-angle di lumpur (Wetu, tile K moodboard v2,
  `tools/make_menu_foot_v23.py`, deterministik, tanpa random; alpha dari
  luminance, grade malam; provenance di `tools/ref/REFERENCES.md`):
  telapak melebar + dua kuku bulat + lumpur di dasar. Penempatan sama
  (2.0, 0, 6.0), 4 m. Event kaki 03:30 dalam game dulu masih pakai
  `giant_foot.png` lama — diganti di v24 (di bawah).
- 2) CA bikin semua teks berpinggiran merah/biru -> `MENU_GRADE_CA`
  0.003 -> **0.0** (`scripts/balance.gd`); grain 0.05 + desat 0.15 +
  vignette 0.32 tetap sebagai grade foto. HUD dalam game TIDAK berubah
  (VHS_CA sendiri). Diukur: CA 0.003 = ~2 px di tengah, ~7 px di sudut
  pada 1280 lebar.
- 3) Dasar lentera menutupi T di THE GIANT -> lentera menu SAJA geser
  z 1.64 -> **1.72** (`main.gd _setup_menu_backdrop`); alas sprite kini
  z 1.54, di belakang tepi jauh logo (z 1.48). Geser x ditolak (kanan
  keluar meja, kiri tabrak meter). Game tidak berubah. Cek rig:
  alas lentera 6 px di atas judul (proyeksi layar, bukan kira-kira).
- 4) Continue mati hampir hilang -> tinta mati `INK_DIM` (0.38, ~2:1)
  diganti `INK_DISABLED` (0.22, ~3,3:1), jelas lebih redup dari tinta
  aktif INK (0.13, ~4,7:1) tapi terbaca; PLUS sinyal bukan-warna
  (game-ui-ux): garis coret 0,80 x 0,012 m di atas teks, hanya saat
  mati, seperti entri dibatalkan di buku jaga. Sub "no record on file"
  pakai INK_BODY (0.22) supaya alasan terbaca.
- game-feel: hover tetap highlight hangat saja (aksi rutin, over-juice
  = mual). Tambah pop seleksi kecil di `main_menu.gd` (`_pop_selection`):
  baris terpilih skala 1.0 -> 1.05 (TRANS_BACK, 0,09 dtk) -> 1.0
  (TRANS_QUAD, 0,12 dtk), tween lama dimatikan saat retrigger, selalu
  kembali persis 1.0. Tanpa SFX baru (proyek tidak punya tick UI).
- Temuan ke-5 saat verifikasi (bukan dari 4 tugas, sudah ada di v22):
  "Start" pucat di portrait — bar sorot kuning (transparan, alpha 0,45)
  sempat ter-sort DI DEPAN teks di sudut kamera tertentu, jadi teks
  tercuci kuning. Perbaiki deterministik: `render_priority = -1` pada
  material bar sorot (selalu di belakang teks), `+1` pada coret (selalu
  di atas teks). Cek piksel rig: luminansi tergelap teks Start 0,11 di
  portrait (sebelumnya pucat), 0,21 di desktop.
- Verifikasi (Xvfb + Vulkan Forward+, screenshot dibaca sendiri):
  rig cepat v23 (`scripts/menu_check_v23.gd`, `scenes/menu_quick.tscn`,
  10 cek: 4 perbaikan + baris + tanpa CCTV + CA + logo utuh + piksel
  Start): desktop 1280x720 **10/10**, portrait 720x1280 **10/10**,
  dengan save **9/9** (Continue hidup, sub "00:03, Sanity 80", tanpa
  coret). Rig menu penuh v26 (`scripts/menu_shot.gd`): desktop **27/0
  PASS**, portrait **27/0 PASS**. Mode verify DONE (registry 67 nama
  missing=0, hitbox meja tumpang=0); mode playtest **PASS fails=0**
  (5 tugas, Sanity 100); menu_autostart=1 masuk scene main (fog game
  0.04/0.03). Catatan rig: `v26_menu_with_save.png` versi rig penuh
  adalah frame DALAM GAME sesudah Continue ditekan (HUD + VHS game,
  sesuai desain); menu dengan-save-nya dibuktikan screenshot quick
  run yang sama.
- Pelajaran sandbox: sesudah restart, Xvfb yang BARU distart kadang
  membuat Godot nyangkut di init (scene tidak pernah load, CPU ~0);
  Xvfb yang sudah hangat + satu run pemanasan (scene kosong) jalan
  ~10 dtk. Jangan `pkill -f` dengan pola yang ada di command sendiri;
  matikan Xvfb/Godot pakai PID persis. `muse.edit` bisa menulis escape
  `\"` literal ke GDScript — selalu grep `\"` sesudah edit string.
- Batas jujur: kuku kaki setengah terpotong kusen jendela (aturan
  "tidak pernah utuh", sengaja); alas lentera cuma 6 px di atas judul
  (tipis tapi terukur dan terbukti di screenshot); portrait tetap
  letterbox 720x405 di layar 720x1280 (stretch aspect=keep, sudah
  sejak v20); event kaki 03:30 dalam game sudah diganti ke aset foto
  di v24 (di bawah). Sprite menu tetap kelas PLACEHOLDER.

## Event kaki Giant 03:30 dalam game: ganti ke aset foto v23 (2026-11-18, v24)

Follow-up v23, atas perintah Arya 12:51 WIB. Skill dari list Luci
(`~/workspace/makefun/skills/`, BUKAN adaptasi): router
awesome-gamedev-agent-skills (Godot 4.3 pinned, disiplin
create-game-assets + game-feel + camera-systems); create-game-assets
(inspect dulu, target visual yang disetujui dipertahankan, produksi
sebagai family, validasi di konteks ukuran native, provenance, nol
aset AI); game-feel (event hook kaki: thud + getar + debu, juice
kembali ke rest — perilaku event TIDAK diubah); camera-systems
(framing kaki lewat jendela, pisah look dari collision);
unslop (chrome diam, satu elemen terang, teks di ruang tenang —
dipakai sebagai ceklis: tidak ada elemen baru yang ditambahkan, hanya
memperbaiki yang ada).
- Aset: `giant_event.gd _start_foot` kini spawn
  `giant_foot_photo_v23` (foto asli yang sama dengan kaki menu v23,
  family yang sama, tanpa crop baru) menggantikan `giant_foot.png`
  (120x218, kolom berkerut seragam tanpa telapak/kuku — di jendela
  memang batang pohon). `giant_foot.png` masih ada di disk + registry
  (cek file test_rig masih lolos) tapi tidak dipakai lagi.
- Pemetaan vertikal (camera-systems, dihitung bukan kira-kira):
  sprite berpusat di y 2,8, tinggi 3,4 m (bentang 1,1-4,5); telapak =
  seperempat bawah tekstur, jatuh di y 1,1-1,95, tepat di band jendela.
  Lebar kaki 2,5 m (470x640) vs 1,87 m sebelumnya.
- Pencahayaan: unshaded + tint (1.5, 1.55, 1.5, 0.95), SAMA seperti
  kaki menu v23 — foto sudah di-grade malam 0,62, shaded membuatnya
  pilar hitam (aturan v14, pola yang sama dengan mata 04:45).
- Perilaku TIDAK berubah: trigger 03:30, durasi stride 9 dtk, thud,
  getar kamera, dust puff, drain Sanity semua sama. Menu v23 tidak
  disentuh. Event lain (mata 04:45, hunter 01:30) tidak disentuh.
- Verifikasi (Xvfb, `--rendering-driver opengl3` karena Vulkan hilang
  sesudah sandbox reset; `project.godot` di-backup dan dicek tidak
  berubah): rig `mode=shots` prefix v27 — event kaki ke-trigger,
  screenshot `v27_foot.png` dibaca sendiri + zoom crop jendela.
  Sebelum (v14): kolom lurus bergaris seragam = batang pohon.
  Sesudah (v27): massa berkerut lebar, lebar tidak seragam, tepi bawah
  berlumpur, tonjolan membulat — terbaca kaki gajah, bukan batang
  pohon. Screenshot playtest `v27_playtest_foot.png` konsisten (kaki
  sedikit lebih maju dalam stride). Mode verify DONE (registry 67 nama
  missing=0, hitbox meja tumpang=0); mode playtest **PASS fails=0**
  (5 tugas, Sanity 100, Stability 100).
- Batas jujur: di dalam game, malam + kabut + grade VHS, kuku tidak
  se-crisp di menu — yang terbaca "massa kaki berkerut raksasa",
  bukan "kaki dengan dua kuku". Itu sudah cukup untuk tujuan
  (kaki gajah, bukan batang pohon); kuku crisp butuh pencahayaan yang
  akan merusak grade malam. Sprite tetap kelas PLACEHOLDER.

## Menu utama v24: kritik desain kedua, teks di-bake ke kertas (2026-11-18)

Kritik kedua Arya (ditempel 13:50 WIB) atas menu v23. Langkah pertama
bukan membangun, tapi VERIFIKASI dari screenshot v26 mana yang masih
rusak — hasilnya: 1 dari 4 poin ternyata SUDAH beres di v23.
Skill dari list Luci (`~/workspace/makefun/skills/`, BUKAN adaptasi):
router awesome-gamedev-agent-skills (Godot 4.3 pinned, disiplin
game-ui-ux + camera-systems + create-game-assets + game-feel);
game-ui-ux (kontras teks >= 4,5:1, warna bukan satu-satunya sinyal,
fokus saat layar dibuka, sweep ukuran desktop + portrait);
camera-systems (kamera melayani framing, pisah look dari collision);
create-game-assets (inspect dulu, produksi sebagai family, normalisasi
deterministik, validasi di konteks ukuran native, provenance, nol aset
AI); game-feel (pop hanya saat pilihan berpindah, juice kembali tepat
ke rest); unslop (chrome diam, satu elemen terang, teks di ruang
tenang, spacing dulu); frontend-design anthropics (tipe membawa
kepribadian, kritik dari screenshot). canvas-design + webapp-testing
dibaca dan DILAPORKAN tidak dipakai (canvas-design untuk poster/statis,
bukan menu Godot; webapp-testing Playwright untuk web, verifikasi Godot
pakai rig sendiri + Xvfb).

- Poin 1, lentera menutupi judul: SEBAGIAN beres di v23 (judul utuh,
  alas 6 px di atas judul), TAPI masih rusak — dari kamera menu,
  sprite lentera jatuh tepat di atas ruang udara judul dan glow-nya
  menabrak huruf. v24: lentera PINDAH ke sudut kiri meja (-2,32,
  1,55), 5 cm di kiri kertas (kertas berakhir x -2,27), cahayanya
  menyinari buku dari samping. Bukan tambah 2-3 px.
- Poin 2, chromatic aberration: SUDAH BERES di v23, TIDAK DIUTAK-ATIK.
  `MENU_GRADE_CA = 0,0` di `balance.gd`, shader `off = 0`, HUD (yang
  membawa `VHS_CA = 0,0016`) tersembunyi di mode menu. Diukur dari
  screenshot v26: scanline lewat "Buku jaga, Pos 07" R-B seragam
  +21..+29 (nada hangat kertas), tanpa sign flip dan tanpa spike di
  tepi — tidak ada chromatic shift yang terukur. Satu-satunya ghost
  merah yang tersisa adalah bawaan sprite `menu_logo_v20` (treatment
  VHS v20-nya); ia hilang sebagai efek samping karena logonya
  sekarang di-bake sebagai mask alpha saja (warnanya tidak dipakai).
- Poin 3, keterbacaan tombol + teks: MASIH RUSAK, diperbaiki penuh.
  (a) Lipatan gelap diagonal di halaman kanan TERBUKTI menabrak
  Continue/Options di zoom v26. (b) Teks Label3D memang terasa
  seperti UI digital yang ditempel rata. Perbaikan: SEMUA teks statis
  DI-BAKE ke tekstur halaman (`tools/make_menu_book_v24.py`, seed 24,
  deterministik) dengan multiply tinta gelap di atas foto perkamen
  asli yang sama dengan v20/v22; zona teks diratakan dulu (blur 18 +
  angkat 0,15 ke median lokal, feather 40, zona mengikuti lebar teks
  — bukan selebar halaman) supaya lipatan tidak menabrak satu pun
  baris; sorot kuning solid DIGANTI outline tinta merah (4 quad
  tipis, alpha 0,35 hover / 0,70 pilihan, `render_priority -1` supaya
  tidak pernah menutupi tulisan). Halaman kanan punya DUA varian:
  aktif (`menu_book_page_r_v24`) dan mati (`..._r_disabled_v24`,
  Continue tinta redup 0,22 + coret + "no record on file" di-bake);
  `_refresh_continue` menukar teksturnya + mengisi sub Label3D
  dinamis (ringkasan save) hanya kalau ada save. Bug ketemu dari
  screenshot tekstur: font digambar 1,4545x lebih besar ikut
  melebarkan teks (header terpotong tepi) — diperbaiki dengan
  stretch HANYA vertikal per baris; zona rata selebar halaman
  kelihatan seperti strip tempelan terang — diperbaiki jadi zona
  mengikuti lebar teks + angkat ringan.
- Poin 4, jendela + latar: MASIH RUSAK, diperbaiki. Kamera menu
  digeser ke kanan (+0,50 x) + sedikit mundur/naik, FOV 62 -> 66,
  pitch -24 -> -25 (`balance.gd`): buku bergeser ke kiri bingkai,
  jendela selatan TERBUKA LEBAR di tengah-atas, dinding kayu kosong
  di kanan tidak lagi mendominasi. Siluet Giant jauh DICOBA dua ronde
  lalu DIHAPUS dengan sengaja: ronde 1 (x 3,5, z 11, tint pucat)
  melebur dengan kabut; ronde 2 (x 5,0, z 9, 12 m, tint gelap 0,45)
  tetap tidak terbaca sebagai gajah — lewat jendela rendah hanya
  kelihatan irisan bawah 2,4 m (kaki tipis di kabut = batang pohon,
  mode gagal yang sama dengan v21). Kritik membolehkan salah satu
  ("siluet hutan berkabut ATAU bayangan Giant"): yang membawa poin #4
  adalah hutan berkabut yang terbuka lebar + kaki close-up foto di
  6 m. Event kaki 03:30 dalam game TIDAK disentuh (sudah bagus di
  v24); event lain juga tidak.
- File yang dihapus: `menu_book_page_l.png`, `menu_book_page_r.png`,
  `menu_logo_v20.png` (teksnya kini di-bake). Registry 67 nama,
  missing=0. `menu_btn_v20*` tetap (tombol Kembali di Options),
  `menu_form_page` tetap.
- Verifikasi (Xvfb, `--rendering-driver opengl3`; `project.godot`
  di-backup dan dicek NO-DIFF): rig cepat v24
  (`scripts/menu_check_v24.gd`, prefix v27) desktop **10/10**,
  portrait **10/10**, dengan save **10/10**; rig menu penuh
  (`scripts/menu_shot.gd`, prefix v27) desktop **28 pass, 0 fail,
  RESULT MENU PASS**, portrait **28 pass, 0 fail**; mode verify DONE
  (registry 67, missing=0, hitbox meja tumpang=0); mode playtest
  **PASS fails=0** (5 tugas, Sanity 100, Stability 100);
  `menu_autostart=1` masuk main (jam 22:00, fog game). Screenshot
  dibaca sendiri: `v27_menu_no_save.png` (desktop), `v27p_...`
  (portrait), `v27_menu_with_save.png` (Continue hidup + sub
  "00:03, Sanity 80"), `v27_menu_options.png`.
- Batas jujur: menu di portrait masih letterbox 720x405 (sejak v20)
  jadi kolom buku kecil di layar HP tinggi; sudut kiri-bawah frame
  agak kosong (permukaan meja); meter getar masih mengintip di tepi
  atas buku; slider volume + CheckButton di Options dan HUD dalam
  game masih kontrol/font default Godot. Aset menu tetap kelas
  PLACEHOLDER.

## Menu utama v25: mockup Arya + kepala Zunisha + bar merah (2026-11-18)

Arya kirim dua gambar referensi (14:34 WIB): (1) mockup target main
UI — meja kayu, buku jaga terbuka, lentera kanan, alat ukur tengah,
cahaya hangat miring dari jendela, jendela lebar menampilkan siluet
raksasa di kabut; (2) sheet elemen tempat — pos panggung + menara,
jalan hutan berkabut, kuburan gajah (kerangka + siluet gajah),
checkpoint logging, papan "KAWASAN KUBURAN GAJAH", pagar, lampu.
**CATATAN JUJUR: kedua gambar kelihatan seperti concept art
AI-generated, jadi semua aset yang dipotong dari sana kelas
PLACEHOLDER, bukan art final.** Dipakai sebagai target/referensi,
seperti sheet Arya sebelumnya.
Skill dari list Luci (`~/workspace/makefun/skills/`, BUKAN adaptasi):
router awesome-gamedev-agent-skills (Godot 4.3 pinned, disiplin
game-ui-ux + game-feel + camera-systems + create-game-assets);
game-ui-ux (kontras >= 4,5:1, warna bukan satu-satunya sinyal —
Continue mati juga dicoret, bukan cuma diredupkan; fokus saat layar
dibuka, sweep ukuran desktop + portrait); game-feel (pop hanya saat
pilihan BERPINDAH, 1,0 -> 1,05 -> 1,0, tween lama di-kill, selalu
kembali tepat ke rest; hover = bar 0,70, bukan juice); camera-systems
(kamera melayani framing, verifikasi framing lewat proyeksi layar,
bukan tebak-tebakan — begitu ketahuan proyeksi rig meleset ~60 px
karena billboard miring); create-game-assets (inspect dulu, kunci
satu target visual, produksi sebagai family, normalisasi
deterministik, validasi di konteks ukuran native, provenance,
gotcha fake-transparency + teks generate); unslop (satu elemen
terang — belalai; chrome diam; teks di ruang tenang; spacing dulu;
satu aksen merah); frontend-design anthropics (grounding di materi
subjek, tipografi membawa kepribadian, kritik dari screenshot).
canvas-design + webapp-testing dibaca dan DILAPORKAN tidak dipakai
(canvas-design untuk poster/statis, bukan menu Godot; webapp-testing
Playwright untuk web, verifikasi Godot pakai rig sendiri + Xvfb).

- Komposisi = mockup: jendela lebar tengah-atas, meja kayu, buku
  terbuka, lentera kanan, alat ukur tengah, cahaya hangat miring ke
  dinding kanan. Buku tetap diegetic (teks di-bake seperti v24,
  tinta multiply, CA menu tetap 0,0, tanpa REC/scanline/CCTV).
  Start pakai BAR MERAH + segitiga play seperti mockup: 4 tekstur
  bar 900x150 (`menu_bar_<row>_v25.png`,
  `tools/make_menu_book_v25.py`) — bar tinta merah INK_RULE, teks
  terang (235,228,210) di posisi yang SAMA persis dengan teks bake
  gelap (mask yang sama), segitiga play hanya di Start; sprite bar
  ditampilkan di atas baris aktif/hover (`main_menu.gd`, alpha 1,0
  terpilih / 0,70 hover, unshaded, squash z 0,6875 yang sama),
  menggantikan outline tinta merah v24. Continue mati tetap terbaca
  + coret, sub kini "no record on this slot" (bahasa mockup, dulu
  "no record on file"). Logo kecil di atas judul: siluet KEPALA
  GAJAH (mask alpha kepala Zunisha, tinta gelap, 150 px) — bukan
  kera seperti di mockup.
- Siluet jendela DIGANTI: bukan siluet kera mockup, bukan kaki foto
  v23/v24, tapi KEPALA GAJAH GEDE kayak Zunisha — kepala dari
  `elephant_front.png` sheet Arya (crop kepala + telinga + belalai
  + gading, `tools/make_menu_head_v25.py`), lebar 20 m di z 12,
  grade kabut pucat + belalai diangkat x3,0 + gading x2,5 (satu
  elemen terang), tint (1,2, 1,25, 1,3), unshaded.
  **Geometri jujur: yang kelihatan lewat jendela HANYA pita bawah
  kepala — belalai + gading + rahang bawah.** Kubah + telinga TIDAK
  BISA masuk frame: kusen jendela (y 1,3..2,2 di dinding z ~2,5)
  membatasi garis pandang ke y 0..2,5 m di segala jarak. Itu
  konsisten dengan aturan Giant (tidak pernah utuh): yang terlihat
  adalah belalai 3 m + gading putih — skalanya yang bilang Zunisha.
  Yang terbaca di screenshot: gading putih besar menyapu diagonal
  + kolom belalai pucat di tengah jendela — langsung kebaca gajah
  raksasa, bukan pohon/bukit.
- Elemen tempat dari gambar 2: papan "KAWASAN KUBURAN GAJAH"
  (crop papan + kaki dari gambar tempat, alpha dari luminansi,
  `menu_sign_graveyard_v25.png`) di x 5,5, z 9 — tepi kiri jendela,
  setengah terpotong kusen, terbaca jelas. Panel kuburan gajah
  (kerangka + gading + siluet gajah jauh, `menu_skeleton_v25.png`,
  checkerboard langit diganti kabut halus) DICOBA lalu DIPOTONG
  dari menu dengan sengaja: di z 12 panel yang lebih dekat menutupi
  belalai, di z 18 panel tenggelam di belakang siluet kepala 20 m
  (kepala menutupi seluruh lebar jendela) — jendela hanya 7 m lebar
  di z 12, kepala dan panel tidak muat berdua. Panel tetap ada
  (aset + registry + generator) untuk penempatan DALAM permainan
  nanti (pemain berjalan ke kuburan). Menara pengawas + checkpoint
  TIDAK dipasang (ramai; menara sudah ada di level permainan).
- Enam ronde iterasi, semua diukur dari screenshot (bukan ditebak):
  ronde 1 — kepala pucat di z 28 hilang total (75% kabut + puff
  tetap (1,5, 12) tepat di depan belalai + kerangka di luar jendela
  (x -3,0)); ronde 2 — grade GELAP kontras NOL lawan kabut L~50
  (diukur: strip belalai = kabut, lum 50 = 50); ronde 3 — kepala
  didekatkan z 12 + koridor pandang dikosongkan dari puff, belalai
  muncul tapi melebur jadi blob (pipi sama terang); ronde 4 —
  pipi digelapkan, belalai jadi kolom, TAPI pohon dekat (seed tetap)
  berdiri tepat di depan belalai; ronde 5 — pohon di koridor
  dihapus, belalai tetap tidak kelihatan; ronde 6 — tes tekstur
  3-warna membuktikan kepala MERENDER (merah di layar x 220-460,
  hijau 440-600) dan belalai di foto sumbernya GELAP (L~34, lum
  49 setelah grade = kabut, preview latar hitam menipu) —
  belalai diangkat x3,0 (lum 158), gading x2,5, preview diganti
  latar kabut; ronde 7 — tes panel dimatikan membuktikan panel
  yang menutupi belalai (render setelah kepala); ronde 8 — panel
  dipindah z 18 (tetap tenggelam di belakang kepala) lalu DIPOTONG.
  Perbaikan sistemik: koridor pandang jendela selatan (x -1..8,
  z 2..20) dikosongkan dari puff acak + ground fog + pohon dekat
  (`main.gd`, seperti koridor gerbang utara sejak lama); puff tetap
  (1,5, 12) dihapus.
- Verifikasi (Xvfb, `--rendering-driver opengl3`; `project.godot`
  NO-DIFF): rig cepat v25 (`scripts/menu_check_v25.gd`, prefix
  v28) desktop **11/11**, portrait **11/11**, dengan save **11/11**;
  rig menu penuh (`scripts/menu_shot.gd`, prefix v28) desktop
  **31 pass, 0 fail, RESULT MENU PASS**, portrait **31 pass, 0 fail, RESULT MENU PASS**;
  mode verify DONE (registry 77, missing=0); mode playtest
  **PASS fails=0**; `menu_autostart=1` masuk main (jam 22:00,
  "[Main] scene main siap").
  Screenshot dibaca sendiri: `v28_menu_no_save.png` (desktop),
  `v28p_menu_no_save.png` (portrait), `v28_menu_with_save.png`
  (Continue hidup + sub "00:03, Sanity 80").
- Batas jujur: belalai agak lunak (sumber 330 px di 20 m + kabut)
  — terbaca sebagai kolom pucat, bukan belalai tajam; kubah +
  telinga di atas frame (sengaja + geometri, lihat di atas); menu
  di portrait masih letterbox 720x405 (sejak v20); slider volume +
  CheckButton di Options dan HUD dalam game masih kontrol/font
  default Godot. Aset menu tetap kelas PLACEHOLDER. Event dalam
  game (kaki 03:30, mata 04:45, hunter 01:30) TIDAK disentuh.

## Menu utama v26: aturan tidak-pernah-utuh DIHAPUS, kepala gajah UTUH (2026-11-18)

Arya 15:50 WIB: "hilangin aturan giant ga utuh, kan bisa siluet kepala
gajah raksasa". Aturan lama (Giant tidak pernah utuh, kaki + mata saja)
DICABUT — berlaku untuk menu dulu; event dalam game (kaki 03:30, mata
04:45, hunter 01:30) TIDAK disentuh. Yang dulu membatasi kepala di
menu bukan aturan semata tapi GEOMETRI: jendela lama (lebar 1,4 m,
top y 2,20) membatasi garis pandang ke y 0..2,4 m di segala jarak,
jadi kepala utuh tidak bisa masuk frame — v25 hanya bisa belalai +
gading + rahang. v26 mengubah framing-nya sampai kepala utuh masuk.
Skill dari list Luci (`~/workspace/makefun/skills/`, BUKAN adaptasi):
router awesome-gamedev-agent-skills (Godot 4.3 pinned, disiplin
game-ui-ux + game-feel + camera-systems + create-game-assets);
camera-systems (diukur dulu dengan probe sebelum mengubah apa pun:
kusen membatasi y 0..2,4 m; pitch -20 kepala 5,2 m di z 12,5 kubah
di y -12, pitch -18 kubah di y +16 dengan tepi dekat buku di y ~715;
pitch -16 buku jatuh dari bawah frame — jadi pitch -18 dipilih
dari DATA, bukan ditebak); create-game-assets (inspect dulu, kunci
satu target visual, produksi sebagai family, normalisasi
deterministik, validasi di konteks ukuran native, provenance,
grade diukur per zona luminansi); game-ui-ux (cek 6 titik kepala +
4 sudut papan di dalam viewport, sweep ukuran desktop + portrait);
game-feel (tidak ada juice baru, menu tetap diam, fokus tidak
berpindah); unslop (tidak ada elemen baru selain kepala; chrome
diam); frontend-design anthropics (tipografi + kepribadian tetap
dari v24/v25, kritik dari screenshot). canvas-design +
webapp-testing dibaca dan DILAPORKAN tidak dipakai (poster/statis
dan Playwright web, bukan menu Godot).

- Probe dulu, bangun belakangan: `scripts/menu_window_probe.gd` +
  `scenes/menu_probe.tscn` (SEMENTARA, dihapus sebelum commit) —
  kepala dummy 4,5 m dipasang di z 12,5, layar diukur lewat proyeksi
  tiap sudut; hasil: jendela lama tidak bisa menampung kepala utuh
  di pitch berapa pun, jadi geometri HARUS berubah.
- Kepala UTUH: `giant_head_zunisha_v26.png` (350x270, crop lebih
  lebar dari v25 (0,0,350,270) supaya ujung gading kiri tidak
  terpotong) dari `elephant_front.png` sheet Arya
  (`tools/make_menu_head_v26.py`, deterministik). Grade DIBALIK
  dari v25: v25 menghancurkan pipi ke 0,5 sehingga hanya kolom
  belalai terang + satu gading yang terbaca; v26 menjaga SELURUH
  kepala terbaca dengan struktur nilai internal yang DIUKUR per zona
  (dome/tengkorak L 54 x2,2, telinga 47/42 x2,2, belalai 51 x2,7,
  gading kiri 75 x2,5, gading kanan 67 x2,6; desat 0,45 + tint dingin,
  tanpa brighten global) — luminansi akhir aset: kubah 105, muka
  121, telinga 89/81, belalai 117, gading 150/141. Sampel pertama
  terkontaminasi piksel transparan RGB-0 dan gading kanan salah
  lokasi 25 px (di x 175-200, bukan 195-235) — diperbaiki, diukur
  ulang. Garis gelap di tepi kiri belalai DICOBA lalu DIHAPUS
  (terbaca retak hitam di tengah muka). Kepala 5,2 m (lebar 6,74 m)
  di (x 2,0, z 12,5), tint (1,2, 1,25, 1,3, 0,98), unshaded.
  Gading melengkung meruncing dari kepala, belalai punya kontur +
  bayangan — bukan kolom kabut lunak.
- Jendela DILEBARKAN (menu saja): `guard_post.gd`
  `rebuild_back_wall_for_menu()` — 4 kotak dinding belakang z ~2,0
  disembunyikan (mesh + collider) lalu dinding dibangun ulang dengan
  bukaan x -1,7..1,7 (3,4 m, dulu 1,4 m), sill y 1,30 tetap, top y
  2,75 (lintel 0,2 m ke puncak dinding 2,95), tanpa collider.
  Dipanggil dari `main.gd _setup_menu_backdrop()` (instans backdrop
  menu saja; permainan pakai dinding asli).
- Kamera: `Balance.MENU_DESK_CAM_PITCH_DEG` -25 -> **-18** (posisi
  + FOV tetap). Koridor pandang jendela selatan dilebarkan
  x -1..8 -> **x -7..15**, z 2..20, di ketiga penjaga (pohon dekat,
  puff acak, ground fog) — berbagi seperti koridor v25.
- Papan "KAWASAN KUBURAN GAJAH" digeser (5,5, 0, 9,0) -> **(-3,5, 0,
  9,0)** — 4 sudutnya kini di dalam viewport, ~20-30 px lepas dari
  tepi kusen (dulu terpotong kusen kiri).
- Registry 77 -> **78** nama (`giant_head_zunisha_v25` tetap di disk
  + registry, tidak dipakai — preseden sama seperti `giant_foot.png`
  yang tidak dipakai sejak v24).
- Verifikasi (Xvfb, `--rendering-driver opengl3`; `project.godot`
  NO-DIFF): rig cepat v26 (`scripts/menu_check_v26.gd`, prefix
  v29) desktop **11/11**, portrait **11/11**, dengan save **11/11**
  (cek #5 kini 6 titik kepala — kubah, belalai, dua gading, dua
  telinga — di dalam viewport; cek #5b 4 sudut papan di dalam
  viewport); rig menu penuh (`scripts/menu_shot.gd`, prefix v29)
  desktop **31 pass, 0 fail**, portrait **31 pass, 0 fail** (satu
  fail pertama di rig penuh adalah nama aset v25 yang ketinggalan
  di rig itu sendiri, diperbaiki, run ulang 31/0); mode verify DONE
  (registry 78, missing=0, hitbox meja tumpang=0); mode playtest
  **PASS fails=0**; `menu_autostart=1` masuk main (jam 22:00).
  Probe pasca-perubahan (pitch -18 live): kubah (508, 17), belalai
  (520, 211), gading kiri (640, 235), gading kanan (421, 225),
  telinga kiri (655, 95), telinga kanan (372, 95) — semua di dalam
  viewport 1280x720; papan 4 sudut (889/759, 211) (875/752, 318)
  di dalam viewport. Screenshot dibaca sendiri:
  `v29_menu_no_save.png` (desktop), `v29p_menu_no_save.png`
  (portrait), `v29_menu_with_save.png` (Continue hidup + sub
  "00:03, Sanity 80"), `v29_menu_options.png`.
- Batas jujur: kepala utuh langsung terbaca sebagai kepala gajah
  (kubah, dua telinga, belalai, dua gading, satu mata kelihatan),
  tapi skala "raksasa" belum sepenuhnya mendarat: kepala 5,2 m
  tingginya kira-kira sama dengan pohon palem di sekitarnya dan
  ujung belalainya menyentuh garis tanah, jadi sekilas bisa terbaca
  gajah biasa di rumpun hutan, bukan Zunisha kolosal. Mockup Arya
  raksasanya ~2-3x tinggi pohon; kepala sebesar itu tidak bisa
  masuk utuh di jendela ini (kubah akan lewat atas frame) — kepala
  yang mengisi jendela adalah pernyataan skalanya untuk sekarang.
  Kandidat ronde berikut kalau Arya mau: perkecil pohon yang
  kelihatan lewat jendela, atau terima kubah sedikit terpotong demi
  kepala lebih besar. Jendela kini meluber keluar atas/kiri frame
  (sengaja, terbaca bukaan besar); pita ground fog di bawah kepala
  agak datar/kosong; sudut kiri-bawah meja masih kosong/gelap (sejak
  v24); portrait masih letterbox 720x405. Aset menu tetap kelas
  PLACEHOLDER. Event dalam game TIDAK disentuh.

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
- Export Android: **sudah dibangun (v18, 2026-11-17)** — APK debug +
  release terverifikasi (`aapt2 dump badging`, `apksigner verify`,
  `unzip -t`); lihat "Android (APK, v18)" di atas. Belum pernah
  di-install di HP asli.
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
../builds/windows/THE-GIANT.exe` (dan `"Web"`). Android: lihat
"Android (APK, v18)" — APK debug + release sudah dibangun 2026-11-17
dari preset yang sama.

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
