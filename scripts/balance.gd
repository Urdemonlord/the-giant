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
## v29 (Arya: "kabutnya belum pekat", 2026-11-18): +40% dari 0.06.
## 0.084: 5 m -> 0.66, 10 m -> 0.43, 20 m -> 0.19, 30 m -> 0.08 —
## cincin hutan 19-34 m kini tertelan (dulu 0.17-0.30 di 20-30 m),
## pos dari gerbang (15,7 m) tinggal 0.27 tapi tetap massa gelap +
## lampu teras, generator 3-5 m dari pemain 0.66-0.73. Bukan dobel
## buta: v6 gagal di 0.085/m TOTAL dengan fog_light_energy 1.0 +
## puff alpha 0.55 (kabut MENYALA jadi dinding); sekarang energi
## 0.35 + puff 0.44, kabutnya murk gelap, bukan dinding terang.
## v30 (Arya: "gada bedanya" setelah v29): 0.084 -> 0.12. Total
## disamakan antar renderer (prinsip v30): Compatibility 0.12,
## Forward+ 0.078 + 0.048 = 0.126 — jadi screenshot sandbox
## mewakili Windows. 0.12: 5 m -> 0.55, 10 m -> 0.30, 15 m -> 0.17,
## 20 m -> 0.09 (jarak larut ~20 m), 30 m -> 0.03. Pos dari
## gerbang (15,7 m) tinggal 0.15 — massa gelap + lampu teras saja;
## generator 3-5 m dari pemain 0.55-0.70, tetap kebaca. Kalau
## langkah ini menelan pos/generator, mundur ke 0.10.
const FOG_DENSITY := 0.12
const FOG_LIGHT_COLOR := Color(0.50, 0.50, 0.51, 1) # v32 (kabut NETRAL ala Silent Hill, Arya 20:05 WIB):
	# v31 (0.45, 0.53, 0.43) -> (0.50, 0.50, 0.51). Luminance Rec709
	# 0.506 -> 0.501 (DIPERTAHANKAN, ini ronde HUE bukan terang).
	# Hijau sakit KELUAR dari kabut: G/R dulu 1.178, kini 1.00; B
	# sedikit di atas R (dingin tipis ala Silent Hill), bukan hijau.
	# Satu warna untuk game + menu + ground fog + puff.
	# GELAP; kabut harus jadi hal paling terang di frame kecuali
	# lampu. Energi diturunkan 0.42 -> 0.32 supaya produk
	# (warna x energi) 0.128 -> 0.162: di antara langkah C v30
	# (0.128, aman) dan langkah B v30 yang GAGAL (0.199, veil
	# lebih terang dari pos, senter mati). Density v30 TIDAK
	# diubah (game 0.12, menu 0.10) — ini ronde WARNA, bukan density.
	# Kalau veil menelan kepala (delta kubah-kabut < 4) atau senter
	# mati, JANGAN kejar delta lewat energi: v32 membuktikan energi
	# menggerakkan gelap dan senter bersama (0.29 -> 0.26: gelap
	# -1.3, senter -0.95). Kuatkan beam senter (main.tscn) sebagai gantinya.
	# Langkah B terlalu MENYALA: veil lebih terang dari pohon DAN
	# dari pos (center night_dark L22.5 > pohon L19.8), pos jadi
	# kotak kabut bercahaya, bukan massa gelap; senter nyaris
	# tidak menambah apa-apa (delta +1.6, dulu +4.6). Kabut harus
	# LEBIH TERANG dari pohon jauh (supaya terbaca sebagai kabut,
	# bukan kegelapan) tapi LEBIH GELAP dari pos dekat (supaya pos
	# tetap massa gelap di dalam kabut). v31 masih abu kehijauan
	# sakit; v32 menghapus hijau itu dari kabut (lihat FOG_LIGHT_COLOR
	# di atas) atas pilihan Arya — netral abu-abu ala Silent Hill.
const FOG_LIGHT_ENERGY := 0.26 # v32: 0.29 -> 0.26. Netralisasi hue menaikkan malam gelap pos 22.0 -> 24.8 (dua sampel v36/v36b) dan delta senter jatuh +4.6 -> ~+1.6. Energi 0.26 memotong gelap 24.8 -> 23.5 TAPI senter ikut -0.95 (v36c): energi menggerakkan gelap dan senter BERSAMA, jadi delta TIDAK pulih lewat energi. Delta dipulihkan lewat senter (SpotLight3D main.tscn 2.4 -> 7.0, lihat catatan di sana): delta rerata +4.6 (3 sampel beam 7.0: +5.1, +4.9, +3.9). Produk kini 0.130, di antara v30 (0.128, aman) dan v31 (0.147). Pelajaran v32: jangan pakai energi untuk mengejar delta senter — pakai beam.
	# Density 0.12 TETAP — yang melarutkan pohon adalah density,
	# bukan kecerahan; yang meratakan kontras adalah kecerahan.
const FOG_SKY_AFFECT := 0.85 # langit ikut berkabut, bukan hitam pekat polos
const FOG_PUFF_COUNT := 48 # v30: 36 -> 48 (kabut punya tekstur yang terlihat)
const FOG_PUFF_ALPHA := 0.50 # v30: 0.40 -> 0.50 (gumpalan tetap + pangkal kepala menu;
	# 0.55 dulu kebablasan jadi dinding). Dipakai gumpalan tetap (4x)
	# + pangkal kepala menu; gumpalan acak di-grade menurut jarak
	# (dekat 0.52, jauh 0.36) di main.gd, ground fog 0.58 -> 0.46.
const GROUND_FOG_COUNT := 32 # v30: 24 -> 32 (pita kabut tanah lebih tebal + jelas)
const GROUND_FOG_ALPHA := 0.55 # v30: 0.44 -> 0.55. Dipakai sebagai
	# acuan; ground fog acak di-grade menurut jarak (dekat 0.58,
	# jauh 0.46) di main.gd, puff deterministik 0.56.

## --- Grade keluarga sprite (v28) -------------------------------------------
## SATU grade untuk semua sprite — dulu tint tersebar sebagai literal
## di tiap call site (kepala 1.2-1.3, papan 0.9, puff 0.62/0.68/0.58,
## wajah papan 0.55, pohon 0.8, props 0.85, darah 1.6) + grade PNG
## v26 yang mencerahkan kepala 2.2-2.7x. Hasilnya di screenshot v29:
## kabut L36, pohon L19, kepala L71-96 — kepala 35-60 poin lebih
## terang dari kabutnya sendiri, terbaca seperti gambar ditempel.
## Semua sprite di game ini UNSHADED (SpriteRegistry.billboard tidak
## menyalakan shaded; cahaya scene tidak menyentuh sprite), jadi
## tint + grade PNG INILAH pencahayaannya. Keluarga malam, diukur
## dari v29: jauh = dingin redup (menempel di kabut, bukan di atasnya),
## tengah = 0.8, papan = 0.55, kabut = abu kehijauan sakit.
## Darah TIDAK masuk keluarga (aksen merah, satu-satunya, v11).
const GRADE_FAR_TINT := Color(0.95, 0.98, 1.0, 1.0) # siluet jauh unshaded: kepala, gerbang, gajah, pemburu
const GRADE_TREE_TINT := Color(0.8, 0.85, 0.85, 1.0) # pohon (dulu literal sama di _make_tree)
const GRADE_PROP_TINT := Color(0.85, 0.85, 0.85, 0.95) # props + decal tanah (dulu literal di _scatter_prop/_ground_decal)
const GRADE_SIGN_TINT := Color(0.55, 0.58, 0.55, 1.0) # wajah papan tanda (dulu literal di _make_sign)
const GRADE_FOG_TINT := Color(0.72, 0.73, 0.74, 1.0) # gumpalan + ground fog (v32: 0.70/0.76/0.66 -> 0.72/0.73/0.74, luminance 0.73 TETAP; hijau keluar, puff tetap sedikit lebih terang dari veil supaya teksturnya kebaca di atas kabut netral)

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
## v29: +40% semua komponen (total Forward+ awal 0.070 -> 0.098/m,
## malam dalam 0.076 -> 0.106/m; Compatibility 0.06 -> 0.084 awal,
## 0.07 -> 0.098 malam). 0.106/m: 5 m -> 0.59, 10 m -> 0.35,
## 15 m -> 0.20, 20 m -> 0.12, 30 m -> 0.04 — jarak larut
## (transmittance 0.10) maju dari ~30 m ke ~22 m. Pohon dekat
## (9-15 m) tinggal siluet 0.20-0.39, pos dari gerbang 0.19.
## v30: total disamakan antar renderer — Forward+ 0.078 + 0.048 =
## 0.126/m (awal), malam dalam 0.078 + 0.058 = 0.136/m; Compatibility
## 0.12 awal, 0.142 malam dalam. Screenshot sandbox kini mewakili
## Windows (selisih total < 5%).
const VOL_FOG_ENABLED := true
const VOL_FOG_DENSITY := 0.048
const VOL_FOG_ALBEDO := Color(0.50, 0.50, 0.51, 1) # hamburan cahaya bulan, NETRAL (v32: 0.45/0.53/0.43 -> sama dengan FOG_LIGHT_COLOR baru, supaya Forward+ dan Compatibility satu keluarga)
const VOL_FOG_EMISSION := Color(0.11, 0.11, 0.115, 1) # pijar kabut sendiri, redup, netral (v32: 0.10/0.12/0.09 -> netral)
const VOL_FOG_EMISSION_ENERGY := 0.10 # v13 ronde 1: 0.25, veil pijar terlalu terang
const VOL_FOG_ANISOTROPY := -0.15 # v13 ronde 2: +0.35 (forward scatter) melemahkan beam yang dilihat dari belakang lampu; beam senter + halo lampu teras butuh BACKscatter, jadi negatif ringan. Ronde 3: -0.15.
const VOL_FOG_SKY_AFFECT := 1.0 # langit ikut berkabut, pohon tidak lagi siluet di langit hitam
const VOL_FOG_LENGTH := 40.0 # jangkauan froxel: cukup untuk hutan 19-34 m
## CATATAN: Godot 4.3 TIDAK punya volumetric_fog_depth_begin/end
## (dicek lewat ClassDB; assignment-nya melempar SCRIPT ERROR tiap run).
## Jangkauan froxel diatur cuma lewat VOL_FOG_LENGTH.
## Saat volumetric aktif, fog eksponensial diturunkan supaya total
## extinction tidak kebablasan (dulu 0.06, lihat percobaan 0.085).
## v29: 0.04 -> 0.056 (+40%, seiring VOL_FOG 0.030 -> 0.042):
## total Forward+ awal 0.056 + 0.042 = 0.098/m (dulu 0.070/m).
## v30: 0.056 -> 0.078. BERSAMA volumetric 0.048, total Forward+
## 0.126/m — sama dengan Compatibility 0.12/m. CATATAN v30: klaim
## lama di sini ("angka inilah SATU-SATUNYA kabut yang kelihatan
## di screenshot") SUDAH TIDAK BENAR sejak perbaikan
## volumetric_active(): sandbox kini mengambil cabang Compatibility
## (FOG_DENSITY 0.12), bukan angka ini. Angka ini hanya komponen
## eksponensial DI DALAM Forward+ (Windows).
const FOG_DENSITY_VOLUMETRIC := 0.078

## Volumetric fog hanya bisa aktif di renderer Forward+ (desktop).
## Godot 4.3 TIDAK punya RenderingServer.get_current_rendering_method(),
## jadi deteksi pakai setting proyek + platform: Web/Android/iOS
## selalu pakai renderer mobile/Compatibility (volumetric diabaikan),
## desktop pakai rendering_method dari project.godot.
## v30 (Arya: "gada bedanya" setelah v29): setting proyek SAJA tidak
## cukup — sandbox jalan dengan --rendering-driver opengl3 sementara
## setting tetap forward_plus, jadi fungsi ini mengembalikan TRUE
## padahal renderer Compatibility MENGABAIKAN volumetric. Akibatnya
## di sandbox: density eksponensial stuck di FOG_DENSITY_VOLUMETRIC
## (0.056), bump malam tidak pernah jalan (cabang else tidak
## tersentuh), dan menu tidak pernah memakai MENU_FOG_DENSITY
## (cabang else _setup_menu_backdrop tidak tersentuh). Kenaikan v29
## (+40%) praktis tidak sampai ke gambar sandbox — itulah kenapa
## Arya benar: tidak ada bedanya. Pembeda yang TERBUKTI jalan di
## Godot 4.3: RenderingServer.get_rendering_device() — null di
## Compatibility (OpenGL, tanpa RenderingDevice), non-null di
## Forward+/Mobile (RD). Diverifikasi langsung: Xvfb + opengl3 ->
## null; Xvfb + Vulkan (Forward+) -> non-null. Di --headless juga
## null, tapi headless tidak pernah me-render screenshot.
static func volumetric_active() -> bool:
	if not VOL_FOG_ENABLED:
		return false
	if OS.has_feature("web") or OS.has_feature("mobile"):
		return false
	if RenderingServer.get_rendering_device() == null:
		return false
	return str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility")) == "forward_plus"

## --- Kurva malam (v14, suasana; v27 digelapkan) ---------------------------
## Malam makin dalam sampai ~02:00, bertahan gelap sampai ~04:00, lalu
## fajar mengintip dari 05:00. Semua lerp KECIL supaya tidak merusak
## tuning kabut v6/v8 yang sudah susah payah.
## v27 (kritik gameplay #3, Luci: level-design — cahaya sebagai
## mekanik): kurva LAMA terlalu terang di luar pos (ambient 0.65 ->
## 0.50, bulan 0.75 -> 0.55): hutan kebaca abu-abu tanpa senter,
## senter tidak ada gunanya. Sekarang ambient 0.28 -> 0.14, bulan
## 0.45 -> 0.28: tanpa senter, jalan ke generator nyaris gelap
## gulita; bulan cuma cukup untuk siluet samar pohon + bayangan
## Giant dari jauh. Interior pos TIDAK ikut gelap: lentera (energi
## 2.0) + lampu teras generator yang menerangi dalam. Menu pakai
## MENU_AMBIENT/MENU_MOON sendiri, tidak tersentuh.
const NIGHT_DEEP_MINUTE := 240.0 # 02:00, titik tergelap
const NIGHT_HOLD_MINUTE := 360.0 # 04:00, gelap bertahan sampai sini
const NIGHT_DAWN_MINUTE := 420.0 # 05:00, fajar mulai mengintip
const NIGHT_MOON_START := 0.45
const NIGHT_MOON_DEEP := 0.28
const NIGHT_MOON_DAWN := 0.55
const NIGHT_AMBIENT_START := 0.28
const NIGHT_AMBIENT_DEEP := 0.14
const NIGHT_AMBIENT_DAWN := 0.35
const NIGHT_VOL_DEEP := 0.058 # v30: 0.050 -> 0.058 (Forward+ malam dalam 0.078 + 0.058 = 0.136/m)
const NIGHT_VOL_DAWN := 0.039 # v29: 0.028 -> 0.039 (+40%)

## --- Hold-to-interact (v27, kritik #5) --------------------------------------
## Interaksi penting butuh WAKTU, bukan satu pencet instan: generator
## 4,5 detik tarik tuas (kamera terkunci menghadap generator, suara
## mesin bising), buku jaga 3 detik menulis (menunduk, rentan).
## Lepas tombol sebelum selesai = progres batal. Yang lain tetap instan.
const HOLD_GENERATOR_SECONDS := 4.5
const HOLD_LOGBOOK_SECONDS := 3.0

## --- Sanity di kegelapan (v27, kritik #6) ------------------------------------
## Bar Sanity dulu statis di 2 menit pertama karena semua drain baru
## aktif saat event (pemburu 01:30, kaki 03:30, mata 04:45). Sekarang
## Sanity hidup sejak awal: di luar pos dalam gelap (tanpa senter,
## di luar jangkauan lampu teras) ia turun pelan; di dalam pos dekat
## cahaya (lentera/generator menyala) ia pulih pelan. Laju kecil
## sengaja: ini tekanan suasana, bukan drain event (5,5/dtk).
const DARK_SANITY_DRAIN := 0.5 # per detik di gelap di luar pos
const DARK_SANITY_REGEN := 0.5 # per detik dekat cahaya pos
const PORCH_LIGHT_PROTECT_RANGE := 7.0 # meter dari lampu teras

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
const VHS_GRAIN_LOW_SANITY := 0.12 # v33: dulu 0.16 (grain dilembutkan, tetap naik saat Sanity rendah)
const VHS_DESAT_LOW_SANITY := 0.52 # dulu 0.45
const VHS_VIGNETTE_LOW_SANITY := 0.45 # dulu 0.38

## --- Grafik creepy (overlay analog horror, hud.gd) ---------------------------
## Semua angka di sini supaya intensitas bisa di-tune tanpa baca shader.
const VHS_GRAIN := 0.09 # v33: dulu 0.13 (grain dilembutkan ~30%, scanline tetap; analog tetap hidup)
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
## v24 (kritik #4, Luci: camera-systems framing): kamera digeser
## ke kanan (+0,50 x) + sedikit mundur/naik, FOV 62 -> 66, pitch
## -24 -> -25. Efeknya: buku bergeser ke kiri bingkai, jendela
## selatan yang tadinya kecil di kiri atas sekarang TERBUKA LEBAR
## di tengah-atas layar, dan dinding kayu kosong di kanan tidak lagi
## mendominasi. Angka dihitung dari geometri garis pandang (lihat
## catatan v24 di main.gd), lalu dibuktikan dari screenshot — bukan
## ditebak. Buku tetap utuh di frame (tepi kiri halaman baris
## -1,47 m dari sumbu pandang vs setengah lebar pandang 1,73 m).
const MENU_DESK_CAM_POS := Vector3(-0.80, 2.15, 0.10)
const MENU_DESK_CAM_PITCH_DEG := -18.0 # v26: -25 -> -18, supaya
# kubah kepala Zunisha 5,2 m di z 12,5 masuk frame (diukur probe:
# kubah di y layar ~+16 px pada -18; pada -20 masih -12 px, pada
# -16 buku menabrak tepi bawah frame)
const MENU_DESK_CAM_YAW_DEG := 180.0
const MENU_DESK_CAM_FOV := 66.0
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
## v29: MENU_VOL 0.025 -> 0.032 (+28%), MENU_FOG 0.05 -> 0.065
## (+30%) — SENGAJA lebih kecil dari +40% game: kepala di z 12,5
## (total Windows 0.056 + 0.032 = 0.088/m, dulu 0.065/m) tinggal
## transmittance 0.35; delta kubah-kabut (v31: 9 poin di sandbox
## 0.04/m) menyusut ke ~3 poin di Windows — kubah tetap kebaca,
## tapi pangkal belalai + kaki pohon larut, sesuai permintaan.
## Kalau vol ikut +40% (0.035), total 0.091/m, kubah ~2 poin:
## terlalu tipis, jangan.
## v30 (Arya: "gada bedanya"): MENU_FOG 0.065 -> 0.10, MENU_VOL
## 0.032 -> 0.04. Total menu: Compatibility 0.10/m, Forward+
## 0.078 + 0.04 = 0.118/m — sandbox sedikit di bawah Windows,
## jadi screenshot TIDAK melebih-lebihkan kabut. Kepala di 12 m:
## transmittance 0.30 (sandbox) / 0.24 (Windows). Guardrail:
## |kubah - kabut| >= 4 poin diukur, kalau di bawah itu mundur
## MENU_FOG ke 0.09. CATATAN v30: kenaikan MENU_FOG v29 (0.05 ->
## 0.065) TIDAK PERNAH kelihatan di sandbox — cabang else
## _setup_menu_backdrop tidak tersentuh karena volumetric_active()
## salah mengembalikan true di opengl3 (lihat perbaikan fungsi itu).
const MENU_VOL_DENSITY := 0.04
const MENU_FOG_DENSITY := 0.10
## Grade menu: grain halus saja, BUKAN bingkai CCTV (kritik #3).
## Scanline/tear/flicker dimatikan; desat + vignette tipis, CA 0.
const MENU_GRADE_GRAIN := 0.04 # v33: dulu 0.05
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
