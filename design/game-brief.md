# THE GIANT — Game Brief (satu halaman)

> Dibuat dengan cara kerja Claude Code Game Studios: brief satu halaman,
> kata-kata Arya dipertahankan, tiap baris dicek built / missing / broken
> dari screenshot dan kode. Rigor: minimal.

## In your words (Arya)

"Teror gajah raksasa di kabut gelap, kayak The Mist, ambil mitos kuburan
gajah dan hantu gajah dari Riau/Sumatera. Teror psikologis, bukan
jumpscare, megalophobia. Visualnya harus creepy kek analog horror di
reels Unholy Dream atau game indie horror No I'm Not a Human."

"Manusianya yang monster. Penebang liar yang bikin kuburan itu. Giant
itu penjaga kuburan gajah, marah karena tempat matinya diganggu."

## Look

Analog horror, kamera pos jaga yang rusak: grain VHS tebal, scanlines,
tracking tear sesekali, REC CAM 07, warna desaturasi ke hijau-abu sakit.
Satu sumber cahaya per frame. Kabut tebal, hutan jauh tertelan kabut.
Giant tidak pernah tampil utuh: hanya kaki lewat jendela, dan satu mata
di kaca. Semua gambar dari sprite sheet Arya, bukan geometri primitif.

## First minute

Menu utama, lalu intro singkat yang bisa di-skip: Pos Jaga 07, Taman
Nasional Malayunesia, shift 22:00–06:00. Pemain di dalam pos, jam
22:00, tugas pertama muncul: nyalakan generator. Aturan briefing
(v27, sesudah kritik gameplay): yang dilarang adalah MEMBUKA PINTU
untuk yang mengetuk dari arah hutan, bukan keluar pos — generator
memang di luar dan tugas pertama memang menyuruh keluar sebelum
gelap, lalu cepat kembali. Di atas meja ada koran
dan surat yang ditinggal penjaga sebelumnya. Radio di meja memutar
potongan siaran.

## Challenge

Satu shift, satu pos jaga, satu malam. Jaga lampu tetap menyala
(generator + bahan bakar), tulis laporan, cek radio. Generator
dinyalakan dengan TAHAN tombol 4,5 detik (tarik tuas, kamera
terkunci menghadap generator); laporan ditulis dengan TAHAN 3 detik
(menunduk, pandangan terkunci). Gelap di luar pos menguras Sanity
pelan sejak awal shift; dekat lampu/lentera di dalam pos Sanity
pulih. Jam 01:30 dua
pemburu berhenti dan menatap pos (tutup pintu, tunggu di dalam).
Jam 03:30 kaki Giant lewat di jendela. Jam 04:45 mata Giant menempel
di kaca. Menatap apa pun yang tidak seharusnya ada menguras Sanity.
Bertahan sampai 06:00.

## Features

1. First-person di pos jaga (WASD + mouse, senter F, interaksi E,
   kontrol sentuh Android). UI menyesuaikan platform (v27): di layar
   sentuh prompt "Ketuk", blok kontrol sentuh, tombol SENTER jauh
   dari E.
2. Shift 22:00–06:00 dengan Sanity, Stability, bahan bakar, 5 tugas.
   Hutan malam gelap gulita tanpa senter (v27); senter membuat jalan
   terbaca.
3. Event pemburu 01:30, kaki Giant 03:30, mata Giant 04:45.
4. Koran Harian Rimba Post bisa dibaca di meja: "Gajah Liar Masuk
   Kebun Sawit, Petani Rugi Miliaran".
5. Surat izin pelepasan hutan 12.400 hektar bisa dibaca di meja,
   dengan catatan tangan di pinggir: "gajah sudah tidak ada di sini".
6. Radio 5 siaran, termasuk "Sawit adalah anugerah Tuhan untuk rakyat
   Malayunesia".
7. Intro singkat (bisa di-skip) dan ending menang/kalah dengan payoff
   cerita, lalu kembali ke menu.
8. Menu utama, save/load, pause, overlay VHS, kabut tebal.

## Keep

- Malayunesia (negara fiksi), bukan Indonesia.
- Pos jaga, bukan rumah. Rutinitas jaga sebagai hal sehari-hari.
- Satir spesifik: koran sawit, pidato radio, surat 12.400 hektar.
- Giant tidak pernah tampil utuh. Tanpa jumpscare murahan.

## Avoid

- Gambar generate berfilter VHS (slop). Aset dari sheet Arya saja.
- Khotbah di dalam game. Cerita lewat benda, bukan ceramah.
- Senjata. Tidak ada cara melawan Giant.

## Left for later (cut / bukan v1)

- APK Android (tidak ada SDK di sandbox; preset tetap ada).
- Kabut volumetrik yang bergerak (billboard statis cukup untuk look).
- Voice acting radio (siaran tetap teks).
- Level kedua / hutan terbuka (satu pos, satu malam).
- Co-op / penjaga kedua.

## Dates

- v6 (2026-11-16): kabut + shader VHS, playtest scripted PASS.
- v7 (2026-11-16): brief ini + koran/surat bisa dibaca + intro +
  ending beneran. Handover card di README.
- v7 QA (2026-11-16, Godot 4.3 Xvfb 1280x720): `story` PASS fails=0,
  `playtest` PASS fails=0, `verify` registry 42 nama 0 hilang, intro
  dicek run langsung `main.tscn` + screenshot, `shots12` 3 shot.
- v27 (2026-11-18): kritik gameplay — briefing konsisten, hutan
  gelap + senter penting, UI platform, hold-to-interact (generator
  4,5 dtk, buku 3 dtk), Sanity di gelap sejak awal; poin
  third-person ternyata artefak rekaman video, bukan bug game.
  `shots27` 7 shot dibaca, `playtest` PASS fails=0, `story` PASS,
  `verify` registry 78 nama 0 hilang, menu 31/31.

## Cek per baris (v7, dari screenshot + kode)

- Look analog horror / VHS / REC CAM 07: **built** (shader v6,
  `v12_*` + `v11_*`).
- Giant tidak pernah utuh (kaki + mata saja): **built** (`giant_event.gd`,
  `v12_playtest_foot` / `v12_playtest_eye`). **ATURAN DIHAPUS Arya
  2026-11-18 15:50 WIB untuk MENU (kepala gajah utuh boleh sebagai
  siluet, v26); event dalam game (kaki 03:30, mata 04:45, hunter
  01:30) tetap seperti sekarang sampai Arya bilang lain.**
- Semua gambar dari sheet Arya: **built** (registry 42 nama, 0 hilang).
- First minute (menu, intro skip, tugas generator, koran + surat di
  meja, radio): **built** (`v12_intro.png`, `v12_desk_docs*.png`).
- Challenge (shift, pemburu 01:30, kaki 03:30, mata 04:45, Sanity,
  bertahan 06:00): **built** (`playtest` PASS Sanity akhir 100).
- Feature 1-3 (first-person + sentuh, shift + 5 tugas, 3 event):
  **built**.
- Feature 4 (koran bisa dibaca, headline sawit): **built**
  (`v12_doc_newspaper.png`, headline + kalimat "yang tidak ditulis"
  + catatan alas makan).
- Feature 5 (surat 12.400 ha + "gajah sudah tidak ada di sini"):
  **built** (`v12_doc_permit.png`).
- Feature 6 (radio 5 siaran, termasuk pidato sawit): **built**
  (kode `radio.gd`, sudah ada sejak v1).
- Feature 7 (intro + ending menang/kalah + kembali ke menu):
  **built** (`v12_intro.png`, `v12_ending_win.png`,
  `v12_ending_lose.png`, kalimat penutup faktual di kedua ending).
- Feature 8 (menu, save/load, pause, VHS, kabut): **built**.
- Keep (Malayunesia, pos jaga bukan rumah, satir spesifik, Giant
  tidak utuh, tanpa jumpscare): **built**.
- Avoid (tanpa gambar generate, tanpa khotbah, tanpa senjata):
  **built**. Cerita lewat benda; satu-satunya kalimat faktual ada di
  layar akhir, bukan ceramah di tengah game.
- **Broken: tidak ada yang diketahui di lingkup v7.** Dua bug yang
  ketemu QA v12 sudah diperbaiki dan lolos ulang (lihat handover).

## Cut yang diusulkan (/cut)

Sudah dipotong sejak awal dan tetap dipotong (lihat "Left for later"):
APK Android, kabut volumetrik bergerak, voice acting radio, level
kedua / hutan terbuka, co-op. Tambahan usulan potong di v7:

- Tidak ada sistem gameplay baru sampai satu shift penuh dimainkan
  manusia. Cerita sudah cukup; yang kurang sekarang adalah rasa,
  bukan sistem.
- Tidak ada dokumen cerita ketiga. Dua dokumen (koran + surat) cukup;
  yang ketiga akan jadi pajangan.
- Tidak ada adegan kabur / kejar-kejaran di akhir. Ending berhenti di
  fajar, sesuai brief.

## Polish list (belum dikerjakan, urut prioritas)

1. Audio didengar telinga manusia + mix (saat ini cuma bentuk
   gelombang + jalur play yang terbukti).
2. Shift penuh dimainkan manusia end-to-end, lalu feedback.
3. Kertas koran/surat: tekstur cetakan asli, bukan kotak datar + garis
   tinta (panel baca sudah benar, visual mejanya masih polos).
4. Kaki Giant lewat jendela masih terbaca seperti kolom coklat besar;
   telapak di bawah ambang jendela.
5. Mata Giant: detail terbatas sumber ~25 px (sudah di-upscale, tidak
   bisa lebih tajam tanpa gambar baru).
6. Gerbang + poacher topeng merah kurang kebaca dalam gelap penuh.
7. Tuning kontrol sentuh di HP sungguhan.
8. Intro: latar belakang panel masih interior pos yang gelap; bisa
   ditambah slow pan keluar jendela.
