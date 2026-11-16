extends Node
## Uji menu utama headless: screenshot menu tanpa save, buat save,
## reload, screenshot menu dengan tombol Lanjutkan aktif, lalu tekan
## MULAI SHIFT BARU dan pastikan masuk scene main.
## Log ke <shot_dir>/v10_results_menu.txt, screenshot v10_menu_*.png.

const SHOT_DIR := "/home/hatch/workspace/godot/shots/"

var _log_path := ""
var _menu: Control = null

func _ready() -> void:
	_log_path = SHOT_DIR + "v10_results_menu.txt"
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
		await _shot("menu_no_save")
		# Buat save, reload menu, tombol Lanjutkan harus aktif.
		SaveGame.save()
		await get_tree().reload_current_scene()
		return
	_log("menu: setelah save, continue disabled=" + str(_menu._continue_btn.disabled) + " text='" + _menu._continue_btn.text + "'")
	await _shot("menu_with_save")
	# Transisi menu -> main TIDAK diuji dari sini: memanggil _on_new_game
	# akan mem-free node ini (ganti scene) sehingga coroutine tidak
	# pernah sampai quit. Transisi diuji terpisah: jalankan menu dengan
	# argumen menu_autostart=1, main_menu memanggil _on_new_game sendiri
	# dan main.gd mencatat "[Main] scene main siap" di stdout.
	SaveGame.clear() # jangan tinggalkan save uji untuk run berikutnya
	_log("DONE mode=menu")
	get_tree().quit()

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

func _shot(name: String) -> void:
	await _frames(3)
	var img := get_viewport().get_texture().get_image()
	var path := SHOT_DIR + "v10_" + name + ".png"
	var err := img.save_png(path)
	_log("shot " + name + " err=" + str(err) + " path=" + path)
