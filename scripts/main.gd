extends Node3D
## Scene utama THE GIANT.
## Level dibangun prosedural di sini (tanah, hutan, pagar, papan tanda)
## supaya main.tscn tetap kecil dan tidak rapuh. Pos jaga dibangun
## oleh guard_post.gd, benda interaktif oleh script masing-masing.
## Semua posisi/ukuran dibaca dari LevelData, semua angka balance dari
## Balance, semua sprite lewat SpriteRegistry. Level MASIH code-built
## (bukan scene editor) — itu keputusan sadar, bukan kekurangan yang
## disembunyikan: satu file data + kode builder lebih gampang di-diff
## dan di-review daripada scene biner.

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = LevelData.FOREST_SEED
	print("[Main] scene main siap, jam=" + GameState.clock_text())
	_apply_fog()
	_apply_level_positions()
	# v17: mode backdrop menu (lihat _setup_menu_backdrop): scene yang
	# sama dipakai menu utama sebagai latar 3D hidup. Cabang ini
	# return sebelum _apply_resume/intro/pesan supaya tidak ada state
	# save atau shift yang bocor ke menu.
	if bool(get_meta("menu_backdrop", false)):
		_setup_menu_backdrop()
		return
	var resumed := not GameState.resume_data.is_empty()
	_apply_resume()
	if not has_node("Ground"):
		_build_terrain()
	if not has_node("Forest"):
		_build_forest()
	# Intro shift (brief v7): hanya untuk shift baru, bukan lanjutan
	# save, dan tidak saat dijalankan test rig / menu_autostart
	# (keduanya memberi argumen baris perintah; lihat _is_rig_run).
	if not resumed and not _is_rig_run():
		if GameState.skip_intro:
			GameState.skip_intro = false
		else:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null and hud.has_method("show_intro"):
				hud.show_intro()
	# Pesan pembuka shift.
	GameState.show_message("Jaga pos ini. Jangan biarkan mereka kembali.")
	var timer := get_tree().create_timer(4.5)
	timer.timeout.connect(func() -> void:
		if not GameState.is_task_done("generator"):
			GameState.show_message("Generator di samping pos. Nyalakan sebelum gelap makan pos ini."))

## Test rig dan menu_autostart memberi argumen baris perintah
## (mode=... / menu_autostart=1). Shift sungguhan tidak punya argumen
## itu, jadi intro hanya muncul di permainan sungguhan.
func _is_rig_run() -> bool:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("mode=") or s == "menu_autostart=1":
			return true
	return false

## v17: menu utama memakai scene ini sebagai latar 3D hidup (bukan
## gambar). Yang dibangun: kabut + terrain + hutan + pos jaga, sama
## persis dengan permainan. Yang dimatikan: waktu shift (Main
## _process), pemain (disembunyikan + semua proses mati), HUD,
## TouchControls, dan event Hunter/Giant (event mereka gated menit
## shift, tapi dimatikan juga supaya tidak ada yang bisa jalan).
## Yang tetap hidup: GuardPost _process (lampu teras fade-in) dan
## Audio (angin + jangkrik autoplay dari _ready-nya; hum generator
## ikut menyala lewat sinyal set_generator). Lampu teras butuh
## generator menyala; bahan bakar penuh jadi tidak berkedip.
## Malam yang dipakai: titik tergelap kurva v14 (jam 02:00), nilai
## final, bukan titik awal — _process mati jadi kurva tidak jalan.
## Reset shift di _on_new_game mengembalikan generator_on=false dan
## fuel=100, jadi setelan menu ini tidak bocor ke permainan.
func _setup_menu_backdrop() -> void:
	# v26 (aturan tidak-pernah-utuh DICABUT): dinding belakang menu
	# dibangun ulang dengan jendela lebar (lihat
	# guard_post.rebuild_back_wall_for_menu) — BUKAAN LAMA tidak
	# bisa menampilkan kepala utuh. Hanya instance backdrop menu.
	var post := get_node_or_null("GuardPost")
	if post != null and post.has_method("rebuild_back_wall_for_menu"):
		post.rebuild_back_wall_for_menu()
	var env_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	var moon := get_node_or_null("MoonLight") as DirectionalLight3D
	if env_node != null and env_node.environment != null and moon != null:
		# v22 (kritik #4): ambient lebih gelap, bulan dikuatkan jadi
		# rim/back light dari selatan untuk Giant + pepohonan di luar
		# jendela. Moon sudah datang dari selatan (lihat transform
		# MoonLight di main.tscn), jadi tidak perlu lampu rim baru.
		moon.light_energy = Balance.MENU_MOON_ENERGY
		env_node.environment.ambient_light_energy = Balance.MENU_AMBIENT
		if Balance.volumetric_active():
			env_node.environment.volumetric_fog_density = Balance.MENU_VOL_DENSITY
		else:
			env_node.environment.fog_density = Balance.MENU_FOG_DENSITY
	GameState.set_generator(true)
	GameState.fuel = Balance.MAX_FUEL
	if not has_node("Ground"):
		_build_terrain()
	if not has_node("Forest"):
		_build_forest()
	set_process(false)
	var player := get_node_or_null("Player") as Node3D
	if player != null:
		player.visible = false
		player.set_process(false)
		player.set_physics_process(false)
		player.set_process_input(false)
		player.set_process_unhandled_input(false)
		var pc := player.get_node_or_null("Head/Camera3D") as Camera3D
		if pc != null:
			pc.current = false
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		(hud as CanvasLayer).visible = false
		hud.set_process(false)
	var touch := get_node_or_null("TouchControls") as CanvasLayer
	if touch != null:
		touch.visible = false
		touch.set_process(false)
	for g in ["hunter_event", "giant_event"]:
		var ev := get_tree().get_first_node_in_group(g)
		if ev != null:
			ev.set_process(false)
	# v22: properti kecil di atas meja yang TERTUTUP buku menu
	# disembunyikan (koran, surat, meter, buku jaga kecil — semuanya
	# di bawah buku 2,0 x 0,70 m). Radio + lentera TETAP: mereka
	# berdiri di belakang buku sebagai benda fisik di meja.
	# v25 ronde 3: radio IKUT disembunyikan — badannya yang tinggi
	# menutupi baris Start + Continue dari sudut kamera meja
	# (terbukti di screenshot v25). Di permainan radio tetap ada.
	for n in ["Newspaper", "Permit", "Logbook", "Radio"]:
		var prop := get_node_or_null(n) as Node3D
		if prop != null:
			prop.visible = false
	# Meter getar tetap: ia berdiri di belakang buku (z 1,64, tepi
	# belakang buku 1,63), jadi mengintip di atas buku seperti benda
	# meja sungguhan, bukan tertutup.
	# v22: lentera diredupkan di menu (0.6) supaya cahaya hangatnya
	# tidak membakar tepi jauh buku jaga — tapi tetap jadi titik
	# fokus hangat di meja (kritik #4). Default permainan 1.0.
	var lantern_node := get_node_or_null("Lantern")
	if lantern_node != null and "dim_factor" in lantern_node:
		lantern_node.dim_factor = 0.6
	# v24 (kritik #1, solusi kritik: lentera ke pojok kiri luar
	# meja — di luar area kertas, bukan cuma digeser beberapa px):
	# lentera PINDAH ke sudut kiri meja (-2,32, 1,55). Kertas
	# berakhir di x -2,27, meja berakhir di x -2,40: lentera
	# berdiri 5 cm di kiri kertas, DI ATAS meja, cahayanya
	# menyinari buku dari samping kiri — tidak ada satu pun huruf
	# yang terhalang badan/glow-nya lagi. v23 hanya menggeser ke
	# belakang (alas 6 px di atas judul) dan itu TIDAK CUKUP:
	# dari kamera menu, sprite lentera tetap jatuh tepat di atas
	# ruang udara judul (terbukti di screenshot v26). z 1,55:
	# sprite lentera ada 0,18 m di utara node-nya, jadi sprite
	# di z ~1,37 — sejajar tengah buku, bukan di belakangnya.
	if lantern_node != null:
		lantern_node.position = Vector3(-2.32, lantern_node.position.y, 1.55)
	# v22: kamera menu DI DALAM pos, di utara meja menghadap selatan
	# (yaw 180 = menghadap +z). Buku di bawah frame, jendela selatan
	# + hutan + Giant di atas frame. Dulu (v17-v21) kamera di luar
	# pos memotret bangunan dari jalan — itu yang bikin menu terasa
	# seperti kartu ditempel di atas foto. Sapuan pelan di menu_camera.gd.
	var cam := Camera3D.new()
	cam.name = "MenuCamera"
	cam.set_script(load("res://scripts/menu_camera.gd"))
	cam.position = Balance.MENU_DESK_CAM_POS
	cam.rotation = Vector3(
		deg_to_rad(Balance.MENU_DESK_CAM_PITCH_DEG),
		deg_to_rad(Balance.MENU_DESK_CAM_YAW_DEG), 0.0)
	cam.fov = Balance.MENU_DESK_CAM_FOV
	add_child(cam)
	cam.current = true
	_setup_menu_window_giant()
	print("[Main] mode backdrop menu: kamera meja aktif")

## v22: Giant di balik JENDELA SELATAN, untuk kamera meja. HANYA di
## backdrop menu; tidak ada di permainan. Kamera meja di (-1.3, 2.1,
## 0.15) menghadap selatan: yang kelihatan lewat jendela (x -0,7..0,7,
## y 1,30..2,20) adalah tanah + kaki Giant di 8 m, bukan langit —
## garis pandang lewat jendela menukik ke tanah. Jadi yang masuk
## frame jendela adalah telapak + kaki bawahnya, persis citra event
## kaki 03:30 (telapak di band jendela). Aturan Giant tetap: tidak
## pernah utuh — dinding + kabut + pohon menelannya; yang kelihatan
## hanya sepotong kaki di jendela. Giant v21 di selatan pos (untuk
## kamera luar v17-v21) DIHAPUS: kamera itu sudah tidak ada.
## Kabut di kusen jendela: dua puff di luar jendela. Puff ketiga
## (di dalam, di ambang bawah) DIHAPUS v25: ia menutupi kaca dari
## dalam dan ikut menelan kaki Giant.
## v25 ronde 3: Giant diganti dari siluet gajah utuh
## (menu_giant_v21) ke KAKI RAKSASA (giant_foot, sprite yang sama
## dengan event kaki 03:30). Siluet utuh gagal tiga kali: kakinya
## tipis (beberapa piksel di tekstur 207 px) dan lewat kabut ia
## terbaca sebagai batang pohon, bukan kaki. Kaki close-up 3,5 m
## (120x218, kolom kaki + telapak di bawah) tidak ambigu: lewat
## jendela kelihatan telapak + kaki bawahnya, dan ukurannya yang
## tidak masuk akal (3,5 m untuk satu kaki) yang membuatnya Giant.
## Tint diangkat (1,2) supaya kerut kulitnya kebaca — tekstur
## aslinya sangat gelap, tanpa angkat ia jadi pilar hitam polos.
## v25 ronde 4: puff kabut di kusen DIHAPUS — masing-masing ~5 m
## lebar (pixel 0,02 x tekstur 256) dan tepat di garis pandang ke
## kaki, jadi mereka yang menutupi Giant, bukan kabut volumetrik.
## Kabut volumetrik + hutan sudah cukup untuk atmosfer jendela.
## Tint kaki diangkat lagi (1,6) supaya terpisah dari hutan gelap
## di belakangnya.
## v23 (Luci: create-game-assets — inspect dulu, iterasi di aset
## sumber, bukan kompensasi runtime): Giant di jendela DIGANTI dari
## giant_foot.png ke giant_foot_photo_v23.png, potongan FOTO ASLI
## kaki gajah di lumpur (Wetu, Tile K moodboard v2). giant_foot.png
## adalah kolom kaki gajah depan sheet Arya yang dipotong lurus:
## dicek di /tmp, zoom 3x ke separuh bawahnya — tidak ada telapak,
## tidak ada kuku, lebar seragam dari atas ke bawah. Di jendela ia
## memang batang pohon. Foto ini punya yang tidak dimiliki sprite
## itu: telapak melebar + DUA KUKU bulat di depan bawah + lumpur di
## telapak. v24: foto yang sama dipakai juga untuk event kaki 03:30
## di permainan (giant_event.gd) — follow-up v23 selesai,
## giant_foot.png kini tidak dipakai lagi.
## Penempatan sama (2,0, 0, 6,0; 4 m): telapak (seperempat bawah
## tekstur, y 0..1 m) masuk band jendela (garis pandang lewat
## ambang bawah jendela menyentuh tanah di y ~0,1 pada 6 m), kaki
## terpotong kusen atas — tidak pernah utuh. Tint 1,5 (foto sudah
## di-grade gelap 0,62 di tools/make_menu_foot_v23.py): kerut +
## kuku terangkat dari hutan gelap di belakangnya tanpa jadi pilar
## putih. Unshaded (aturan v14: siluet jauh shaded = hitam total).
func _setup_menu_window_giant() -> void:
	# v26 (aturan tidak-pernah-utuh DICABUT Arya 2026-11-18 15:50 WIB):
	# kepala Zunisha UTUH di jendela — kubah, telinga, belalai, dan
	# gading SEMUANYA masuk frame. Aset baru giant_head_zunisha_v26
	# (tools/make_menu_head_v26.py): grade dibalik dari v25, seluruh
	# kepala terbaca (kubah/wajah L~110, telinga ~85, belalai ~120,
	# gading ~145) bukan satu kolom terang; gading kanan yang di v25
	# salah letak 25 px kini di x 175-200.
	# GEOMETRI (diukur probe menu_window_probe.gd, bukan ditebak):
	# jendela lama (1,4 m, atas 2,20) membatasi pita pandang ke
	# y 0..2,4 m — kubah tidak akan pernah masuk. Jendela menu kini
	# 3,4 m lebar, atas 2,75 (guard_post.rebuild_back_wall_for_menu)
	# + pitch kamera -25 -> -18 (Balance): kepala 5,2 m (lebar
	# 6,7 m) di z 12,5, tengah x 2,0 — keempat sudutnya di dalam
	# viewport dengan margin, kubah di y layar ~+16 px. Kepala
	# mengisi jendela; tepi atas jendela sendiri di luar frame
	# atas (bukaan tinggi, kamera dekat) — yang kelihatan adalah
	# kusen kiri/kanan + ambang bawah, seperti mockup Arya yang
	# jendelanya memenuhi atas frame.
	# Papan "KAWASAN KUBURAN GAJAH" PINDAH ke x -3,5, z 9 (dulu
	# x 5,5: terpotong kusen kiri di v28; diukur probe: sudut
	# papan kini di dalam jendela, tidak menabrak kepala).
	# Menara pengawas + checkpoint tetap TIDAK dipasang di menu
	# (ramai; menara sudah ada di level permainan). Aset kelas
	# PLACEHOLDER (gambar Arya kelihatan AI-generated) — lihat
	# tools/ref/REFERENCES.md.
	# v28 (Luci: create-game-assets — SATU grade keluarga): kepala
	# v28 dari tools/grade_family_v28.py — grade DIBALIK dari v26
	# (pengali zona 1.1/1.1/1.3/1.35, bukan 2.2/2.2/2.7/2.55):
	# target akhir kubah ~48, telinga ~44, belalai ~52, gading ~68
	# (kabut L36, pohon L19 di v29 — kepala v26 L71-96 = ditempel).
	# Runtime tint 1.2-1.3 -> GRADE_FAR_TINT: PNG-lah grade-nya.
	# PNG 700x540 (upscale Lanczos 2x, haluskan tepi, bukan detail
	# baru — sumber tetap 350 px), jadi pixel_size 5.2/540.0.
	_billboard(self, "giant_head_zunisha_v28", Vector3(2.0, 0.0, 12.5), 5.2 / 540.0, Balance.GRADE_FAR_TINT, true)
	# v28: kabut di PANGKAL kepala — 3 puff DI DEPAN ujung belalai
	# (z 10.5-11, antara kamera dan kepala) supaya ujung belalai
	# larut ke kabut, bukan berakhir di udara di atas pita kabut
	# tanah yang tepinya keras (itu yang bikin kepala v26 melayang).
	# Puff eksplisit di sini (bukan _build_forest): koridor jendela
	# di sana memang dikosongkan supaya puff acak tidak menutupi
	# kepala; yang ini ditempatkan dengan sengaja di pangkalnya.
	for fp in [Vector3(0.5, 0.6, 10.5), Vector3(2.0, 0.8, 11.0),
			Vector3(3.5, 0.5, 10.5)]:
		var fc := Balance.GRADE_FOG_TINT
		fc.a = 0.38
		_billboard(self, "fog_puff", fp, 0.022, fc)
	# Kuburan gajah: PANEL DIHAPUS dari menu (ronde 8) — bukan
	# karena asetnya jelek (kerangka + gading terbaca jelas di
	# ronde 4-6), tapi karena kepala 20 m menutupi SELURUH lebar
	# jendela: panel di z 12 ditutupi kepala yang lebih dekat,
	# panel di z 18 tenggelam di belakang siluet kepala. Jendela
	# hanya 7 m lebar di z 12 — kepala dan panel tidak muat
	# berdua. Yang membawa "kuburan gajah" di menu adalah papan
	# "KAWASAN KUBURAN GAJAH" (z 9, terbaca jelas). Panel
	# menu_skeleton_v25 TETAP ada (aset + registry + generator)
	# untuk penempatan DALAM permainan nanti (pemain berjalan ke
	# kuburan) — jangan hapus filenya.
	# _billboard(self, "menu_skeleton_v25", Vector3(5.0, 0.0, 18.0), 6.0 / 390.0, Color(1.0, 1.0, 1.0, 0.95), true)
	# Papan "KAWASAN KUBURAN GAJAH" di x -3,5, z 9 (v26: pindah
	# dari x 5,5 yang terpotong kusen kiri di v28; diukur probe:
	# papan kini utuh di dalam jendela, di kanan kepala).
	# Menara pengawas + checkpoint TIDAK dipasang di menu (ramai;
	# menara sudah ada di level permainan, terlihat dari jendela
	# dalam game). Aset kelas PLACEHOLDER (gambar Arya kelihatan
	# AI-generated) — lihat tools/ref/REFERENCES.md.
	# v28: papan v28 (PNG di-grade x0.85 + feather) + GRADE_FAR_TINT.
	_billboard(self, "menu_sign_graveyard_v28", Vector3(-3.5, 0.0, 9.0), 2.0 / 200.0, Balance.GRADE_FAR_TINT, true)

## Kabut diterapkan dari Balance (satu tempat tune), bukan angka di .tscn.
## .tscn menyimpan default yang sama supaya scene tetap benar walau
## _ready tidak jalan (mis. dibuka di editor).
## Volumetric fog (Godot 4.3) hanya aktif di renderer Forward+; di
## Compatibility properti volumetric diabaikan dan game jatuh kembali
## ke fog eksponensial 0.06 + billboard, jadi Web/Android tidak berubah.
## Renderer aktif dibaca di sini supaya satu build tidak perlu cabang.
func _apply_fog() -> void:
	var env_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node == null or env_node.environment == null:
		push_error("[Main] WorldEnvironment tidak ketemu, fog tidak diterapkan")
		return
	var env := env_node.environment
	var volumetric := Balance.volumetric_active()
	env.fog_enabled = true
	env.fog_density = Balance.FOG_DENSITY_VOLUMETRIC if volumetric else Balance.FOG_DENSITY
	env.fog_light_color = Balance.FOG_LIGHT_COLOR
	env.fog_light_energy = Balance.FOG_LIGHT_ENERGY
	env.fog_sky_affect = Balance.FOG_SKY_AFFECT
	env.background_color = Color(0.045, 0.06, 0.05, 1) # langit = kabut gelap
	env.volumetric_fog_enabled = volumetric
	if volumetric:
		env.volumetric_fog_density = Balance.VOL_FOG_DENSITY
		env.volumetric_fog_albedo = Balance.VOL_FOG_ALBEDO
		env.volumetric_fog_emission = Balance.VOL_FOG_EMISSION
		env.volumetric_fog_emission_energy = Balance.VOL_FOG_EMISSION_ENERGY
		env.volumetric_fog_anisotropy = Balance.VOL_FOG_ANISOTROPY
		env.volumetric_fog_sky_affect = Balance.VOL_FOG_SKY_AFFECT
		env.volumetric_fog_length = Balance.VOL_FOG_LENGTH
	print("[Main] fog: volumetric=" + str(volumetric)
		+ " fog_density=" + str(env.fog_density)
		+ " vol_density=" + str(env.volumetric_fog_density if volumetric else 0.0))

func _process(delta: float) -> void:
	if GameState.shift_over:
		return
	GameState.advance_time(delta)
	if GameState.generator_on:
		GameState.drain_fuel(Balance.FUEL_DRAIN_PER_SECOND * delta)
		GameState.restore_stability(Balance.LIGHT_STABILITY_REGEN * delta)
	else:
		GameState.damage_stability(Balance.DARK_STABILITY_DRAIN * delta)
	_update_darkness_sanity(delta)
	_apply_night_curve(delta)

## v27 (kritik #6, Luci: level-design — cahaya sebagai mekanik):
## Sanity hidup sejak menit pertama, bukan baru saat event. Di luar
## pos dalam gelap (tanpa senter, di luar jangkauan lampu teras)
## Sanity turun pelan; di dalam pos dekat cahaya (lentera menyala
## atau generator menyala) ia pulih pelan. Di dalam pos yang gelap
## (lentera mati, generator mati) netral — pos adalah markas, bukan
## jebakan. Stability sudah hidup sejak awal lewat drain generator
## mati di _process (0.55/dtk), jadi kedua bar bergerak di 2 menit
## pertama. Batas pos dari LevelData: x -2.5..2.5, z -2..2 (+0.5
## toleransi ambang pintu).
func _update_darkness_sanity(delta: float) -> void:
	var player := get_node_or_null("Player") as Node3D
	if player == null:
		return
	var pos := player.global_position
	var outside := absf(pos.x) > LevelData.POST_WIDTH * 0.5 + 0.5 or pos.z < -LevelData.POST_DEPTH * 0.5 - 0.5 or pos.z > LevelData.POST_DEPTH * 0.5 + 0.5
	if not outside:
		var lantern := get_node_or_null("Lantern")
		var lit_inside := GameState.generator_on or (lantern != null and bool(lantern.get("is_on")))
		if lit_inside:
			GameState.restore_sanity(Balance.DARK_SANITY_REGEN * delta)
		return
	var flash_on := bool(player.get("flashlight_on"))
	var porch_lit := GameState.generator_on and pos.distance_to(LevelData.POST_PORCH_LIGHT_POS) < Balance.PORCH_LIGHT_PROTECT_RANGE
	if flash_on or porch_lit:
		return
	GameState.damage_sanity(Balance.DARK_SANITY_DRAIN * delta)

## v14 (tension pacing): malam makin dalam sampai ~02:00, bertahan
## gelap sampai ~04:00, lalu fajar mengintip dari 05:00. Bulan, ambient,
## dan fog volumetrik di-lerp pelan (konstanta ~2 detik) supaya tidak
## ada lompatan yang kelihatan; semua angka di Balance, semua kecil.
## v27: titik START/DEEP/DAWN kini konstanta Balance sendiri (dulu
## hardcode 0.75/0.65 di rumus) supaya kurva bisa di-tune tanpa baca
## rumus — dan nilainya digelapkan (lihat Balance).
func _apply_night_curve(delta: float) -> void:
	var env_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	var moon := get_node_or_null("MoonLight") as DirectionalLight3D
	if env_node == null or env_node.environment == null or moon == null:
		return
	var m := GameState.shift_minutes
	var dark := 0.0
	if m < Balance.NIGHT_DEEP_MINUTE:
		dark = m / Balance.NIGHT_DEEP_MINUTE
	elif m < Balance.NIGHT_HOLD_MINUTE:
		dark = 1.0
	elif m < Balance.NIGHT_DAWN_MINUTE:
		dark = 1.0 - (m - Balance.NIGHT_HOLD_MINUTE) / (Balance.NIGHT_DAWN_MINUTE - Balance.NIGHT_HOLD_MINUTE) * 0.5
	else:
		dark = 0.5 - (m - Balance.NIGHT_DAWN_MINUTE) / (Balance.SHIFT_LENGTH_MINUTES - Balance.NIGHT_DAWN_MINUTE) * 0.5
	var dawn := 0.0
	if m > Balance.NIGHT_DAWN_MINUTE:
		dawn = clampf((m - Balance.NIGHT_DAWN_MINUTE) / (Balance.SHIFT_LENGTH_MINUTES - Balance.NIGHT_DAWN_MINUTE), 0.0, 1.0)
	var env := env_node.environment
	var k := 1.0 - exp(-0.5 * delta)
	# Kurva tiga titik: START (22:00) -> DEEP (02:00-04:00) -> DAWN (06:00).
	# dark=0 di awal, 1 di titik tergelap, 0.5 di akhir; dawn=0 sampai
	# 05:00 lalu naik ke 1. Rumus lama (0.75 - 0.20*dark + 0.10*dawn)
	# setara dengan START 0.75 / DEEP 0.55 / DAWN 0.65 untuk bulan.
	var moon_target := lerpf(Balance.NIGHT_MOON_START, Balance.NIGHT_MOON_DEEP, dark) + (Balance.NIGHT_MOON_DAWN - Balance.NIGHT_MOON_DEEP) * dawn * 0.5
	var amb_target := lerpf(Balance.NIGHT_AMBIENT_START, Balance.NIGHT_AMBIENT_DEEP, dark) + (Balance.NIGHT_AMBIENT_DAWN - Balance.NIGHT_AMBIENT_DEEP) * dawn * 0.5
	moon.light_energy = lerpf(moon.light_energy, moon_target, k)
	env.ambient_light_energy = lerpf(env.ambient_light_energy, amb_target, k)
	if Balance.volumetric_active():
		env.volumetric_fog_density = lerpf(env.volumetric_fog_density,
			Balance.VOL_FOG_DENSITY + (Balance.NIGHT_VOL_DEEP - Balance.VOL_FOG_DENSITY) * dark
			+ (Balance.NIGHT_VOL_DAWN - Balance.VOL_FOG_DENSITY) * dawn, k)
	else:
		env.fog_density = lerpf(env.fog_density,
			Balance.FOG_DENSITY + 0.01 * dark - 0.005 * dawn, k)

## Posisi spawn + benda interaktif diambil dari LevelData, supaya
## main.tscn bukan satu-satunya sumber kebenaran. Dipanggil sebelum
## _build_terrain/_build_forest agar posisi final sejak frame pertama.
func _apply_level_positions() -> void:
	var player := get_node_or_null("Player")
	if player != null:
		player.global_position = LevelData.PLAYER_SPAWN
	_apply_node_pos("Generator", LevelData.GENERATOR_POS, deg_to_rad(LevelData.GENERATOR_ROT_Y_DEG))
	_apply_node_pos("Radio", LevelData.RADIO_POS, 0.0)
	_apply_node_pos("Logbook", LevelData.LOGBOOK_POS, 0.0)
	_apply_node_pos("Lantern", LevelData.LANTERN_POS, 0.0)
	_apply_node_pos("Newspaper", LevelData.NEWSPAPER_POS, 0.0) # v10: lurus (dulu 12 derajat), rapi + hitbox persis
	_apply_node_pos("Permit", LevelData.PERMIT_POS, 0.0) # v10: lurus (dulu -8 derajat)

func _apply_node_pos(node_name: String, pos: Vector3, rot_y: float) -> void:
	var n := get_node_or_null(node_name) as Node3D
	if n == null:
		push_error("[Main] node tidak ditemukan di main.tscn: " + node_name)
		return
	n.global_position = pos
	if rot_y != 0.0:
		n.rotation.y = rot_y

## Lanjutkan shift dari save: terapkan state GameState + posisi pemain.
## Event yang sedang berjalan tidak disimpan (lihat save_game.gd).
func _apply_resume() -> void:
	var d := GameState.resume_data
	if d.is_empty():
		return
	GameState.resume_data = {}
	GameState.shift_minutes = float(d.get("shift_minutes", 0.0))
	GameState.sanity = float(d.get("sanity", Balance.MAX_SANITY))
	GameState.stability = float(d.get("stability", Balance.MAX_STABILITY))
	GameState.fuel = float(d.get("fuel", Balance.MAX_FUEL))
	GameState.generator_on = bool(d.get("generator_on", false))
	GameState.door_open = bool(d.get("door_open", false))
	for id in d.get("tasks_done", []):
		GameState.complete_task(String(id))
	var player := get_node_or_null("Player") as Node3D
	if player != null:
		var p: Array = d.get("player_pos", [])
		if p.size() == 3:
			player.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		player.rotation.y = float(d.get("player_yaw", 0.0))
	var door := get_tree().get_first_node_in_group("door")
	if door != null and GameState.door_open and door.has_method("set_open_instant"):
		door.set_open_instant(true)
	GameState.show_message("Shift dilanjutkan. Jam %s." % GameState.clock_text())

# --- Terrain -------------------------------------------------------------

func _build_terrain() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(LevelData.GROUND_SIZE, LevelData.GROUND_SIZE)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	var gtex := load("res://assets/textures/ground.png") as Texture2D
	if gtex != null:
		mat.albedo_texture = gtex
		mat.uv1_scale = Vector3(12, 12, 1)
	mat.albedo_color = Color(0.85, 0.9, 0.85)
	mat.roughness = 1.0
	mesh.material_override = mat
	ground.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := WorldBoundaryShape3D.new()
	shape.shape = col
	ground.add_child(shape)
	# Jalan tanah kecil dari pagar ke pos.
	var path_mesh := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = LevelData.PATH_SIZE
	path_mesh.mesh = pb
	path_mesh.position = LevelData.PATH_POS
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.11, 0.09, 0.06)
	path_mesh.material_override = pm
	add_child(path_mesh)
	_build_fence_and_signs()

func _build_fence_and_signs() -> void:
	var fence := Node3D.new()
	fence.name = "Fence"
	add_child(fence)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.12, 0.08)
	# Pagar kayu di depan, celah gerbang di tengah, z = FENCE_Z.
	for x in range(-LevelData.FENCE_HALF_WIDTH, LevelData.FENCE_HALF_WIDTH + 1):
		if abs(x) < LevelData.FENCE_GATE_HALF_GAP or x % 2 != 0:
			continue
		var post := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.16, 1.25, 0.16)
		post.mesh = b
		post.position = Vector3(float(x), 0.62, LevelData.FENCE_Z)
		post.material_override = mat
		fence.add_child(post)
	for y in [0.45, 0.95]:
		for side in [-1.0, 1.0]:
			var rail := MeshInstance3D.new()
			var rb := BoxMesh.new()
			rb.size = Vector3(14.5, 0.09, 0.06)
			rail.mesh = rb
			rail.position = Vector3(side * 8.75, y, LevelData.FENCE_Z)
			rail.material_override = mat
			fence.add_child(rail)
	_make_sign(fence, LevelData.SIGN_PARK_POS, "sign_park", Color(0.35, 0.3, 0.22))
	_make_sign(fence, LevelData.SIGN_NO_LOGGING_POS, "sign_no_logging", Color(0.3, 0.26, 0.2))
	# Papan larangan gajah di tiang sendiri, dekat gerbang.
	_make_sign(fence, LevelData.SIGN_NO_ELEPHANT_POS, "sign_no_elephant2", Color(0.3, 0.26, 0.2))

func _make_sign(parent: Node, pos: Vector3, sprite_name: String, color: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	# v11: tiang + papan pakai material kayu yang sama. Dulu tiang
	# tanpa material (putih default) dan kelihatan seperti tiang lampu
	# di kabut — itu dua garis putih di shot v15c_gate_signs.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	var pole := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.12, 1.5, 0.12)
	pole.mesh = pb
	pole.position.y = 0.75
	pole.material_override = mat
	root.add_child(pole)
	var board := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.7, 0.5, 0.06)
	board.mesh = bb
	board.position.y = 1.55
	board.material_override = mat
	root.add_child(board)
	if sprite_name != "":
		var spr := SpriteRegistry.billboard(sprite_name, 0.004)
		if spr != null:
			# v14: wajah papan unshaded + tint redup supaya
			# tulisannya kebaca samar di gelap tanpa senter — dengan
			# senter tetap terbaca seperti dulu (shots16 sign_park).
			# v28: tint literal -> GRADE_SIGN_TINT (satu keluarga).
			spr.shaded = false
			spr.modulate = Balance.GRADE_SIGN_TINT
			spr.position = Vector3(0, 1.55, 0.05)
			root.add_child(spr)

# --- Hutan ---------------------------------------------------------------

func _build_forest() -> void:
	var forest := Node3D.new()
	forest.name = "Forest"
	add_child(forest)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.07, 0.055, 0.04)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.03, 0.07, 0.035)
	# Cincin pohon rapat mengelilingi area pos: hutan sebagai dinding kabut.
	for i in range(LevelData.FOREST_RING_COUNT):
		var angle := TAU * float(i) / float(LevelData.FOREST_RING_COUNT) + _rng.randf_range(-0.04, 0.04)
		var radius := _rng.randf_range(LevelData.FOREST_RING_RADIUS_MIN, LevelData.FOREST_RING_RADIUS_MAX)
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		_make_tree(forest, pos, trunk_mat, leaf_mat)
	# Beberapa pohon lepas lebih dekat, tetap di luar pagar.
	for i in range(LevelData.FOREST_NEAR_COUNT):
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(LevelData.FOREST_NEAR_RADIUS_MIN, LevelData.FOREST_NEAR_RADIUS_MAX)
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		if absf(pos.x) < 4.0 and pos.z < 0.0:
			continue # jangan halangi jalan ke gerbang
		# v26: koridor pandang jendela selatan DILEBARKAN ke
		# (x -7..15, z 2..20) — jendela menu kini 3,4 m lebar,
		# garis pandang di z 12 mencapai x -6,4..14,9; koridor
		# v25 (x -1..8) terlalu sempit, pohon di tepinya bisa
		# menutupi telinga/gading kepala Zunisha. — satu pohon dekat (seed tetap) berdiri
		# tepat di depan belalai Zunisha (ronde 4: kolom gelap
		# pohon menutupi belalai, hanya gading yang mengintip).
		if pos.z > 2.0 and pos.z < 20.0 and pos.x > -7.0 and pos.x < 15.0:
			continue
		_make_tree(forest, pos, trunk_mat, leaf_mat)
	# Properti berserakan + decal tanah, semua dari tabel LevelData.
	for entry in LevelData.SCATTER_PROPS:
		_scatter_prop(forest, String(entry[0]), entry[1], float(entry[2]))
	for entry in LevelData.GROUND_DECALS:
		_ground_decal(forest, String(entry[0]), entry[1], float(entry[2]))
	# Billboard statis dari tabel LevelData.
	for entry in LevelData.BILLBOARDS:
		_billboard(forest, String(entry[0]), entry[1], float(entry[2]), entry[3],
			String(entry[0]) in UNSHADED_BILLBOARDS)
	# Gumpalan kabut di antara pohon (36x, abu kehijauan sakit, bukan putih).
	# Koridor jalan gerbang->pos (|x|<3.5, z -16..2) dikosongkan supaya
	# tidak ada gumpalan yang menempel di depan kamera dan menelan pos.
	# v14 (depth cueing): alpha gumpalan DIGRADING menurut jarak —
	# dekat lebih padat (0.38), jauh lebih tipis (0.26) — supaya kabut
	# punya lapisan, bukan satu veil datar. Dulu semua 0.34 sama rata;
	# lewat jendela belakang itu yang bikin kabut kelihatan dinding
	# polos tanpa depth cue (catatan jujur v8).
	for i in range(Balance.FOG_PUFF_COUNT):
		var a := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(9.0, 26.0)
		var fp := Vector3(cos(a) * r, 0, sin(a) * r)
		if absf(fp.x) < 3.5 and fp.z > -16.0 and fp.z < 2.0:
			continue
		# v26: koridor pandang jendela selatan DILEBARKAN ke
		# (x -7..15, z 2..20) — jendela menu kini 3,4 m lebar,
		# garis pandang di z 12 mencapai x -6,4..14,9; koridor
		# v25 (x -1..8) terlalu sempit, pohon di tepinya bisa
		# menutupi telinga/gading kepala Zunisha. — puff di sini menutupi kepala Zunisha
		# + panel kuburan di menu (ronde 1-2: puff tetap di
		# (1,5, 12) tepat di depan belalai). Koridor gerbang utara
		# di atas sudah ada sejak lama dengan alasan sama.
		if fp.z > 2.0 and fp.z < 20.0 and fp.x > -7.0 and fp.x < 15.0:
			continue
		var depth_k := clampf((r - 9.0) / (26.0 - 9.0), 0.0, 1.0)
		var puff_alpha := lerpf(0.38, 0.26, depth_k)
		# v28: tint literal -> GRADE_FOG_TINT (satu keluarga).
		var fc := Balance.GRADE_FOG_TINT
		fc.a = puff_alpha
		_billboard(forest, "fog_puff", Vector3(fp.x, _rng.randf_range(0.4, 1.4), fp.z), _rng.randf_range(0.015, 0.024), fc)
	# Gumpalan tetap di mid-ground (10-12 m), supaya selalu ada
	# struktur kabut yang kebaca dari pos dan gerbang. Ronde 1 pakai
	# tint GELAP untuk yang selatan — lewat jendela cuma jadi noda
	# samar di kabut (diukur: std jendela 14,1 vs 15,9 baseline) dan
	# di luar berisiko kelihatan gumpalan hitam; dikembalikan pucat
	# seperti gumpalan lain. Jendela belakang tetap dinding kabut:
	# pada 0,07/m, billboard apa pun di 10-14 m cuma ~40% kebaca
	# dengan latar kabut sewarna + desaturasi VHS. Batas jujur v14.
	# v25: gumpalan (1,5, 0,6, 12,0) DIHAPUS — ia tepat di depan
	# belalai Zunisha (kepala menu di x 1,0, z 12) dan menutupi
	# kepala di ronde 1-2. Yang selatan tinggal dua di luar
	# koridor jendela.
	for fp in [Vector3(-5.0, 0.8, 11.0), Vector3(6.0, 0.9, 10.0),
			Vector3(-7.0, 0.8, -11.0), Vector3(8.0, 1.0, -12.0)]:
		# v28: tint literal -> GRADE_FOG_TINT (satu keluarga).
		var fc2 := Balance.GRADE_FOG_TINT
		fc2.a = 0.34
		_billboard(forest, "fog_puff", fp, 0.022, fc2)
	# Ground fog: lapisan kabut rendah merayap di permukaan tanah,
	# rapat di sekitar pos + jalan + gerbang, supaya tanah tidak bersih.
	for i in range(Balance.GROUND_FOG_COUNT):
		var ga := _rng.randf_range(0.0, TAU)
		var gr := _rng.randf_range(6.0, 13.0)
		var gp := Vector3(cos(ga) * gr, 0, sin(ga) * gr)
		if absf(gp.x) < 3.5 and gp.z > -16.0 and gp.z < 2.0:
			continue
		# v26: koridor pandang jendela selatan DILEBARKAN ke
		# (x -7..15, z 2..20) (alasan sama seperti puff di atas).
		if gp.z > 2.0 and gp.z < 20.0 and gp.x > -7.0 and gp.x < 15.0:
			continue
		var gdepth_k := clampf((gr - 6.0) / (13.0 - 6.0), 0.0, 1.0)
		var ground_alpha := lerpf(0.42, 0.32, gdepth_k)
		# v28: tint literal -> GRADE_FOG_TINT (satu keluarga).
		var gc := Balance.GRADE_FOG_TINT
		gc.a = ground_alpha
		_billboard(forest, "fog_puff", Vector3(gp.x, _rng.randf_range(0.15, 0.45), gp.z), _rng.randf_range(0.018, 0.026), gc)
	# v28 (grade keluarga — elemen MENEMPEL ke dunia): kabut tanah
	# DETERMINISTIK di kaki elemen besar. Yang acak di atas (seeded)
	# sering tidak jatuh di tempat yang penting — di shot
	# v30_path_dark tanah di sekitar generator hitam polos, generator
	# + chainsaw + barel melayang di atasnya. Puff ini selalu ada di
	# kaki generator, papan tanda, gerbang, dan jalan. Area selatan
	# (koridor jendela menu) TIDAK disentuh — kabut pangkal kepala
	# sudah dipasang eksplisit di _setup_menu_window_giant.
	for fp in [Vector3(3.6, 0.3, -1.2), Vector3(4.4, 0.3, -2.5),
			Vector3(0.0, 0.3, -15.7), Vector3(1.0, 0.35, -9.0),
			Vector3(-1.0, 0.35, -12.0)]:
		var dc := Balance.GRADE_FOG_TINT
		dc.a = 0.4
		_billboard(forest, "fog_puff", fp, 0.02, dc)
	# Bayangan kontak di bawah generator + papan + gerbang: elips
	# gelap datar (contact_shadow.png) supaya benda tidak melayang
	# saat tanah diterangi (senter / lampu teras). Di gelap total
	# ia tidak kelihatan — dan memang tidak ada yang kelihatan di
	# gelap total; kabut tanah di atas yang bekerja di sana.
	_contact_shadow(forest, Vector3(3.9, 0.06, -1.8), Vector2(2.2, 1.4))
	_contact_shadow(forest, Vector3(0.0, 0.06, -15.7), Vector2(3.0, 1.2))
	for sp in [LevelData.SIGN_PARK_POS, LevelData.SIGN_NO_LOGGING_POS,
			LevelData.SIGN_NO_ELEPHANT_POS]:
		_contact_shadow(forest, Vector3(sp.x, 0.06, sp.z), Vector2(1.2, 0.8))

## v14 (polish #6): sosok jauh yang harus kebaca sebagai siluet di
## kabut (gerbang, pemburu, gajah) dibuat UNSHADED — shaded membuat
## mereka hitam total di gelap karena membelakangi bulan. Preseden:
## mata Giant sudah unshaded + HDR sejak v9 dengan alasan sama.
## Fog tetap berlaku pada sprite unshaded, jadi mereka tetap tertelan
## kabut di jarak jauh, hanya tidak lagi hilang total di 15 m.
const UNSHADED_BILLBOARDS: Array[String] = [
	"gate", "poacher_mask", "poacher_ghost",
	"elephant_front", "elephant_shadow", "elephant_side",
	# v16: gajah belakang + menara radio jauh juga unshaded supaya
	# kebaca sebagai siluet di kabut (lampu merah menara tetap nyala).
	"elephant_back", "radio_tower",
	# v16 ronde 2: ranger kedua juga unshaded — versi shaded-nya
	# hilang total menempel dinding pondok yang gelap (shot v20
	# guard_back ronde 1). Guard_front tetap shaded: latarnya kabut,
	# bukan dinding gelap, jadi ia kebaca.
	"guard_back",
]

# Billboard statis dari sprite sheet: posisi y = 0 (alas di tanah),
# sprite diangkat setengah tinggi gambarnya supaya alasnya menapak.
func _billboard(parent: Node, sprite_name: String, pos: Vector3, pixel_size: float, tint: Color, unshaded := false) -> void:
	var tex := SpriteRegistry.texture(sprite_name)
	if tex == null:
		return
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.pixel_size = pixel_size
	spr.modulate = tint
	spr.shaded = not unshaded
	spr.position = pos + Vector3(0, tex.get_height() * pixel_size * 0.5, 0)
	parent.add_child(spr)

# Bayangan kontak (v28): elips gelap datar di bawah benda besar
# supaya alasnya menapak di tanah saat tanah diterangi. Sprite
# flat (bukan billboard), unshaded, alpha dari tekstur radial.
func _contact_shadow(parent: Node, pos: Vector3, size_m: Vector2) -> void:
	var tex := SpriteRegistry.texture("contact_shadow")
	if tex == null:
		return
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.pixel_size = size_m.x / float(tex.get_width())
	spr.rotation = Vector3(-PI * 0.5, 0, 0)
	spr.position = pos
	spr.modulate = Color(1, 1, 1, 0.9)
	parent.add_child(spr)

func _make_tree(parent: Node, pos: Vector3, _trunk_mat: Material, _leaf_mat: Material) -> void:
	# Pohon BUKAN bola di atas silinder lagi: sprite pohon dari sheet
	# (tinggi, palem, atau mati), dipilih bergiliran supaya hutan tidak seragam.
	var kinds := ["tree_tall", "tree_tall", "tree_palm", "tree_dead", "tree_big"]
	var kind: String = kinds[int(absf(pos.x * 7.0 + pos.z * 3.0)) % kinds.size()]
	var tex := SpriteRegistry.texture(kind)
	if tex == null:
		return
	var h := _rng.randf_range(5.0, 8.0)
	var pixel_size := h / float(tex.get_height())
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.pixel_size = pixel_size
	# v28: tint literal -> GRADE_TREE_TINT (satu keluarga).
	spr.modulate = Balance.GRADE_TREE_TINT
	spr.position = pos + Vector3(0, h * 0.5, 0)
	parent.add_child(spr)
	var body := StaticBody3D.new()
	# DULU BUG: body.position.y saja yang diisi, x/z tetap 0 — SEMUA
	# ~104 silinder tabrakan pohon menumpuk di origin (0,0,0), jadi ada
	# dinding tak terlihat di tengah pos jaga dan pemain tidak bisa
	# jalan lurus ke pintu. Ketemu lewat test rig mode=touch (tabrakan
	# dengan StaticBody parent Forest di (0, 2.77, 0)).
	body.position = pos + Vector3(0, h * 0.5, 0)
	var shape := CollisionShape3D.new()
	var col := CylinderShape3D.new()
	col.radius = 0.3
	col.height = h
	shape.shape = col
	body.add_child(shape)
	parent.add_child(body)

func _scatter_prop(parent: Node, sprite_name: String, pos: Vector3, pixel_size: float) -> void:
	# v28: tint literal -> GRADE_PROP_TINT (satu keluarga).
	var spr := SpriteRegistry.billboard(sprite_name, pixel_size, Balance.GRADE_PROP_TINT)
	if spr == null:
		return
	spr.position = pos
	parent.add_child(spr)

# Decal di tanah (mis. darah): sprite dibaringkan datar, bukan billboard
# tegak, supaya menempel di tanah dan tidak melayang.
func _ground_decal(parent: Node, sprite_name: String, pos: Vector3, pixel_size: float) -> void:
	var tex := SpriteRegistry.texture(sprite_name)
	if tex == null:
		return
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.pixel_size = pixel_size
	spr.rotation = Vector3(-PI * 0.5, 0, 0)
	spr.position = pos
	# v11: darah didongkrak merah supaya kebaca di tanah gelap;
	# decal lain (jejak, jerat) netral, jangan ikut merah.
	# v28: non-darah -> GRADE_PROP_TINT (satu keluarga); darah
	# tetap aksen merah (satu-satunya yang boleh keluar keluarga).
	spr.modulate = Color(1.6, 1.0, 1.0, 1.0) if sprite_name == "blood" else Balance.GRADE_PROP_TINT
	parent.add_child(spr)
