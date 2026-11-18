extends Node
## Rig khusus menu utama: masuk scene menu, screenshot, cek judul,
## tombol, pengaturan, save/continue, dan exit. Dipakai di CI dengan
## --headless + timeout.
##
## v25 (menu v22, Opsi B): menu sekarang buku jaga 3D di atas meja
## (bukan panel Control + tombol). Rig ditulis ulang ke API baru:
## - baris menu = Label3D di halaman (row_names, screen_pos_for_row)
## - klik = InputEventMouseButton sungguhan di posisi baris (bukan
##   emit pressed) — membuktikan raycast _ray_to_book jalan
## - CCTV harus TIDAK ada: has_cctv() false + grade scanline/tear 0
## - kamera menu DI DALAM pos menghadap selatan (bukan dari jalan)
## - Giant + kabut di luar jendela selatan harus ada
## - formulir Options tetap Control (slider/toggle di-skin) — diuji
##   lewat klik sungguhan pada tombol Kembali (formulir di-scroll
##   dulu ke bawah supaya tombolnya kelihatan)
##
## CATATAN: scene ini jalan headless tanpa DISPLAY — Godot tetap
## render ke viewport dan menyimpan PNG dengan benar (viewport di
## headless tidak hitam). Verifikasi yang sama di Xvfb tidak
## diperlukan, karena rig ini tidak menguji interaksi pointer-lock
## dan tidak menggerakkan player.
##
## CATATAN 2: viewport 1280x720 dengan stretch mode canvas_items
## aspect KEEP — di jendela yang lebarnya tidak pas, tampilannya
## letterbox hitam di atas/bawah.
## CATATAN 3: Godot mengembalikan frame pertama yang dirender
## (garis besar kasar) saat `_ready` selesai; ambil screenshot
## beberapa frame kemudian supaya hasilnya stabil.

## v32: prefix "v32" untuk desktop, "v32p" untuk portrait — supaya
## screenshot portrait tidak menimpa desktop (keduanya jalan di
## rig yang sama, beda --resolution).
var _prefix := "v32"
const SHOT_DIR := "/home/hatch/workspace/godot/shots"
const RES_PATH := "res://scenes/menu.tscn"

var _log: FileAccess
var _menu: Control
var _passes := 0
var _fails := 0
var _phase := "init"
var _frames := 0
var _awaiting := false
var _await_start_frame := 0
var _await_frames := 0
var _await_action := ""
var _back_checked := false

func _ready() -> void:
	var vp := get_viewport()
	vp.transparent_bg = false
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	# test_menu.tscn SUDAH menginstansiasi Menu sebagai anak — rig
	# TIDAK membuat menu kedua (dulu: add_child kedua, dua Backdrop
	# + dua kamera berebut current).
	_menu = get_node("Menu") as Control
	# v25p: deteksi portrait dari UKURAN JENDELA (root.size, piksel
	# fisik), BUKAN get_visible_rect() — yang itu mengembalikan
	# ukuran base stretch (1280x720) di kedua orientasi, jadi run
	# portrait pertama menimpa file desktop.
	if get_tree().root.size.y > get_tree().root.size.x:
		_prefix = "v32p"
	_log = FileAccess.open(SHOT_DIR + "/" + _prefix + "_results_menu.txt", FileAccess.WRITE)
	_log.store_line("[MENU-RIG] " + _prefix + " menu v29 (Luci list)")
	_log.store_line("mode: menu")
	_log.store_line("time: " + Time.get_datetime_string_from_system())
	_log.store_line("start")
	_log.store_line("scene: " + RES_PATH)
	_log.store_line("window: " + str(get_tree().root.size))
	var has_save := SaveGame.has_save()
	_log.store_line("save_exists_at_start: " + ("YES" if has_save else "NO"))
	_log.flush()
	if has_save:
		_log.store_line("save_summary_at_start: " + SaveGame.summary_text())
		SaveGame.clear()
		_log.store_line("save_cleared_for_menu_test: YES")
		_log.flush()
		# v25: menu sudah dibangun SEBELUM _ready rig (anak _ready
		# dulu), jadi Continue masih membawa info save lama — segarkan
		# barisnya setelah save dihapus.
		_menu._refresh_continue()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit(0)

func _process(_delta: float) -> void:
	_frames += 1
	if _awaiting:
		if _frames - _await_start_frame >= _await_frames:
			_awaiting = false
			_run_awaited(_await_action)
		return
	if _frames < 5:
		return
	match _phase:
		"init":
			_phase = "menu_no_save"
			_check_viewport()
			_test_menu_camera()
			_test_book_pages()
			_test_book_rows()
			_test_menu_no_save()
			_test_giant_window()
			_test_menu_options_grain()
			_shot("menu_no_save")
			_log.store_line("menu_no_save_checked")
			_phase = "pan"
			_wait(6.5, "pan_shot")
		"pan":
			_phase = "click_options"
			_test_menu_click_options()
			_wait(0.3, "options_shot")
		"click_options":
			_phase = "settings"
			_shot("menu_options")
			_test_settings()
			# Formulir lebih panjang dari layar: tombol Kembali ada
			# di bawah lipatan. Scroll dulu ke bawah supaya global
			# rect-nya valid saat klik nanti (butuh beberapa frame
			# untuk layout, jadi scroll di sini, klik di fase lain).
			_menu._options_scroll.scroll_vertical = 100000
			_wait(0.3, "back_clicks")
		"settings":
			# Tunggu hasil cek Kembali dulu (dicek di _run_awaited
			# "back_check") sebelum membuat save + reload.
			if not _back_checked:
				return
			_phase = "save"
			_test_save()
			_wait(0.3, "reload_menu")
		"save":
			_phase = "menu_with_save"
			_test_menu_with_save()
			_test_menu_exit()
			_shot("menu_with_save")
			_finish()

func _wait(seconds: float, action: String) -> void:
	_awaiting = true
	_await_start_frame = _frames
	_await_frames = int(ceil(seconds / (1.0 / 60.0)))
	_await_action = action

func _run_awaited(action: String) -> void:
	match action:
		"pan_shot":
			_shot("menu_no_save_pan")
			_log.store_line("menu_pan_shot_saved")
		"options_shot":
			_log.store_line("options_opened_by_real_click")
		"back_clicks":
			_test_back_to_main_clicks()
			_wait(0.3, "back_check")
		"back_check":
			_test_back_to_main_check()
			_back_checked = true
		"reload_menu":
			_reload_menu_with_save()

func _check_viewport() -> void:
	# Ukuran jendela fisik (root.size), bukan get_visible_rect()
	# yang mengembalikan base stretch 1280x720 di semua orientasi.
	var actual := get_tree().root.size
	# Desktop 1280x720 atau portrait HP 720x1280 (letterbox:
	# konten 1280x720 diskalakan ke 720x405 di tengah layar).
	if actual == Vector2i(1280, 720) or actual == Vector2i(720, 1280):
		_pass("viewport " + str(actual))
	else:
		_fail("viewport: " + str(actual) + " (bukan 1280x720 atau 720x1280)")

func _menu_camera() -> Camera3D:
	return _menu.get_node_or_null("Backdrop/MenuCamera") as Camera3D

func _test_menu_camera() -> void:
	var cam := _menu_camera()
	if cam == null:
		_fail("menu camera tidak ada")
		return
	# v22: kamera DI DALAM pos, di utara meja menghadap selatan
	# (yaw 180), bukan lagi dari jalan depan-kiri (v17-v21).
	if cam.position.distance_to(Balance.MENU_DESK_CAM_POS) < 0.05:
		_pass("menu camera pos di dalam pos: " + str(cam.position))
	else:
		_fail("menu camera pos " + str(cam.position) + " (bukan " + str(Balance.MENU_DESK_CAM_POS) + ")")
	if cam.position.z > -2.0 and cam.position.z < 2.0:
		_pass("menu camera di dalam pos (z di dalam dinding)")
	else:
		_fail("menu camera di luar pos: z=" + str(cam.position.z))
	if absf(rad_to_deg(cam.rotation.y) - Balance.MENU_DESK_CAM_YAW_DEG) < 1.0:
		_pass("menu camera yaw menghadap selatan (180)")
	else:
		_fail("menu camera yaw " + str(rad_to_deg(cam.rotation.y)) + " (bukan 180)")
	if absf(cam.fov - Balance.MENU_DESK_CAM_FOV) < 0.5:
		_pass("menu camera fov " + str(Balance.MENU_DESK_CAM_FOV))
	else:
		_fail("menu camera fov " + str(cam.fov) + " (bukan " + str(Balance.MENU_DESK_CAM_FOV) + ")")

func _find_sprite_with(root: Node, needle: String) -> bool:
	for n in root.get_children():
		if n is Sprite3D:
			var t := (n as Sprite3D).texture
			if t != null and needle in t.resource_path:
				return true
		if _find_sprite_with(n, needle):
			return true
	return false

func _find_menu_silhouette(root: Node) -> Sprite3D:
	# Siluet menu (kalau ada) berdiri di sisi SELATAN (z > 0, arah
	# jendela). Level permainan sendiri punya elephant_shadow di
	# kabut utara (7, 0, -36) — itu bukan siluet menu.
	if root == null:
		return null
	for n in root.get_children():
		if n is Sprite3D:
			var t := (n as Sprite3D).texture
			if t != null and "elephant_shadow" in t.resource_path and (n as Sprite3D).position.z > 0.0:
				return n as Sprite3D
		var found := _find_menu_silhouette(n)
		if found != null:
			return found
	return null

func _find_label3d(root: Node, text: String) -> Label3D:
	for n in root.get_children():
		if n is Label3D and str((n as Label3D).text) == text:
			return n as Label3D
		var found := _find_label3d(n, text)
		if found != null:
			return found
	return null

func _test_book_pages() -> void:
	var backdrop := _menu.get_node_or_null("Backdrop") as Node3D
	if backdrop == null:
		_fail("backdrop tidak ada")
		return
	# v25: halaman dari tekstur v25 (teks di-bake + siluet kepala
	# gajah di atas judul). Rig ini jalan tanpa save, jadi halaman
	# kanan harus varian MATI.
	if _find_sprite_with(backdrop, "menu_book_page_l_v25"):
		_pass("halaman kiri buku v25 ada")
	else:
		_fail("halaman kiri buku v25 tidak ada")
	if _find_sprite_with(backdrop, "menu_book_page_r_disabled_v25"):
		_pass("halaman kanan buku v25 (varian mati, tanpa save) ada")
	else:
		_fail("halaman kanan buku v25 mati tidak ada")
	# v25: bar merah pilihan (bukan outline v24) harus ada di
	# baris Start (terpilih default).
	if _find_sprite_with(backdrop, "menu_bar_start_v25"):
		_pass("bar merah Start v25 ada")
	else:
		_fail("bar merah Start v25 tidak ada")
	# v25: logo + header + siluet kepala bukan lagi node terpisah — mereka di-bake
	# ke tekstur halaman kiri. Kalau sprite/logo Label3D-nya masih
	# ada, refactor tidak bersih.
	if _find_sprite_with(backdrop, "menu_logo_v20"):
		_fail("sprite menu_logo_v20 masih ada (seharusnya di-bake)")
	else:
		_pass("logo judul tidak lagi sprite terpisah (di-bake)")
	if _find_label3d(backdrop, "Buku jaga, Pos 07") != null:
		_fail("Label3D 'Buku jaga, Pos 07' masih ada (seharusnya di-bake)")
	else:
		_pass("header bukan lagi Label3D (di-bake ke halaman)")
	# v24 (kritik #1): lentera di sudut kiri meja, DI LUAR kertas
	# (kertas berakhir x -2,27) — bukan di atas judul lagi.
	var lantern := backdrop.get_node_or_null("Lantern") as Node3D
	if lantern == null:
		_fail("lentera menu tidak ada")
	elif lantern.position.x < -2.27:
		_pass("lentera di luar kertas (x %.2f, pojok kiri meja)" % lantern.position.x)
	else:
		_fail("lentera masih di atas kertas: x=" + str(lantern.position.x))

func _test_book_rows() -> void:
	var names: Array[String] = _menu.row_names()
	var expected: Array[String] = ["Start", "Continue", "Options", "Exit"]
	if names == expected:
		_pass("baris menu: " + ", ".join(names))
	else:
		_fail("baris menu: " + ", ".join(names) + " (bukan Start, Continue, Options, Exit)")
	# Posisi layar baris harus berurutan dari atas ke bawah
	# (Start di atas, Exit di bawah) dan di dalam viewport.
	# Batas diambil dari ukuran viewport yang sebenarnya (portrait
	# 720x1280 me-letterbox konten 1280x720 ke 720x405 di tengah).
	var vp_size := get_viewport().get_visible_rect().size
	var last_y := -1.0
	var ok := true
	for n in expected:
		var p: Vector2 = _menu.screen_pos_for_row(n)
		if p == Vector2.ZERO:
			_fail("posisi layar baris " + n + " tidak bisa diproyeksi")
			ok = false
			continue
		if p.x < 0 or p.x > vp_size.x or p.y < 0 or p.y > vp_size.y:
			_fail("baris " + n + " di luar viewport: " + str(p))
			ok = false
		if p.y <= last_y:
			_fail("baris " + n + " tidak berurutan (y=" + str(p.y) + ", sebelumnya " + str(last_y) + ")")
			ok = false
		last_y = p.y
	if ok:
		_pass("baris menu berurutan atas-bawah di dalam viewport")

func _test_menu_no_save() -> void:
	if not _menu.row_enabled("Continue"):
		_pass("Continue mati tanpa save")
	else:
		_fail("Continue hidup padahal tidak ada save")
	if _menu.row_sub("Continue") == "no record on this slot":
		_pass("sub-baris Continue: 'no record on this slot'")
	else:
		_fail("sub-baris Continue: '" + _menu.row_sub("Continue") + "'")
	# Kritik #3: TIDAK ADA sisa CCTV di menu.
	if not _menu.has_cctv():
		_pass("tidak ada label REC/CAM di menu")
	else:
		_fail("masih ada label REC/CAM di menu")
	if _menu._fx_mat != null:
		var sm: ShaderMaterial = _menu._fx_mat
		var scan := float(sm.get_shader_parameter("scanline"))
		var tear := float(sm.get_shader_parameter("tear_shift"))
		if scan == 0.0 and tear == 0.0:
			_pass("grade menu: scanline 0, tear 0 (bukan CCTV)")
		else:
			_fail("grade menu masih CCTV: scanline=" + str(scan) + ", tear=" + str(tear))

func _test_giant_window() -> void:
	var backdrop := _menu.get_node_or_null("Backdrop") as Node3D
	if backdrop == null:
		_fail("backdrop tidak ada")
		return
	# v28: kepala Zunisha UTUH di luar jendela selatan — aset baru
	# giant_head_zunisha_v28 (grade DIBALIK dari v26 + tepi feather).
	# Aturan tidak-pernah-utuh DICABUT, jadi yang dicek di sini
	# hanya kepalanya ada, bukan "sebagian saja".
	if _find_sprite_with(backdrop, "giant_head_zunisha_v28"):
		_pass("Kepala Zunisha v28 di luar jendela selatan ada")
	else:
		_fail("Kepala Zunisha v28 di luar jendela selatan tidak ada")
	# v28: kabut pangkal kepala — puff di depan ujung belalai.
	var wraps := 0
	for n in backdrop.get_children():
		if n is Sprite3D:
			var t := (n as Sprite3D).texture
			if t != null and "fog_puff" in t.resource_path:
				var pp := (n as Sprite3D).position
				if pp.z > 10.0 and pp.z < 11.5 and pp.x > 0.0 and pp.x < 4.0:
					wraps += 1
	if wraps >= 3:
		_pass("kabut pangkal kepala: %d puff di depan belalai" % wraps)
	else:
		_fail("kabut pangkal kepala: %d puff (harus >= 3)" % wraps)
	# v25: elemen tempat dari gambar 2 — papan kuburan (panel
	# kerangka SENGAJA dipotong dari menu ronde 8: kepala 20 m
	# menutupi seluruh jendela; panel tetap aset untuk dalam game).
	if _find_sprite_with(backdrop, "menu_sign_graveyard_v28"):
		_pass("elemen tempat menu_sign_graveyard_v28 ada")
	else:
		_fail("elemen tempat menu_sign_graveyard_v28 tidak ada")
	if _find_sprite_with(backdrop, "menu_skeleton_v25"):
		_fail("panel kerangka masih di menu (seharusnya dipotong ronde 8)")
	else:
		_pass("panel kerangka tidak di menu (dipotong sengaja, aset tetap ada)")
	# v25: siluet BADAN UTUH v21 (elephant_shadow) TIDAK BOLEH
	# kembali (gagal 3x). Yang boleh di selatan sekarang hanya
	# KEPALA Zunisha (di atas). Hati-hati: level permainan SENDIRI
	# punya elephant_shadow di kabut utara (7, 0, -36) — itu bukan
	# siluet menu; yang dicek di sini hanya sisi selatan (z > 0).
	var sil := _find_menu_silhouette(backdrop)
	if sil != null:
		_fail("siluet badan utuh v21 masih ada di " + str(sil.position) + " (seharusnya dihapus)")
	else:
		_pass("siluet badan utuh v21 tidak ada di menu selatan")
	# Puff kabut di kusen dihapus sejak v24 (menutupi Giant) —
	# kabut jendela sekarang hanya volumetrik + hutan, dicek lewat
	# screenshot, bukan lewat node.

func _test_menu_options_grain() -> void:
	if _menu._fx_mat == null:
		_fail("fx material tidak ada")
		return
	var grain := float(_menu._fx_mat.get_shader_parameter("grain"))
	if absf(grain - Balance.MENU_GRADE_GRAIN) < 0.001:
		_pass("grain menu: " + str(grain) + " (grade halus, bukan VHS penuh)")
	else:
		_fail("grain menu: " + str(grain) + " (bukan " + str(Balance.MENU_GRADE_GRAIN) + ")")

func _test_menu_click_options() -> void:
	# Klik SUNGGUHAN pada baris Options (bukan emit pressed):
	# membuktikan raycast _ray_to_book + jalur _input jalan.
	var pos: Vector2 = _menu.screen_pos_for_row("Options")
	if pos == Vector2.ZERO:
		_fail("posisi layar baris Options tidak bisa diproyeksi")
		return
	_click_at(pos)

func _click_at(pos: Vector2) -> void:
	# pos adalah koordinat KANVAS (dari unproject_position / rect
	# Control, ruang base 1280x720). InputEventMouseButton yang
	# di-inject lewat parse_input_event masuk lewat pipeline input
	# yang sama dengan mouse asli: posisinya dibaca sebagai
	# koordinat JENDELA (piksel fisik) lalu ditransformasi stretch
	# ke kanvas sebelum sampai ke _input. Jadi di portrait
	# (letterbox) klik harus dikonversi kanvas -> jendela dulu.
	# get_canvas_transform() TIDAK bisa dipakai untuk ini: di
	# portrait ia identitas (terbukti di log DBG), sementara
	# stretch-nya nyata (skala 0,5625 + offset y 437,5). Hitung
	# stretch KEEP manual dari ukuran jendela vs base. Di desktop
	# skala 1 + offset 0, jadi tidak berubah.
	var win := Vector2(get_tree().root.size)
	var base := get_viewport().get_visible_rect().size
	var s := minf(win.x / base.x, win.y / base.y)
	var off := (win - base * s) * 0.5
	var win_pos := pos * s + off
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = win_pos
	Input.parse_input_event(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = win_pos
	Input.parse_input_event(release)

func _test_settings() -> void:
	if not _menu.is_options_visible():
		_fail("klik Options tidak membuka formulir")
		return
	_pass("klik Options membuka formulir")
	if _menu._master_slider != null:
		var before: float = _menu._master_slider.value
		_menu._master_slider.value = 0.5
		if absf(Settings.vol("Master") - 0.5) < 0.001:
			_pass("master slider -> Settings")
		else:
			_fail("master slider tidak mengubah Settings: " + str(Settings.vol("Master")))
		_menu._master_slider.value = before
	else:
		_fail("master slider tidak ada")
	if _menu._sens_slider != null:
		var before: float = _menu._sens_slider.value
		_menu._sens_slider.value = 1.2
		if absf(Settings.mouse_sens() - 1.2) < 0.001:
			_pass("sensitivity slider -> Settings")
		else:
			_fail("sensitivity slider tidak mengubah Settings")
		_menu._sens_slider.value = before
	else:
		_fail("sensitivity slider tidak ada")
	if _menu._grain_check != null:
		var before: bool = _menu._grain_check.button_pressed
		_menu._grain_check.button_pressed = not before
		var grain := float(_menu._fx_mat.get_shader_parameter("grain"))
		# v25: ekspektasi dulu terbalik — setelah toggle ke (not
		# before), grain = 0.05 kalau saklar baru ON, 0.0 kalau OFF.
		var expected := Balance.MENU_GRADE_GRAIN if not before else 0.0
		if absf(grain - expected) < 0.001:
			_pass("grain toggle -> grade menu")
		else:
			_fail("grain toggle tidak mengubah grade: " + str(grain))
		_menu._grain_check.button_pressed = before
	else:
		_fail("grain check tidak ada")

func _test_back_to_main_clicks() -> void:
	# Klik SUNGGUHAN pada tombol Kembali di formulir. Formulir
	# sudah di-scroll ke bawah di fase sebelumnya, jadi global
	# rect tombol valid.
	var back_btn := _find_button(_menu, "Kembali")
	if back_btn == null:
		_fail("tombol Kembali tidak ada")
		return
	var center := back_btn.get_global_rect().get_center()
	_click_at(center)

func _test_back_to_main_check() -> void:
	if _menu.is_main_visible():
		_pass("klik Kembali kembali ke buku")
	else:
		_fail("klik Kembali tidak kembali ke buku")

func _find_button(node: Node, text: String) -> Button:
	if node is Button and str((node as Button).text) == text:
		return node as Button
	for c in node.get_children():
		var found := _find_button(c, text)
		if found != null:
			return found
	return null

func _test_save() -> void:
	# v18: buat save dummy (isi GameState lalu SaveGame.save()) +
	# reload scene menu: Continue harus hidup dan membawa info
	# simpanan. SaveGame tidak punya save_now — save() membaca
	# GameState yang sedang berjalan.
	GameState.shift_minutes = 123.0
	GameState.sanity = 80.0
	GameState.stability = 65.0
	GameState.fuel = 40.0
	GameState.generator_on = true
	var ok: bool = SaveGame.save()
	if not ok:
		_fail("save_now gagal")
		return
	_log.store_line("save_created: " + SaveGame.summary_text())
	_log.flush()
	_pass("save dummy dibuat: " + SaveGame.summary_text())

func _reload_menu_with_save() -> void:
	_menu.queue_free()
	_menu = (load(RES_PATH) as PackedScene).instantiate()
	add_child(_menu)
	_phase = "save"

func _test_menu_with_save() -> void:
	if _menu.row_enabled("Continue"):
		_pass("Continue hidup dengan save")
	else:
		_fail("Continue mati padahal ada save")
	var sub: String = _menu.row_sub("Continue")
	if sub != "" and sub != "no record on this slot":
		_pass("sub-baris Continue membawa info: '" + sub + "'")
	else:
		_fail("sub-baris Continue kosong/tidak membawa info: '" + sub + "'")

func _test_menu_exit() -> void:
	# Exit tidak diuji dengan klik di sini (itu menutup rig).
	# Jalankan dengan -- menu_test_exit=1 di proses terpisah.
	var scene := load("res://scenes/menu.tscn") as PackedScene
	var inst := scene.instantiate()
	inst.queue_free()
	_pass("menu.tscn bisa diinstansiasi ulang (jalur exit diuji terpisah)")

func _shot(tag: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var path := SHOT_DIR + "/" + _prefix + "_" + tag + ".png"
	img.save_png(path)
	_log.store_line("shot: " + path)

func _pass(msg: String) -> void:
	_passes += 1
	_log.store_line("PASS " + msg)
	_log.flush()

func _fail(msg: String) -> void:
	_fails += 1
	_log.store_line("FAIL " + msg)
	_log.flush()

func _finish() -> void:
	# Jangan tinggalkan save dummy untuk run berikutnya.
	SaveGame.clear()
	_log.store_line("menu_results: " + str(_passes) + " pass, " + str(_fails) + " fail")
	if _fails == 0:
		_log.store_line("RESULT MENU PASS")
	else:
		_log.store_line("RESULT MENU FAIL")
	_log.close()
	print("[MENU-RIG] " + str(_passes) + " pass, " + str(_fails) + " fail")
	get_tree().quit(0 if _fails == 0 else 1)
