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

## --- Kurva malam (v14, suasana) ----------------------------------------------
## Malam makin dalam sampai ~02:00, bertahan gelap sampai ~04:00, lalu
## fajar mengintip dari 05:00. Semua lerp KECIL supaya tidak merusak
## tuning kabut v6/v8 yang sudah susah payah: bulan 0.75 -> 0.55 -> 0.85,
## ambient 0.65 -> 0.50 -> 0.70, fog volumetrik 0.030 -> 0.036 -> 0.028.
## Tidak menyentuh gameplay (generator/lampu/tugas tetap seperti semula).
const NIGHT_DEEP_MINUTE := 240.0 # 02:00, titik tergelap
const NIGHT_HOLD_MINUTE := 360.0 # 04:00, gelap bertahan sampai sini
const NIGHT_DAWN_MINUTE := 420.0 # 05:00, fajar mulai mengintip
const NIGHT_MOON_DEEP := 0.55
const NIGHT_MOON_DAWN := 0.85
const NIGHT_AMBIENT_DEEP := 0.50
const NIGHT_AMBIENT_DAWN := 0.70
const NIGHT_VOL_DEEP := 0.036
const NIGHT_VOL_DAWN := 0.028

## --- Goyang kamera trauma (v14, game-feel) -----------------------------------
## game-feel: trauma^2 + summed sines, meluruh di real time, snap ke rest.
## Menggantikan randf_range per frame di player.gd (yang skill sebut
## "buzzes like static"). Roll sangat kecil supaya tidak memuakkan.
const SHAKE_DECAY := 1.2 # trauma hilang per detik (real time)
const SHAKE_MAX_OFFSET := 0.05 # meter di kamera
const SHAKE_MAX_ROLL := 0.01 # radian
const FOV_BASE := 72.0
const FOV_SANITY_NARROW := 4.0 # menyempit saat Sanity < 35 (terowongan)
const FOV_EVENT_NARROW := 1.5 # tambahan saat event Giant aktif

## --- Generator sekarat (v14) --------------------------------------------------
## Di bawah ambang ini lampu teras + generator mulai berkedip (bukan
## strobo: redup singkat, paling sering ~2x/detik di ambang parah).
const GEN_FLICKER_FUEL := 25.0
const GEN_SPUTTER_FUEL := 10.0

## --- Dentum jauh (v14) -------------------------------------------------------
## Dentum Giant dari kejauhan, sebelum event kaki 03:30: petunjuk audio
## tanpa menampakkan apa pun. Hanya di jendela jam ini, tidak saat event
## pemburu/Giant sedang aktif.
const DISTANT_THUD_EARLIEST := 60.0 # menit shift (23:00)
const DISTANT_THUD_LATEST := 320.0 # menit shift (03:20)
const DISTANT_THUD_MIN_GAP := 90.0 # detik antar dentum
const DISTANT_THUD_MAX_GAP := 180.0

## --- VHS ikut Sanity (v14) ----------------------------------------------------
const VHS_GRAIN_LOW_SANITY := 0.16 # dulu 0.13
const VHS_DESAT_LOW_SANITY := 0.52 # dulu 0.45
const VHS_VIGNETTE_LOW_SANITY := 0.45 # dulu 0.38

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

## --- Menu v22 Opsi B (meja pos jaga, diegetic) -------------------------------
## Kamera menu pindah ke DALAM pos, di utara meja menghadap selatan:
## buku di bawah, jendela + hutan + Giant di atas. Bukan lagi kamera
## luar yang memotret pos dari jalan (v17-v21).
const MENU_DESK_CAM_POS := Vector3(-1.30, 2.10, 0.15)
const MENU_DESK_CAM_PITCH_DEG := -24.0
const MENU_DESK_CAM_YAW_DEG := 180.0
const MENU_DESK_CAM_FOV := 62.0
## Pencahayaan menu (kritik #4): ambient lebih gelap dari malam game
## (0.50 -> 0.30), bulan dikuatkan (0.55 -> 0.80) supaya jadi rim/back
## light dari selatan untuk Giant + pepohonan di luar jendela.
const MENU_AMBIENT := 0.30
const MENU_MOON_ENERGY := 0.80
## Kabut menu: lebih tipis dari malam permainan (0.036 -> 0.025
## volumetrik, 0.06 -> 0.05 biasa). Kabut adalah alat, bukan tujuan:
## di 0.036, Giant di 8-10 m terhisap kontrasnya sampai tidak kebaca
## lewat jendela; di 0.025 ia berdiri dari kabut sementara hutan
## tetap berkabut. Mood gelap menu datang dari ambient + lentera,
## bukan dari kabut maksimal.
const MENU_VOL_DENSITY := 0.025
const MENU_FOG_DENSITY := 0.05
## Grade menu: grain halus saja, BUKAN bingkai CCTV (kritik #3).
## Scanline/tear/flicker dimatikan; desat + vignette tipis, CA 0.
const MENU_GRADE_GRAIN := 0.05
const MENU_GRADE_SCANLINE := 0.0
const MENU_GRADE_CA := 0.0 # v23 (Luci: game-ui-ux + unslop):
	# CA MATI di menu. Dulu 0.003 (v25: 0.008) — shader VHS
	# menggeser kanal R/B sampai ~7 px di tepi dan ~2 px di tengah,
	# jadi SEMUA teks menu berpinggiran merah/biru. Teks di atas
	# kertas harus tajam dan bersih; grade foto (grain + desat +
	# vignette) sudah cukup untuk suasana. HUD game tetap pakai
	# VHS_CA sendiri, tidak ikut berubah.
const MENU_GRADE_DESAT := 0.15
const MENU_GRADE_VIGNETTE := 0.32
const MENU_GRADE_FLICKER := 0.0
const MENU_GRADE_TEAR := 0.0
