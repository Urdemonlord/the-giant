extends Node
## Video rig THE GIANT — rekaman gameplay asli (bukan fake frame).
## Jalankan: Godot --path . --resolution 1280x720 scenes/video_rig.tscn -- video=1
## Alur: menu -> intro (E untuk skip) -> jalan keluar pos -> generator ->
## radio (suara + teks) -> buku jaga -> lentera -> tutup pintu ->
## pemburu 01:30 -> kaki Giant 03:30 -> mata Giant 04:45 -> ending 06:00.
## Waktu in-game DIPERCEPAT di antara event (lompat shift_minutes),
## persis seperti mode playtest di test_rig.gd; event sendiri jalan
## real-time. JANGAN jadikan ini bukti durasi shift penuh (480 detik).
## Suara: sandbox tanpa sound card, Godot pakai dummy audio driver,
## jadi video ini BISU. Jangan dub audio palsu di atasnya.
## Log: ~/workspace/godot/shots/video_results_video.txt

var _log_path := "/home/hatch/workspace/godot/shots/video_results_video.txt"
var _player: Node3D = null

func _ready() -> void:
	var f := FileAccess.open(_log_path, FileAccess.WRITE)
	if f:
		f.close()
	_log("video rig mulai")
	_run()

func _log(s: String) -> void:
	print("[VIDEO] " + s)
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

func _wait_until(cond: Callable, timeout_s: float) -> bool:
	var t := 0.0
	while t < timeout_s:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false

func _set_view(pos: Vector3, yaw_deg: float, pitch_deg: float) -> void:
	_player.global_position = pos
	_player.rotation.y = deg_to_rad(yaw_deg)
	_player.pitch = deg_to_rad(pitch_deg)
	_player.head.rotation.x = deg_to_rad(pitch_deg)
	await _frames(2)

func _face_point(target: Vector3) -> void:
	var d := target - _player.global_position
	d.y = 0.0
	if d.length() < 0.01:
		return
	d = d.normalized()
	_player.rotation.y = atan2(-d.x, -d.z)
	_player.pitch = 0.0
	_player.head.rotation.x = 0.0

func _aim_at(target: Vector3) -> void:
	var d := target - _player.global_position
	var horiz := Vector2(d.x, d.z).length()
	_player.rotation.y = atan2(-d.x, -d.z)
	var pitch := atan2(d.y - 1.62, horiz)
	_player.pitch = pitch
	_player.head.rotation.x = pitch
	await _frames(3)

func _walk_toward(target: Vector3, timeout_s: float, stop_dist: float) -> bool:
	Input.action_press("move_forward")
	var t := 0.0
	var ok := false
	while t < timeout_s:
		var cur := _player.global_position
		if Vector2(cur.x, cur.z).distance_to(Vector2(target.x, target.z)) <= stop_dist:
			ok = true
			break
		_face_point(target)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	Input.action_release("move_forward")
	await _frames(2)
	return ok

func _prompt_text() -> String:
	var target: Object = _player.get_current_interactable()
	if target != null and target.has_method("get_prompt"):
		return str(target.get_prompt())
	return ""

func _press_interact() -> bool:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var ev2 := InputEventAction.new()
	ev2.action = "interact"
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await _frames(2)
	return true

func _interact_at(target: Vector3, expect_in_prompt: String) -> bool:
	await _aim_at(target)
	var prompt := _prompt_text()
	_log("aim " + str(target) + " prompt='" + prompt + "'")
	if expect_in_prompt != "" and not expect_in_prompt in prompt:
		_log("FAIL prompt tidak mengandung '" + expect_in_prompt + "'")
		return false
	await _press_interact()
	return true

func _run() -> void:
	await _frames(30)
	var _video_arg := "1"
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("video="):
			_video_arg = str(a).trim_prefix("video=")
	if _video_arg == "menu":
		# Klip menu saja (digabung dengan klip gameplay di
		# post-processing). Dipisah karena menu + main dalam SATU
		# sesi X11 meninggalkan "hantu" menu di belakang panel intro
		# pada rekaman x11grab (viewport Godot sendiri bersih,
		# dibuktikan video_diag_intro.png take 5: menu valid=false,
		# anak rig kosong, screenshot bersih; hantu cuma ada di
		# pixmap X yang direkam ffmpeg).
		var menu_scene := load("res://scenes/menu.tscn") as PackedScene
		var menu := menu_scene.instantiate()
		add_child(menu)
		_log("menu tampil (klip menu), tahan 8 dtk")
		await _wait_sec(8.0)
		_log("DONE video menu")
		get_tree().quit()
		return
	# Klip gameplay: langsung ke Main (tanpa menu di sesi ini, supaya
	# tidak ada hantu menu di rekaman). Intro tetap muncul karena run
	# ini TANPA argumen mode= (lihat main.gd).
	_log("gameplay: masuk Main langsung (tanpa menu di sesi ini)")
	GameState.resume_data = {}
	GameState.reset_shift()
	SaveGame.clear()
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main_inst := main_scene.instantiate()
	add_child(main_inst)
	await _frames(10)
	_player = get_tree().get_first_node_in_group("player")
	var hud := get_tree().get_first_node_in_group("hud")
	_log("main masuk, player=" + str(_player != null) + " intro_open=" + str(hud._intro_open if hud else "?"))
	# 2. Intro (muncul karena run ini TANPA argumen mode=, lihat main.gd).
	var intro_ok := await _wait_until(func() -> bool: return hud._intro_open, 5.0)
	_log("intro muncul=" + str(intro_ok))
	if intro_ok:
		await _wait_sec(6.0) # penonton sempat baca brief shift
		await _press_interact() # E = "Mulai Shift (E)"
		await _frames(5)
		_log("intro ditutup E, intro_open=" + str(hud._intro_open))
	# 3. Buka pintu, jalan keluar pos.
	var ok := await _walk_toward(Vector3(0, 0, -1.4), 6.0, 0.5)
	_log("jalan ke pintu ok=" + str(ok))
	await _interact_at(Vector3(0, 1.4, -2.0), "Pintu")
	await _wait_sec(1.0)
	_log("pintu terbuka=" + str(GameState.door_open))
	ok = await _walk_toward(Vector3(0, 0, -4.5), 6.0, 0.8)
	_log("keluar pos ok=" + str(ok) + " pos=" + str(_player.global_position))
	await _wait_sec(2.0) # tengok hutan + kabut dari luar
	# 4. Generator.
	ok = await _walk_toward(Vector3(3.6, 0, -1.2), 8.0, 2.2)
	_log("jalan ke generator ok=" + str(ok))
	await _interact_at(Vector3(3.6, 0.5, -1.2), "Generator")
	await _frames(5)
	_log("generator nyala=" + str(GameState.generator_on))
	await _wait_sec(2.5) # lampu teras menyala di kabut
	# 5. Kembali masuk pos (dua kaki, hindari sudut tangga).
	ok = await _walk_toward(Vector3(0, 0, -4.0), 8.0, 0.5)
	_log("ke depan pintu ok=" + str(ok))
	ok = await _walk_toward(Vector3(0, 0, 1.3), 8.0, 0.5)
	_log("kembali ke pos ok=" + str(ok))
	# 6. Radio: teks siaran + suara voice clip (bisu di sandbox).
	await _interact_at(Vector3(-1.55, 1.27, 1.35), "Radio")
	_log("tugas radio=" + str(GameState.is_task_done("radio")))
	await _wait_sec(5.0) # siaran 1 sempat kebaca + voice clip jalan
	# 7. Buku jaga (log).
	await _interact_at(Vector3(-1.02, 1.14, 1.28), "Buku")
	_log("tugas log=" + str(GameState.is_task_done("log")) + " sanity=" + str(GameState.sanity))
	await _wait_sec(3.0)
	# 8. Lentera.
	var lantern := get_node_or_null("Main/Lantern")
	if lantern == null:
		lantern = get_tree().get_first_node_in_group("lantern")
	var lb: bool = lantern.is_on if lantern != null else false
	await _interact_at(Vector3(-0.55, 1.27, 1.64), "Lentera")
	_log("lentera toggle " + str(lb) + " -> " + str(lantern.is_on if lantern != null else "?"))
	# Lentera harus tetap MENYALA untuk sisa shift (seperti playtest):
	# kalau tadi mati, nyalakan lagi, kalau tidak interior gelap total
	# saat pemburu/kaki/mata difilmkan.
	if lantern != null and not lantern.is_on:
		await _interact_at(Vector3(-0.55, 1.27, 1.64), "Lentera")
		_log("lentera dinyalakan lagi untuk sisa shift")
	await _wait_sec(1.5)
	# 9. Tutup pintu.
	ok = await _walk_toward(Vector3(0, 0, -1.0), 6.0, 0.5)
	_log("jalan ke pintu (tutup) ok=" + str(ok))
	await _interact_at(Vector3(-0.6, 1.4, -1.5), "Pintu")
	await _wait_sec(1.0)
	_log("pintu tertutup=" + str(not GameState.door_open))
	# 10. Event pemburu 01:30 (lompat waktu: 209 -> 210).
	GameState.sanity = 100.0
	GameState.shift_minutes = 209.0
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0)
	var hunter := get_tree().get_first_node_in_group("hunter_event")
	ok = await _wait_until(func() -> bool: return hunter._active, 6.0)
	_log("event pemburu mulai=" + str(ok) + " jam=" + GameState.clock_text())
	# DARI DALAM dengan pintu tertutup, pemburu TIDAK KELIHATAN (mereka
	# di balik kayu solid) — video take 1 cuma menunjukkan pintu.
	# Jadi kamera dipindah ke luar (sudut yang sama dengan shot
	# hunter_out di test_rig v7): dua sosok menatap pos. Event-nya
	# tetap jalan normal: tugas selesai karena pintu tertutup, dan
	# drain tatapan cuma berlaku kalau pintu terbuka (hunter_event.gd).
	# Take 2 dari z=-19: kabut volumetrik menelan mereka (hampir tidak
	# kelihatan). Take 3: kamera lebih dekat (z=-16, 3,5-5 m dari
	# pemburu di -11/-12,5) + senter menyala supaya mereka kebaca.
	await _set_view(Vector3(0, 0.45, -16.0), 180, 2)
	_player.flashlight_on = true
	_player.flashlight.visible = true
	_log("kamera pemburu: dari luar z=-16 + senter, menghadap pos")
	ok = await _wait_until(func() -> bool: return GameState.is_task_done("hunter"), 25.0)
	_log("tugas hunter selesai=" + str(ok) + " sanity=" + str(GameState.sanity))
	await _wait_sec(2.0)
	_player.flashlight_on = false
	_player.flashlight.visible = false
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0) # kembali ke dalam
	# 11. Kaki Giant 03:30, lihat lewat jendela belakang.
	GameState.sanity = 100.0
	GameState.shift_minutes = 329.0
	await _set_view(Vector3(0, 0.45, 0.2), 180, 0)
	var giant := get_tree().get_first_node_in_group("giant_event")
	ok = await _wait_until(func() -> bool: return giant.active_event == "foot", 6.0)
	_log("event kaki mulai=" + str(ok) + " jam=" + GameState.clock_text())
	await _wait_sec(5.0) # kaki di tengah jendela
	ok = await _wait_until(func() -> bool: return giant.active_event == "", 12.0)
	_log("event kaki selesai=" + str(ok) + " sanity=" + str(GameState.sanity))
	# 12. Mata Giant 04:45.
	GameState.sanity = 100.0
	GameState.shift_minutes = 404.0
	ok = await _wait_until(func() -> bool: return giant.active_event == "eye", 6.0)
	_log("event mata mulai=" + str(ok) + " jam=" + GameState.clock_text())
	await _wait_sec(4.0) # mata menempel di kaca
	ok = await _wait_until(func() -> bool: return giant.active_event == "", 14.0)
	_log("event mata selesai=" + str(ok) + " sanity=" + str(GameState.sanity))
	# 13. Bertahan sampai 06:00 (lompat ke 470, 10 menit terakhir real-time).
	GameState.sanity = 100.0
	GameState.stability = 100.0
	GameState.set_generator(true)
	GameState.shift_minutes = 470.0
	_log("lompat ke 05:50, tunggu fajar, jam=" + GameState.clock_text())
	ok = await _wait_until(func() -> bool: return GameState.shift_over, 30.0)
	_log("shift_over=" + str(ok) + " alasan=" + GameState.end_reason)
	await _frames(5)
	_log("panel ending buka=" + str(hud._end_open) + " judul='" + (hud._end_title.text if hud else "?") + "'")
	await _wait_sec(7.0) # penonton baca ending
	_log("DONE video")
	get_tree().quit()
