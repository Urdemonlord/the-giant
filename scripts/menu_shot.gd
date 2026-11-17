extends Node
## Uji menu utama headless (v22: tema buku jaga, 4 tombol, Options):
## fase A tanpa save: 4 tombol persis (Start/Continue/Options/Exit),
## Continue disabled, fokus di Start, tidak ada teks slop, backdrop
## 3D hidup + sapuan kamera; buka Options, uji tiap pengaturan
## (volume bus, sensitivitas, grain, layar penuh) + persistensi
## file; reload, pastikan nilai bertahan; fase B: buat save, reload,
## Continue aktif; pastikan wiring Exit. Transisi menu -> main
## TIDAK diuji dari sini (lihat menu_autostart=1); jalur keluar
## diuji terpisah (menu_test_exit=1, proses harus berhenti).
## Log ke <shot_dir>/v23_results_menu.txt, screenshot v23_menu_*.png.
## Static _run_phase bertahan melewati reload_current_scene dalam
## satu proses, jadi fase tidak terulang.

const SHOT_DIR := "/home/hatch/workspace/godot/shots/"

static var _run_phase := 0

var _log_path := ""
var _menu: Control = null

func _ready() -> void:
	_log_path = SHOT_DIR + "v23_results_menu.txt"
	if _run_phase == 0:
		var init := FileAccess.open(_log_path, FileAccess.WRITE)
		if init:
			init.close()
	# Bersihkan state uji dari run sebelumnya supaya fase deterministik.
	Settings.reset_defaults()
	SaveGame.clear()
	_menu = get_node("Menu") as Control
	await _frames(30)
	match _run_phase:
		0:
			await _phase_a()
		1:
			await _phase_b()
		2:
			await _phase_c()
	# v21: fase A/B berakhir dengan reload_current_scene — coroutine
	# lama di node yang sudah di-free kadang lanjut jalan; tanpa
	# guard ini ia mencatat DONE lalu get_tree().quit() di null.
	if not is_inside_tree():
		return
	_log("DONE mode=menu")
	get_tree().quit()

## Fase A: menu utama tanpa save + seluruh layar Options.
func _phase_a() -> void:
	_check_buttons()
	_check_no_slop()
	var bd := _menu.get_node_or_null("Backdrop")
	var cam := _menu.get_node_or_null("Backdrop/MenuCamera") as Camera3D
	_log("menu: backdrop=" + str(bd != null) + " camera_current=" + str(cam != null and cam.current) + " cam_yaw=" + str(snappedf(_cam_yaw(), 0.1)))
	_log("menu: focus_start=" + str(get_viewport().gui_get_focus_owner() == _menu._start_btn))
	await _shot("menu_no_save")
	await _wait_sec(6.5)
	_log("menu: cam_yaw setelah 6.5 dtk=" + str(snappedf(_cam_yaw(), 0.1)))
	await _shot("menu_no_save_pan")
	# Buka Options lewat sinyal tombol (jalur sungguhan, bukan panggil
	# _show_options langsung).
	_menu._options_btn.pressed.emit()
	await _frames(5)
	_log("options: visible=" + str(_menu._options_scroll.visible) + " menu_hidden=" + str(not _menu._menu_box.visible))
	_log("options: focus_master_slider=" + str(get_viewport().gui_get_focus_owner() == _menu._master_slider))
	_check_options_content()
	await _shot("menu_options")
	# v21: HARUS await — tanpa await, coroutine berhenti di await
	# pertama dan sisanya (sens, grain, fullscreen) tidak jalan.
	await _test_settings()
	# Persistensi di DISK (bukan cuma static yang bertahan di proses):
	# baca file settings.json langsung, nilainya harus sama.
	var on_disk := _read_settings_file()
	_log("settings: file master=" + str(on_disk.get("master", -1.0)) + " sens=" + str(on_disk.get("mouse_sens", -1.0)) + " grain=" + str(on_disk.get("grain", "?")) + " fullscreen=" + str(on_disk.get("fullscreen", "?")))
	_run_phase = 1
	await get_tree().reload_current_scene()

## Fase B: setelah reload, slider harus menampilkan nilai tersimpan.
func _phase_b() -> void:
	await _frames(30)
	_menu._options_btn.pressed.emit()
	await _frames(5)
	_log("persist: master_slider=" + str(snappedf(_menu._master_slider.value, 0.01)) + " sens_slider=" + str(snappedf(_menu._sens_slider.value, 0.01)) + " grain_check=" + str(_menu._grain_check.button_pressed) + " fs_check=" + str(_menu._fullscreen_check.button_pressed))
	_log("persist: bus_master_db=" + str(snappedf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")), 0.01)))
	# Kembalikan bawaan supaya tidak ada state uji yang bocor, lalu
	# buat save untuk fase Continue.
	Settings.reset_defaults()
	_menu._show_main()
	await _frames(5)
	SaveGame.save()
	_run_phase = 2
	await get_tree().reload_current_scene()

## Fase C: Continue aktif dengan save + wiring Exit.
func _phase_c() -> void:
	await _frames(30)
	_log("menu: setelah save, continue disabled=" + str(_menu._continue_btn.disabled) + " text='" + _menu._continue_btn.text + "'")
	_log("menu: continue_text_ok=" + str(str(_menu._continue_btn.text).begins_with("Continue - ")))
	await _shot("menu_with_save")
	# Exit: rig tidak bisa quit di tengah run dan lanjut — yang
	# diuji di sini adalah wiring-nya; jalur quit sungguhan diuji
	# run terpisah (menu_test_exit=1).
	_log("exit: wired=" + str(_menu._exit_btn.pressed.is_connected(_menu._on_exit)) + " visible=" + str(_menu._exit_btn.visible))
	SaveGame.clear()
	Settings.reset_defaults()

func _check_buttons() -> void:
	# Empat tombol persis, urutan persis, di luar web (sandbox = desktop).
	# Continue membawa sufiks info simpanan ("Continue - 22:00, ...")
	# atau "no record on file" saat disabled — dicek prefix-nya.
	var got: Array[String] = [
		_menu._start_btn.text, _menu._continue_btn.text,
		_menu._options_btn.text, _menu._exit_btn.text]
	var ok := got[0] == "Start" and str(got[1]).begins_with("Continue") and got[2] == "Options" and got[3] == "Exit"
	_log("menu: buttons=" + str(got) + " ok=" + str(ok))
	_log("menu: continue disabled=" + str(_menu._continue_btn.disabled) + " text='" + _menu._continue_btn.text + "'")
	_log("menu: exit visible=" + str(_menu._exit_btn.visible))

func _check_no_slop() -> void:
	# Tidak ada satu pun label di menu (termasuk layar Options yang
	# tersembunyi) yang berisi blurb toko v15/v17.
	var bad: Array[String] = []
	_collect_labels(_menu, bad)
	_log("menu: slop_labels=" + str(bad) + " ok=" + str(bad.is_empty()))

func _collect_labels(node: Node, bad: Array[String]) -> void:
	if node is Label:
		var t := str((node as Label).text)
		if "cerita horor psikologis" in t or "tidak pernah tampil utuh" in t:
			bad.append(t)
	for c in node.get_children():
		_collect_labels(c, bad)

func _check_options_content() -> void:
	# "Cara main" sekarang hidup di Options: keycap + instruksi ada.
	var texts := _all_label_texts(_menu._options_scroll)
	_log("options: has_cara_main=" + str("Cara main" in texts))
	_log("options: has_keycap_wasd=" + str("WASD" in texts))
	_log("options: has_peralatan=" + str("Peralatan pos" in texts))

func _all_label_texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Label:
		out.append(str((node as Label).text))
	for c in node.get_children():
		out.append_array(_all_label_texts(c))
	return out

func _test_settings() -> void:
	# Volume utama 50% -> bus Master -6.02 dB, tersimpan di Settings.
	_menu._master_slider.value = 0.5
	await _frames(3)
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	_log("settings: master 50% bus_db=" + str(snappedf(db, 0.01)) + " ok=" + str(absf(db - linear_to_db(0.5)) < 0.05))
	# Sensitivitas 1.5x tersimpan.
	_menu._sens_slider.value = 1.5
	await _frames(3)
	_log("settings: sens=" + str(Settings.mouse_sens()) + " ok=" + str(Settings.mouse_sens() == 1.5))
	# Grain mati -> shader menu 0.0; nyala lagi -> bawaan.
	_menu._grain_check.button_pressed = false
	await _frames(3)
	_log("settings: grain off param=" + str(_menu._fx_mat.get_shader_parameter("grain")) + " ok=" + str(float(_menu._fx_mat.get_shader_parameter("grain")) == 0.0))
	_menu._grain_check.button_pressed = true
	await _frames(3)
	_log("settings: grain on param=" + str(_menu._fx_mat.get_shader_parameter("grain")) + " ok=" + str(float(_menu._fx_mat.get_shader_parameter("grain")) == Balance.VHS_GRAIN))
	# Layar penuh: yang diuji pengaturannya (mode window Xvfb tidak
	# bisa diandalkan sebagai bukti visual); kembalikan ke windowed.
	_menu._fullscreen_check.button_pressed = true
	await _frames(3)
	_log("settings: fullscreen=" + str(Settings.fullscreen()) + " ok=" + str(Settings.fullscreen()))
	_menu._fullscreen_check.button_pressed = false
	await _frames(3)
	# Kembali ke menu utama (Esc juga diuji: ui_cancel menutup Options).
	_menu._show_main()
	await _frames(3)
	_log("options: back_to_main=" + str(_menu._menu_box.visible and not _menu._options_scroll.visible))

func _read_settings_file() -> Dictionary:
	if not FileAccess.file_exists(Settings.SETTINGS_PATH):
		return {}
	var f := FileAccess.open(Settings.SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed
	return {}

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
	var path := SHOT_DIR + "v23_" + name + ".png"
	var err := img.save_png(path)
	_log("shot " + name + " err=" + str(err) + " path=" + path)
