class_name Balance
## Satu-satunya tempat angka balance THE GIANT tinggal.
## Semua script gameplay membaca dari sini, jadi mengubah jam event,
## drain Sanity, atau laju bahan bakar tidak perlu mengobrak-abrik
## main.gd / hunter_event.gd / giant_event.gd satu per satu.
## Cerita dan urutan event TIDAK berubah, hanya angkanya dipindah ke sini.

## --- Shift ---------------------------------------------------------------
const SHIFT_START_HOUR := 22.0
const SHIFT_LENGTH_MINUTES := 480.0 # 22:00 -> 06:00
## 1 detik dunia nyata = 1 menit waktu shift (shift penuh +/- 8 menit).
const MINUTES_PER_SECOND := 1.0

## --- Sanity / Stability / bahan bakar ------------------------------------
const MAX_SANITY := 100.0
const MAX_STABILITY := 100.0
const MAX_FUEL := 100.0
## Generator menyala: bahan bakar habis dalam +/- 7 menit.
const FUEL_DRAIN_PER_SECOND := 100.0 / 420.0
const DARK_STABILITY_DRAIN := 0.55 # per detik saat generator mati
const LIGHT_STABILITY_REGEN := 0.35 # per detik saat generator menyala
const HEARTBEAT_SANITY_THRESHOLD := 35.0 # di bawah ini detak jantung nyala
const LOGBOOK_SANITY_RESTORE := 4.0 # menulis laporan memulihkan sedikit

## --- Event pemburu (01:30) ------------------------------------------------
const HUNTER_TRIGGER_MINUTE := 210.0 # 22:00 + 210 menit = 01:30
const HUNTER_EVENT_DURATION := 50.0 # detik, lalu pergi sendiri
const HUNTER_SAFE_DOOR_CLOSED_TIME := 12.0 # detik pintu tertutup = aman
const HUNTER_LOOK_DRAIN := 5.5 # Sanity/detik saat menatap (satu sosok saja)
const HUNTER_LOOK_DOT := 0.72 # seberapa lurus tatapan ke pemburu
const HUNTER_START_DRAIN := 6.0 # Sanity langsung saat event mulai
const HUNTER_END_DRAIN := 14.0 # Sanity kalau event berakhir tidak aman

## --- Event Giant: kaki (03:30) --------------------------------------------
const GIANT_FOOT_TRIGGER_MINUTE := 330.0 # 22:00 + 330 menit = 03:30
const GIANT_FOOT_DURATION := 9.0 # detik kaki melangkah lewat jendela
const GIANT_FOOT_LOOK_DRAIN := 2.0 # Sanity/detik saat menatap kaki
const GIANT_FOOT_LOOK_DOT := 0.6
const GIANT_FOOT_START_DRAIN := 5.0
const GIANT_FOOT_SHAKE := 0.35 # kekuatan guncangan kamera

## --- Event Giant: mata (04:45) --------------------------------------------
const GIANT_EYE_TRIGGER_MINUTE := 405.0 # 22:00 + 405 menit = 04:45
const GIANT_EYE_DURATION := 12.0 # detik mata menempel di kaca
const GIANT_EYE_LOOK_DRAIN := 4.0 # Sanity/detik saat menatap mata
const GIANT_EYE_LOOK_DOT := 0.72
const GIANT_EYE_START_DRAIN := 5.0
const GIANT_EYE_END_DRAIN := 8.0 # Sanity saat mata mundur
const GIANT_EYE_SHAKE := 0.15

## --- Player -----------------------------------------------------------------
const PLAYER_WALK_SPEED := 3.2
const PLAYER_SPRINT_SPEED := 5.2
const PLAYER_GRAVITY := 18.0
const PLAYER_MOUSE_SENS := 0.0022
const PLAYER_PITCH_LIMIT_DEG := 82.0

## --- Kabut ------------------------------------------------------------------
## Fog eksponensial Godot: transmittance = exp(-density * jarak).
## density 0.06: 5 m -> 0.74, 10 m -> 0.55, 20 m -> 0.30, 30 m -> 0.17.
## Jadi pos + jalan dekat kebaca, pohon dekat jadi siluet gelap di kabut,
## cincin hutan (19-34 m) tertelan kabut. v5: 0.032 (kabut tidak terasa).
## Percobaan pertama 0.085 kebablasan: jendela jadi dinding kabut polos,
## pos ketutup gumpalan kabut dari jarak 8 m.
const FOG_DENSITY := 0.06
const FOG_LIGHT_COLOR := Color(0.23, 0.27, 0.22, 1) # abu kehijauan sakit, palet
const FOG_LIGHT_ENERGY := 1.0
const FOG_SKY_AFFECT := 0.85 # langit ikut berkabut, bukan hitam pekat polos
const FOG_PUFF_COUNT := 36 # v5: 10
const FOG_PUFF_ALPHA := 0.42 # v5: 0.32; 0.55 kebablasan jadi dinding
const GROUND_FOG_COUNT := 18 # lapisan kabut rendah di permukaan tanah
const GROUND_FOG_ALPHA := 0.45

## --- Grafik creepy (overlay analog horror, hud.gd) ---------------------------
## Semua angka di sini supaya intensitas bisa di-tune tanpa baca shader.
const VHS_GRAIN := 0.13 # v5: 0.055
const VHS_SCANLINE := 0.10 # kekuatan garis scanline
const VHS_CA := 0.0016 # chromatic aberration, offset UV merah/biru
const VHS_DESATURATE := 0.45 # 0 = warna asli, 1 = abu-abu sakit
const VHS_VIGNETTE := 0.38 # gelap di tepi layar
const VHS_FLICKER := 0.04 # kedip cahaya halus
const VHS_TEAR_SECONDS := 0.15 # durasi tracking tear tiap kejadian
const VHS_TEAR_SHIFT := 0.02 # seberapa jauh garis tear bergeser
