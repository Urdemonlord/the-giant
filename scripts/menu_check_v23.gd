extends Node
## Verifikasi cepat menu v23 (list Luci) — TANPA pan 6,5 dtk rig penuh.
## Dipakai saat CPU sempit (llvmpipe + kerja lain): buka menu, tunggu
## 12 frame, cek 4 perbaikan v23 + screenshot, keluar. Rig penuh
## (menu_shot.gd) tetap sumber PASS/FAIL lengkap; skrip ini hanya
## jalan pintas bukti visual + cek API yang sama.
## Jalankan: Xvfb :98, --resolution 1280x720 (desktop, prefix v26)
## atau 720x1280 (portrait, prefix v26p), scene menu_quick.tscn.
## Argumen `-- menu_with_save=1` membuat save dummy SEBELUM menu
## dibangun (Continue hidup, tanpa coret); tanpa argumen, Continue
## mati (dengan coret, tetap terbaca).
const SHOT_DIR := "/home/hatch/workspace/godot/shots"
const RES_PATH := "res://scenes/menu.tscn"

var _prefix := "v26"
var _passes := 0
var _fails := 0
var _menu: Control
var _frames := 0
var _with_save := false
var _done := false

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	for a in OS.get_cmdline_user_args():
		if str(a) == "menu_with_save=1":
			_with_save = true
	if get_tree().root.size.y > get_tree().root.size.x:
		_prefix = "v26p"
	if _with_save:
		GameState.shift_minutes = 123.0
		GameState.sanity = 80.0
		GameState.stability = 65.0
		GameState.fuel = 40.0
		GameState.generator_on = true
		SaveGame.save()
	else:
		SaveGame.clear()
	_menu = (load(RES_PATH) as PackedScene).instantiate()
	add_child(_menu)

func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 12 or _done:
		return
	_done = true
	var img := get_viewport().get_texture().get_image()
	_check_all(img)
	var tag := "menu_with_save" if _with_save else "menu_no_save"
	img.save_png(SHOT_DIR + "/" + _prefix + "_" + tag + ".png")
	print("[QUICK] " + str(_passes) + " pass, " + str(_fails) + " fail")
	if not _with_save:
		SaveGame.clear()
	get_tree().quit(0 if _fails == 0 else 1)

func _pass(msg: String) -> void:
	_passes += 1
	print("[QUICK] PASS " + msg)

func _fail(msg: String) -> void:
	_fails += 1
	print("[QUICK] FAIL " + msg)

func _cam() -> Camera3D:
	return _menu.get_node_or_null("Backdrop/MenuCamera") as Camera3D

func _check_all(img: Image) -> void:
	# 1. Baris menu ada.
	var names: Array[String] = _menu.row_names()
	if names == ["Start", "Continue", "Options", "Exit"]:
		_pass("baris menu: Start, Continue, Options, Exit")
	else:
		_fail("baris menu: " + str(names))
	# 2. Continue: mati TANPA save (terbaca + coret), hidup DENGAN save.
	var cont_enabled: bool = _menu.row_enabled("Continue")
	var sub: String = _menu.row_sub("Continue")
	var strike_visible := false
	var label_mod := Color.BLACK
	for row in _menu._rows:
		if str(row["name"]) == "Continue":
			var st := row.get("strike") as MeshInstance3D
			strike_visible = st != null and st.visible
			label_mod = (row["label"] as Label3D).modulate
	if _with_save:
		if cont_enabled and sub != "" and sub != "no record on file" and not strike_visible:
			_pass("Continue hidup dengan save, sub '" + sub + "', tanpa coret")
		else:
			_fail("Continue dengan save: enabled=" + str(cont_enabled) + " sub='" + sub + "' coret=" + str(strike_visible))
	else:
		if not cont_enabled and sub == "no record on file" and strike_visible:
			_pass("Continue mati tanpa save, TAPI terbaca + dicoret")
		else:
			_fail("Continue tanpa save: enabled=" + str(cont_enabled) + " sub='" + sub + "' coret=" + str(strike_visible))
		# Tinta mati harus INK_DISABLED (0,22), bukan INK_DIM 0,38 yang hilang.
		if label_mod.r < 0.26 and label_mod.r > 0.18:
			_pass("tinta Continue mati 0,22 (terbaca, bukan 0,38)")
		else:
			_fail("tinta Continue mati: " + str(label_mod))
	# 3. Tanpa CCTV.
	if not _menu.has_cctv():
		_pass("tidak ada REC/CAM di menu")
	else:
		_fail("masih ada REC/CAM di menu")
	# 4. CA mati (v23): konstanta + parameter shader.
	if absf(float(Balance.MENU_GRADE_CA)) < 0.0001:
		_pass("MENU_GRADE_CA = 0")
	else:
		_fail("MENU_GRADE_CA = " + str(Balance.MENU_GRADE_CA))
	var ca := float(_menu._fx_mat.get_shader_parameter("ca"))
	if absf(ca) < 0.0001:
		_pass("parameter shader ca = 0 (teks tajam)")
	else:
		_fail("parameter shader ca = " + str(ca))
	# 5. Kaki Giant FOTO di jendela (bukan giant_foot kolom).
	var foot := _find_sprite(_menu.get_node_or_null("Backdrop"), "giant_foot_photo_v23")
	if foot == null:
		_fail("sprite giant_foot_photo_v23 tidak ada di backdrop")
	else:
		var cam := _cam()
		var sp := cam.unproject_position((foot as Sprite3D).position)
		var vp := get_viewport().get_visible_rect()
		if vp.has_point(sp):
			_pass("kaki foto di jendela, posisi layar " + str(sp))
		else:
			_fail("kaki foto di luar viewport: " + str(sp))
	# 6. Lentera tidak menutupi judul: alas lentera (z 1,54) harus
	# terproyeksi DI ATAS tepi jauh logo (z 1,48) — di layar, y
	# lebih kecil = lebih tinggi. Logo juga harus utuh di viewport.
	var cam2 := _cam()
	var lantern := _menu.get_node_or_null("Backdrop/Lantern") as Node3D
	if lantern == null or cam2 == null:
		_fail("kamera/lentera menu tidak ada")
	else:
		var base := Vector3(lantern.position.x, 1.11, lantern.position.z - 0.18)
		var base_sp := cam2.unproject_position(base)
		var logo_far := cam2.unproject_position(Vector3(-0.81, 1.133, 1.482))
		if base_sp.y < logo_far.y - 3.0:
			_pass("alas lentera di atas judul (jarak layar %.0f px)" % (logo_far.y - base_sp.y))
		else:
			_fail("alas lentera masih menutupi judul: alas y=%.0f logo y=%.0f" % [base_sp.y, logo_far.y])
		var vp2 := get_viewport().get_visible_rect()
		var corners: Array[Vector2] = []
		for cx in [-1.24, -0.38]:
			for cz in [1.258, 1.482]:
				corners.append(cam2.unproject_position(Vector3(cx, 1.133, cz)))
		var all_in := true
		for c in corners:
			if not vp2.has_point(c):
				all_in = false
		if all_in:
			_pass("logo THE GIANT utuh di viewport")
		else:
			_fail("logo terpotong viewport: " + str(corners))
	# 7. Teks baris terpilih ("Start") gelap di atas bar sorot kuning.
	# v22: di portrait bar sorot sempat menutupi teks (sort transparan
	# terbalik) -> "Start" pucat. Cek piksel: di sekitar tengah label
	# Start harus ada piksel tinta gelap (luminansi < 0,45).
	var cam3 := _cam()
	var start_pos := Vector3.ZERO
	var found_start := false
	for row in _menu._rows:
		if str(row["name"]) == "Start":
			start_pos = (row["label"] as Label3D).position
			found_start = true
	if not found_start or cam3 == null:
		_fail("baris Start tidak ditemukan untuk cek piksel")
	else:
		var sp := cam3.unproject_position(start_pos)
		# unproject mengembalikan koordinat LOGIS (1280x720); gambar
		# adalah konten yang sama diskala ke ukuran viewport
		# (portrait 720x405). Skala dulu, kalau tidak semua sampel
		# jatuh di luar gambar dan darkest tetap 1,00.
		var vp_size := get_viewport().get_visible_rect().size
		var ip := Vector2(sp.x * img.get_width() / vp_size.x, sp.y * img.get_height() / vp_size.y)
		print("[QUICK] debug Start sp=" + str(sp) + " vp=" + str(vp_size) + " img=" + str(Vector2i(img.get_width(), img.get_height())) + " ip=" + str(ip))
		var darkest := 1.0
		for dx in range(-48, 49, 4):
			for dy in range(-20, 21, 3):
				var p := Vector2i(int(ip.x) + dx, int(ip.y) + dy)
				if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
					continue
				var c := img.get_pixel(p.x, p.y)
				var lum := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				if lum < darkest:
					darkest = lum
		if darkest < 0.45:
			_pass("teks Start gelap di atas bar sorot (lum tergelap %.2f)" % darkest)
		else:
			_fail("teks Start pucat di atas bar sorot (lum tergelap %.2f)" % darkest)

func _find_sprite(root: Node, needle: String) -> Sprite3D:
	if root == null:
		return null
	for n in root.get_children():
		if n is Sprite3D:
			var t := (n as Sprite3D).texture
			if t != null and needle in t.resource_path:
				return n as Sprite3D
		var found := _find_sprite(n, needle)
		if found != null:
			return found
	return null
