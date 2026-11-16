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
| Lepas mouse / jeda | ESC |

Di Android: export preset sudah disiapkan (lihat bawah), kontrol sentuh virtual **belum** dibuat, jadi versi Android saat ini untuk uji build, bukan untuk dimainkan penuh.

## Yang sudah jalan

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
Playthrough scripted (test rig, TIDAK ikut ZIP): jalur menang
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
graph (`scripts/test_rig.gd` mode `verify`, TIDAK ikut ZIP):
149 Sprite3D, 36 unik, semua 16 nama di atas count >= 1
(`hunter.png` count 0 di mode verify karena pemburu hanya spawn saat
event 01:30; sudah terbukti visual di `v9_hunter2`). Jalur menang
scripted masih lolos setelah perubahan ini (Sanity 84), headless 300
frame tanpa script error (hanya warning dummy-renderer yang dikenal).

## Yang masih placeholder / belum ada

- Belum ada kontrol sentuh untuk Android, belum ada menu utama / layar intro, belum ada save.
- Langkah kaki dan beberapa suara adalah sintesis sederhana, bukan rekaman; audio baru terbukti dari status `playing` di sandbox tanpa sound card, belum pernah didengar telinga manusia.
- Model masih berupa kotak + sprite billboard; ini prototipe gameplay, bukan build visual final.
- Proyek ini **sudah diuji di Godot 4.3 headless** (2026-11-16): `--import` bersih setelah dua sheet sumber yang tadinya JPEG ber-ekstensi .png dikonversi ke PNG asli, dan game jalan 300 frame tanpa script error. Peringatan mesh di headless dummy renderer bukan error game.

## Struktur

```
the-giant-godot/
  project.godot          scene utama, autoload, InputMap
  export_presets.cfg     Windows / Android / Web
  icon.svg
  scenes/main.tscn       scene utama (ramping, level dibangun dari kode)
  scripts/
    game_state.gd        autoload: sanity, stability, fuel, tugas, jam
    player.gd            first-person controller
    main.gd              terrain, hutan, pagar, loop shift
    guard_post.gd        bangunan pos jaga + pintu
    hud.gd               HUD dari kode
    audio.gd             manajer audio
    hunter_event.gd      event dua pemburu 01:30
    giant_event.gd       event kaki Giant 03:30 + mata Giant 04:45
    interactables/       generator, radio, logbook, lantern, door
  assets/
    source/              dua sprite sheet asli (utuh)
    sprites/             potongan individual transparan
    audio/               WAV hasil sintesis prosedural
```
