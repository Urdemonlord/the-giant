extends Node
## Uji menu utama headless (v20: latar 3D hidup): screenshot menu tanpa
## save, buat save, reload, screenshot menu dengan tombol Lanjutkan
## aktif, buka Cara main, lalu tekan MULAI SHIFT BARU dan pastikan
## masuk scene main. Asert backdrop: node Backdrop ada, kamera menu
## aktif, luminansi rata-rata frame di atas ambang hitam polos, dan
## yaw kamera berubah antar dua shot (sapuan jalan).
## Log ke <shot_dir>/v20_results_menu.txt, screenshot v20_menu_*.png.

const SHOT_DIR := "/home/hatch/workspace/godot/shots/"

var _log_path := ""
var _menu: Control = null

func _ready() -> void:
	_log_path = SHOT_DIR + "v20_results_menu.txt"
	# Fase 2 terdeteksi dari save yang ada (reload_current_scene
	# menjalankan _ready ini lagi, jadi tidak boleh mengulang fase 1).
	var phase2 := SaveGame.has_save()
	if not phase2:
		var init := FileAccess.open(_log_path, FileAccess.WRITE)
		if init:
			init.close()
	_menu = get_node("Menu") as Control
	await _frames(30)
	if not phase2:
		_log("menu: tampil, continue disabled=" + str(_menu._continue_btn.disabled) + " text='" + _menu._continue_btn.text + "'")
		# v20: backdrop harus ada + kamera menu aktif + fokus di tombol mulai.
		var bd := _menu.get_node_or_null("Backdrop")
		var cam := _menu.get_node_or_null("Backdrop/MenuCamera") as Camera3D
		_log("menu: backdrop=" + str(bd != null) + " camera_current=" + str(cam != null and cam.current) + " cam_yaw=" + str(snappedf(_cam_yaw(), 0.1)))
		_log("menu: focus=" + str(get_viewport().gui_get_focus_owner() == _menu._start_btn))
		await _shot("menu_no_save")
		# Sapuan kamera: tunggu seperempat periode (6.5 dtk) supaya
		# yaw bergeser ke ujung, lalu shot lagi — dua shot harus beda.
		await _wait_sec(6.5)
		_log("menu: cam_yaw setelah 6.5 dtk=" + str(snappedf(_cam_yaw(), 0.1)))
		await _shot("menu_no_save_pan")
		# Buat save, reload menu, tombol Lanjutkan harus aktif.
		SaveGame.save()
		await get_tree().reload_current_scene()
		return
	_log("menu: setelah save, continue disabled=" + str(_menu._continue_btn.disabled) + " text='" + _menu._continue_btn.text + "'")
	await _shot("menu_with_save")
	# Cara main: buka panel kontrol, shot, tutup lagi.
	_menu._help_label.visible = true
	await _frames(5)
	_log("menu: help visible=" + str(_menu._help_label.visible))
	await _shot("menu_help")
	# Transisi menu -> main TIDAK diuji dari sini: memanggil _on_new_game
	# akan mem-free node ini (ganti scene) sehingga coroutine tidak
	# pernah sampai quit. Transisi diuji terpisah: jalankan menu dengan
	# argumen menu_autostart=1, main_menu memanggil _on_new_game sendiri
	# dan main.gd mencatat "[Main] scene main siap" di stdout.
	SaveGame.clear() # jangan tinggalkan save uji untuk run berikutnya
	_log("DONE mode=menu")
	get_tree().quit()

func _cam_yaw() -> float:
	var cam := _menu.get_node_or_null("Backdrop/MenuCamera") as Camera3D
	if cam == null:
		return -999.0
	return rad_to_deg(cam.rotation.y)

func _log(s: String) -> void:
	print("[RIG] " + s)
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(s)
		f.close()

func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame

func _wait_sec(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shot(name: String) -> void:
	await _frames(3)
	var img := get_viewport().get_texture().get_image()
	# v20: bukti latar BUKAN hitam polos — rata-rata luminansi frame
	# (sampel tiap 16 piksel). Menu v15 di atas hitam: ~0.02. Latar
	# 3D malam dengan lentera teras: jelas di atas 0.05.
	var mean := 0.0
	var step := 16
	var n := 0
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var c := img.get_pixel(x, y)
			mean += 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			n += 1
	mean /= maxf(n, 1.0)
	_log("shot " + name + " mean_lum=" + str(snappedf(mean, 0.001)) + " backdrop_lit=" + str(mean > 0.05))
	var path := SHOT_DIR + "v20_" + name + ".png"
	var err := img.save_png(path)
	_log("shot " + name + " err=" + str(err) + " path=" + path)
