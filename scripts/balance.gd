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
const FOG_PUFF_ALPHA := 0.34 # v6: 0.42; diturunkan karena volumetric fog menambah haze (0.55 dulu kebablasan jadi dinding)
const GROUND_FOG_COUNT := 18 # lapisan kabut rendah di permukaan tanah
const GROUND_FOG_ALPHA := 0.38 # v6: 0.45, alasan sama seperti FOG_PUFF_ALPHA

## --- Kabut volumetrik (Forward+ saja) ---------------------------------------
## Godot 4.3: volumetric fog HANYA jalan di renderer Forward+; di
## Compatibility (Web/Android) properti ini diabaikan diam-diam dan game
## tetap pakai fog eksponensial + billboard di atas. Desktop (Windows)
## pakai forward_plus, mobile/web tetap gl_compatibility lewat
## rendering_method.mobile di project.godot. main.gd mendeteksi lewat
## Balance.volumetric_active() (setting proyek + OS.has_feature).
## density = extinction per meter di dalam volume (beda dari fog_density):
## v13 ronde 1 (0.045 + fog 0.04 = 0.085/m): kebablasan, hutan hilang
## total, pos dari 19 m tinggal bayangan samar. Ronde 2: 0.030 + 0.04
## = 0.07/m: 5 m -> 0.70, 10 m -> 0.50, 20 m -> 0.25 (pohon dekat
## samar), 30 m -> 0.12 (cincin jauh tertelan).
const VOL_FOG_ENABLED := true
const VOL_FOG_DENSITY := 0.030
const VOL_FOG_ALBEDO := Color(0.35, 0.42, 0.34, 1) # hamburan cahaya bulan, hijau sakit
const VOL_FOG_EMISSION := Color(0.10, 0.12, 0.09, 1) # pijar kabut sendiri, redup
const VOL_FOG_EMISSION_ENERGY := 0.10 # v13 ronde 1: 0.25, veil pijar terlalu terang
const VOL_FOG_ANISOTROPY := -0.15 # v13 ronde 2: +0.35 (forward scatter) melemahkan beam yang dilihat dari belakang lampu; beam senter + halo lampu teras butuh BACKscatter, jadi negatif ringan. Ronde 3: -0.15.
const VOL_FOG_SKY_AFFECT := 1.0 # langit ikut berkabut, pohon tidak lagi siluet di langit hitam
const VOL_FOG_LENGTH := 40.0 # jangkauan froxel: cukup untuk hutan 19-34 m
## CATATAN: Godot 4.3 TIDAK punya volumetric_fog_depth_begin/end
## (dicek lewat ClassDB; assignment-nya melempar SCRIPT ERROR tiap run).
## Jangkauan froxel diatur cuma lewat VOL_FOG_LENGTH.
## Saat volumetric aktif, fog eksponensial diturunkan supaya total
## extinction tidak kebablasan (dulu 0.06, lihat percobaan 0.085).
const FOG_DENSITY_VOLUMETRIC := 0.04

## Volumetric fog hanya bisa aktif di renderer Forward+ (desktop).
## Godot 4.3 TIDAK punya RenderingServer.get_current_rendering_method(),
## jadi deteksi pakai setting proyek + platform: Web/Android/iOS
## selalu pakai renderer mobile/Compatibility (volumetric diabaikan),
## desktop pakai rendering_method dari project.godot.
static func volumetric_active() -> bool:
	if not VOL_FOG_ENABLED:
		return false
	if OS.has_feature("web") or OS.has_feature("mobile"):
		return false
	return str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility")) == "forward_plus"

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
