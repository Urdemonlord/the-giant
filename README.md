# THE GIANT - Proyek Godot

Prototipe first-person psychological horror dalam **Godot 4.3+** (GDScript, renderer GL Compatibility).
Ini versi native dari prototipe browser sebelumnya: bukan halaman web, jadi tidak kena pull-to-refresh, kunci orientasi webview, atau AudioContext yang tertidur.

Setting: **pos jaga** (bukan rumah) di Taman Nasional **Malayunesia**. Kamu penjaga shift malam, 22:00 sampai 06:00. Jaga pos ini. Jangan biarkan mereka kembali.

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
  - `lantern.gd` - lentera di dalam pos, nyala/matikan cahayanya.
  - `door.gd` - buka/tutup pintu pos.
- **Sistem shift** (`scripts/game_state.gd`, autoload `GameState`): Sanity, Stability, bahan bakar, jam shift 22:00 ke 06:00 (1 detik nyata = 1 menit shift, shift penuh sekitar 8 menit), daftar tugas, sinyal untuk HUD. Generator mati = Stability terkuras; menyala = pulih perlahan.
- **Event pemburu** (`scripts/hunter_event.gd`): pukul 01:30 dua sosok diam muncul di depan pos dan menatap, persis momen *No I'm Not a Human*. Menatap mereka menguras Sanity. Tutup pintu dan tunggu di dalam 12 detik untuk melewatinya dengan aman; event juga berakhir sendiri setelah 50 detik dengan harga Sanity.
- **HUD** (`scripts/hud.gd`): titik crosshair di tengah, prompt interaksi, bar SANITY dan STABILITY di kiri bawah, jam + daftar tugas di kanan atas, pesan naratif yang memudar. Tidak ada panel yang menutupi tengah layar.
- **Audio prosedural** (`scripts/audio.gd` + `assets/audio/*.wav`): angin (loop), dengung generator (loop), statis radio, derit pintu, langkah kaki, dan detak jantung saat Sanity di bawah 35. Semua WAV **disintesis dari kode** (noise/sine), tidak ada file audio berlisensi pihak ketiga.
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

## Yang masih placeholder / belum ada

- Model masih berupa kotak + sprite billboard; ini prototipe gameplay, bukan build visual final.
- Audio tetap sintesis prosedural dan **belum pernah didengar telinga
  manusia** (sandbox tanpa sound card); yang diverifikasi adalah bentuk
  gelombang + jalur play (lihat "v5" di bawah).
- Export Android belum pernah dicoba: tidak ada Java/Android SDK di
  sandbox, jadi APK tidak bisa dibangun di sini. Preset-nya ada, tapi
  belum terbukti.
- Export Windows belum pernah dijalankan di Windows (tidak ada Wine di
  sandbox): file .exe terbukti ada dan berformat PE, tapi belum
  dijalankan di mesin Windows sungguhan.
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
                         touch/pause/save/playtest (v5)
    menu_shot.gd         uji menu headless (v5)
    interactables/       generator, radio, logbook, lantern, door
  tools/
    synth_audio.py       sintesis WAV prosedural (v5, numpy)
  assets/
    source/              dua sprite sheet asli (utuh)
    sprites/             potongan individual transparan (42, v5)
    audio/               WAV hasil sintesis prosedural (7, v5)
```
