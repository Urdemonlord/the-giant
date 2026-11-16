extends Node
## Test rig THE GIANT — IKUT ZIP (bagian dari proyek, bukan alat luar).
## Jalankan: Godot --path . scenes/test_rig.tscn -- mode=<mode> prefix=<prefix>
## Mode: shots | shots11 | shots12 | verify | win | lose | audio | touch | pause | save | playtest | story
## (mode shots9..shots9e lama masih ada untuk arsip visual v9.)
## Log ditulis ke <shot_dir>/<prefix>_results_<mode>.txt dan screenshot
## ke <shot_dir>/<prefix>_<nama>.png. shot_dir = ~/workspace/godot/shots/
## kalau folder itu ada (sandbox), kalau tidak user://shots/ (portabel).
## mode=playtest mensimulasikan pemain manusia: jalan pakai Input
## sungguhan + raycast + tombol E, tugas berurutan, lalu satu shift penuh.
## mode=audio hanya membuktikan jalur play + bentuk file WAV, BUKAN bunyi
## yang terdengar (sandbox tanpa sound card).

var _mode := "shots"
var _prefix := "v10"
var _log_path := ""
var _shot_dir := ""
var _player: Node3D = null

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if str(a).begins_with("mode="):
			_mode = str(a).trim_prefix("mode=")
		if str(a).begins_with("prefix="):
			_prefix = str(a).trim_prefix("prefix=")
	_shot_dir = _resolve_shot_dir()
	_log_path = _shot_dir + _prefix + "_results_" + _mode + ".txt"
	var init := FileAccess.open(_log_path, FileAccess.WRITE)
	if init:
		init.close()
	_log("rig mode=" + _mode + " shot_dir=" + _shot_dir)
	_player = get_tree().get_first_node_in_group("player")
	_run()

func _resolve_shot_dir() -> String:
	var sandbox := "/home/hatch/workspace/godot/shots/"
	if DirAccess.dir_exists_absolute(sandbox):
		return sandbox
	var u := "user://shots/"
	DirAccess.make_dir_recursive_absolute(u)
	return u

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
	var path := _shot_dir + _prefix + "_" + name + ".png"
	var err := img.save_png(path)
	_log("shot " + name + " err=" + str(err) + " path=" + path)

func _set_view(pos: Vector3, yaw_deg: float, pitch_deg: float) -> void:
	_player.global_position = pos
	_player.rotation.y = deg_to_rad(yaw_deg)
	_player.pitch = deg_to_rad(pitch_deg)
	_player.head.rotation.x = deg_to_rad(pitch_deg)
	await _frames(2)

func _wait_until(cond: Callable, timeout_s: float) -> bool:
	var t := 0.0
	while t < timeout_s:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false

func _run() -> void:
	await _frames(30)
	match _mode:
		"shots":
			await _mode_shots()
		"shots9":
			await _mode_shots9()
		"shots9b":
			await _mode_shots9b()
		"shots9c":
			await _mode_shots9c()
		"shots9d":
			await _mode_shots9d()
		"shots9e":
			await _mode_shots9e()
		"shots11":
			await _mode_shots11()
		"shots12":
			await _mode_shots12()
		"story":
			await _mode_story()
		"verify":
			await _mode_verify()
		"win":
			await _mode_win()
		"lose":
			await _mode_lose()
		"audio":
			await _mode_audio()
		"touch":
			await _mode_touch()
		"pause":
			await _mode_pause()
		"save":
			await _mode_save()
		"playtest":
			await _mode_playtest()
		_:
			_log("mode tidak dikenal: " + _mode)
	_log("DONE mode=" + _mode)
	get_tree().quit()

func _mode_shots() -> void:
	# 1. Event pemburu 01:30 dari dalam (dulu, supaya menit 210 tidak terlewat).
	GameState.shift_minutes = 209.0
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0)
	var hunter := get_tree().get_first_node_in_group("hunter_event")
	var ok := await _wait_until(func() -> bool: return hunter._active, 6.0)
	_log("hunter event started: " + str(ok))
	await _wait_sec(2.0)
	await _shot("hunter_vhs")
	# Momen No I'm Not Human dari luar: kamera di utara pemburu
	# (z -19), pemburu di -11/-12.5, pos di belakang mereka.
	await _set_view(Vector3(0, 0.45, -19.0), 180, 2)
	await _shot("hunter_out")
	# 2. Interior menghadap pintu (VHS overlay harus kelihatan).
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0)
	await _shot("door_vhs")
	# 3. Meja jaga (lentera, radio, buku).
	await _set_view(Vector3(0.6, 0.45, 0.2), 140, -6)
	await _shot("desk_vhs")
	# 4. Event kaki Giant 03:30, lihat lewat jendela belakang.
	GameState.sanity = 100.0
	GameState.stability = 100.0
	GameState.shift_minutes = 329.0
	await _set_view(Vector3(0, 0.45, 0.2), 180, 0)
	var giant := get_tree().get_first_node_in_group("giant_event")
	ok = await _wait_until(func() -> bool: return giant.active_event == "foot", 6.0)
	_log("foot event started: " + str(ok))
	await _wait_sec(4.0) # kaki di tengah jendela
	await _shot("foot")
	await _wait_until(func() -> bool: return giant.active_event == "", 12.0)
	_log("foot event ended, sanity=" + str(GameState.sanity))
	# 5. Event mata Giant 04:45 di kaca jendela.
	GameState.sanity = 100.0
	GameState.shift_minutes = 404.0
	ok = await _wait_until(func() -> bool: return giant.active_event == "eye", 6.0)
	_log("eye event started: " + str(ok))
	await _wait_sec(3.0) # mata menempel
	await _shot("eye")
	await _wait_until(func() -> bool: return giant.active_event == "", 14.0)
	_log("eye event ended, sanity=" + str(GameState.sanity))
	GameState.sanity = 100.0
	# 6. Eksterior + lampu teras (generator nyala).
	GameState.set_generator(true)
	await _set_view(Vector3(0, 0.45, -8.0), 180, 2)
	await _shot("outside_porch")

func _mode_shots9() -> void:
	# v9: semua elemen sheet yang baru dipasang, satu screenshot per kelompok.
	# 1. Meja jaga: meter getar di samping buku jaga + radio.
	await _set_view(Vector3(0.6, 0.45, 0.2), 140, -6)
	await _shot("desk_meter")
	# 2. Samping generator: chainsaw, tong, karung, peti tinggi.
	GameState.set_generator(true)
	await _set_view(Vector3(2.0, 0.45, 2.2), -25, -4)
	await _shot("shed")
	# 3. Gerbang + penjaga sebelumnya di samping jalan.
	await _set_view(Vector3(0, 0.45, -3.0), 0, 0)
	await _shot("gate")
	# 4. Kabut utara: gajah depan + siluet gajah.
	await _set_view(Vector3(0, 0.45, -13.0), 0, 2)
	await _shot("north")
	# 5. Poacher topeng merah di hutan timur.
	await _set_view(Vector3(2.0, 0.45, -6.0), -51, 0)
	await _shot("poacher_mask")
	# 6. Siluet putih di kabut barat.
	await _set_view(Vector3(0, 0.45, -10.0), 40, 2)
	await _shot("poacher_ghost")
	# 7. Tanah timur: log, batu, pisang.
	await _set_view(Vector3(3.0, 0.45, -1.5), -50, -10)
	await _shot("ground")
	# 8. Darah di tanah dekat jerat.
	await _set_view(Vector3(-1.0, 0.45, -6.0), 31, -12)
	await _shot("blood")
	# 9. Peti rendah di sisi barat pos.
	await _set_view(Vector3(-1.0, 0.45, -0.5), 38, -6)
	await _shot("crate")
	# 10. Event pemburu 01:30: pemburu kedua = hunter.png.
	GameState.sanity = 100.0
	GameState.shift_minutes = 209.0
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0)
	var hunter := get_tree().get_first_node_in_group("hunter_event")
	var ok := await _wait_until(func() -> bool: return hunter._active, 6.0)
	_log("hunter event started: " + str(ok))
	await _wait_sec(2.0)
	await _set_view(Vector3(0, 0.45, -19.0), 180, 2)
	await _shot("hunter2")

func _mode_shots9b() -> void:
	# v9 ronde 2: ulang 7 shot yang gagal di ronde 1 (sudut/posisi diperbaiki).
	GameState.set_generator(true)
	# 1. Samping generator dari selatan, bukan dari dalam hutan.
	await _set_view(Vector3(1.0, 0.45, 4.5), -27, -8)
	await _shot("shed2")
	# 2. Gerbang dari dekat, di depan pagar.
	await _set_view(Vector3(0, 0.45, -6.0), 0, -2)
	await _shot("gate2")
	# 3. Gajah depan dari dekat, menghadap barat laut.
	await _set_view(Vector3(0, 0.45, -16.0), 35, 2)
	await _shot("north2")
	# 4. Poacher topeng merah, kamera sudah di timur penjaga lama.
	await _set_view(Vector3(6.0, 0.45, -6.0), -37, 0)
	await _shot("poacher_mask2")
	# 5. Siluet putih, sudah didekatkan.
	await _set_view(Vector3(0, 0.45, -8.0), 43, 2)
	await _shot("poacher_ghost2")
	# 6. Darah dari dekat, sudah dibesarkan + didongkrak.
	await _set_view(Vector3(-2.5, 0.45, -8.5), 32, -18)
	await _shot("blood2")
	# 7. Peti rendah dari luar dinding barat, bukan dari dalam pos.
	await _set_view(Vector3(-5.5, 0.45, -1.0), -45, -10)
	await _shot("crate2")

func _mode_shots9c() -> void:
	# v9 ronde 3: tiga shot terakhir yang masih gagal.
	GameState.set_generator(true)
	# 1. Samping generator dari timur (dari selatan ketutup sudut pos).
	await _set_view(Vector3(8.5, 0.45, -1.0), 90, -6)
	await _shot("shed3")
	# 2. Gerbang pakai senter (kayu gelap, tanpa senter tidak kebaca).
	_player.flashlight_on = true
	_player.flashlight.visible = true
	await _set_view(Vector3(0, 0.45, -8.0), 0, -2)
	await _shot("gate3")
	_player.flashlight_on = false
	_player.flashlight.visible = false
	# 3. Poacher topeng merah, sudah didekatkan ke (9,-11).
	await _set_view(Vector3(4.0, 0.45, -5.0), -40, 0)
	await _shot("poacher_mask3")

func _mode_shots9d() -> void:
	# v9 ronde 4: tiga sisa terakhir.
	GameState.set_generator(true)
	# 1. Gerbang dari dekat + senter (4,7 m dari gerbang).
	_player.flashlight_on = true
	_player.flashlight.visible = true
	await _set_view(Vector3(0, 0.45, -11.0), 0, -4)
	await _shot("gate4")
	# 2. Poacher topeng merah berdiri di gerbang, dari pintu pos.
	await _set_view(Vector3(0, 0.45, -3.5), 0, 0)
	await _shot("poacher_mask4")
	_player.flashlight_on = false
	_player.flashlight.visible = false
	# 3. Peti tinggi di tenggara pos.
	await _set_view(Vector3(7.0, 0.45, 3.5), 51, -10)
	await _shot("crate_tall")

func _mode_shots9e() -> void:
	# v9 ronde 5: peti tinggi dari dekat + senter (sebelumnya gelap total).
	GameState.set_generator(true)
	_player.flashlight_on = true
	_player.flashlight.visible = true
	await _set_view(Vector3(5.6, 0.45, 2.6), 51, -15)
	await _shot("crate_tall2")
	_player.flashlight_on = false
	_player.flashlight.visible = false

func _mode_shots11() -> void:
	# v11: kabut + grafik creepy. Tiap shot dicek: hutan jauh harus
	# tertelan kabut, ground fog kelihatan, grain/scanline/CA/vignette
	# terasa tapi HUD + prompt tetap kebaca.
	GameState.set_generator(true)
	# 1. Dari dalam pos, menghadap jendela belakang (hutan utara).
	await _set_view(Vector3(0, 0.45, 1.3), 180, 0)
	await _shot("window_fog")
	# 2. Eksterior: dari jalan di depan pos, menghadap pos + hutan.
	await _set_view(Vector3(0, 0.45, -8.0), 180, 2)
	await _shot("outside_fog")
	# 3. Dari hutan, menghadap pos dari utara (kabut di antara pohon).
	await _set_view(Vector3(0, 0.45, -19.0), 180, 2)
	await _shot("forest_fog")
	# 4. Gerbang + jalan (ground fog di permukaan tanah).
	await _set_view(Vector3(0, 0.45, -11.0), 0, 0)
	await _shot("gate_fog")
	# 5. Meja jaga: overlay creepy dari dekat (grain/scanline/vignette).
	await _set_view(Vector3(0.6, 0.45, 0.2), 140, -6)
	await _shot("desk_creepy")
	# 6. Pintu dari dalam, senter menyala (CA + grain di cahaya).
	_player.flashlight_on = true
	_player.flashlight.visible = true
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0)
	await _shot("door_creepy")
	_player.flashlight_on = false
	_player.flashlight.visible = false
	# 7. Event mata Giant 04:45 (mata di kabut + overlay).
	GameState.sanity = 100.0
	GameState.shift_minutes = 404.0
	var giant := get_tree().get_first_node_in_group("giant_event")
	var ok := await _wait_until(func() -> bool: return giant.active_event == "eye", 6.0)
	_log("eye event started: " + str(ok))
	await _wait_sec(3.0)
	# Jendela ada di belakang pos (arah +z): hadap ke sana, bukan ke pintu.
	await _set_view(Vector3(0, 0.45, 0.2), 180, 0)
	await _shot("eye_fog")

func _mode_shots12() -> void:
	# v12 (brief v7): koran + surat di atas meja, dari sudut meja jaga.
	GameState.set_generator(true)
	await _set_view(Vector3(0.6, 0.45, 0.2), 140, -6)
	await _shot("desk_docs")
	# Dari dekat + senter: kertas koran dan stempel merah surat kebaca.
	_player.flashlight_on = true
	_player.flashlight.visible = true
	await _set_view(Vector3(-0.6, 0.45, 0.2), 125, -14)
	await _shot("desk_docs_close")
	_player.flashlight_on = false
	_player.flashlight.visible = false
	# Dari atas meja, menunduk: kedua kertas di atas meja harus
	# kebaca sebagai kertas (bukan cuma hitbox).
	await _set_view(Vector3(-1.35, 0.45, -0.1), 178, -42)
	await _shot("desk_docs_top")

func _mode_story() -> void:
	# Brief v7: koran/surat bisa dibaca, ending menang/kalah beneran.
	# Rig menjalankan main.tscn dengan argumen mode=, jadi intro
	# sengaja dilewati di sini (intro dicek lewat run langsung + ffmpeg).
	var fails := 0
	var hud := get_tree().get_first_node_in_group("hud")
	_log("story: intro dilewati di rig=" + str(not hud._intro_open) + " (harus true)")
	if hud._intro_open:
		fails += 1
	# 1. Koran: bidik, E, panel buka + pause, screenshot, E lagi tutup.
	if not await _interact_at(Vector3(-2.05, 1.19, 1.05), "Koran"):
		fails += 1
		_log("story: koran FAIL bidik")
	await _frames(5)
	_log("story: koran panel buka=" + str(hud._doc_open) + " paused=" + str(get_tree().paused) + " judul='" + hud._doc_title.text + "'")
	if not hud._doc_open or not get_tree().paused or not "HARIAN RIMBA" in hud._doc_title.text:
		fails += 1
		_log("story: koran FAIL panel/judul/pause")
	if not "Gajah Liar Masuk Kebun Sawit" in hud._doc_body.text:
		fails += 1
		_log("story: koran FAIL headline tidak ada di isi")
	await _shot("doc_newspaper")
	await _press_interact() # E menutup dokumen
	await _frames(5)
	_log("story: koran tutup lewat E, panel buka=" + str(hud._doc_open) + " paused=" + str(get_tree().paused))
	if hud._doc_open or get_tree().paused:
		fails += 1
		_log("story: koran FAIL tidak tertutup lewat E")
		hud.close_document()
	# 2. Surat izin: sama, cek angka 12.400 + catatan tangan.
	if not await _interact_at(Vector3(-0.8, 1.19, 1.6), "Surat"):
		fails += 1
		_log("story: surat FAIL bidik")
	await _frames(5)
	_log("story: surat panel buka=" + str(hud._doc_open) + " judul='" + hud._doc_title.text + "'")
	if not hud._doc_open or not "SURAT KEPUTUSAN" in hud._doc_title.text:
		fails += 1
		_log("story: surat FAIL panel/judul")
	if not "12.400" in hud._doc_body.text or not "gajah sudah tidak ada di sini" in hud._doc_body.text:
		fails += 1
		_log("story: surat FAIL isi (12.400 / catatan tangan)")
	await _shot("doc_permit")
	await _press_interact()
	await _frames(5)
	_log("story: surat tutup lewat E, panel buka=" + str(hud._doc_open) + " paused=" + str(get_tree().paused))
	if hud._doc_open or get_tree().paused:
		fails += 1
		_log("story: surat FAIL tidak tertutup lewat E")
		hud.close_document()
	# 3. Ending menang: sampai 06:00, panel akhir + kalimat faktual.
	GameState.sanity = 100.0
	GameState.stability = 100.0
	GameState.set_generator(true)
	GameState.shift_minutes = 470.0
	var ok := await _wait_until(func() -> bool: return GameState.shift_over, 30.0)
	_log("story: ending menang shift_over=" + str(ok) + " alasan=" + GameState.end_reason)
	if not ok or GameState.end_reason != "dawn":
		fails += 1
	await _frames(5)
	_log("story: ending menang panel buka=" + str(hud._end_open) + " paused=" + str(get_tree().paused) + " judul='" + hud._end_title.text + "'")
	if not hud._end_open or not "Fajar" in hud._end_title.text:
		fails += 1
	if not "satwa dilindungi" in hud._end_body.text:
		fails += 1
		_log("story: ending menang FAIL kalimat faktual tidak ada")
	await _shot("ending_win")
	# 4. Ending kalah (Sanity 0): reset, sembunyikan panel, jatuhkan Sanity.
	GameState.reset_shift()
	hud._end_panel.visible = false
	hud._end_open = false
	get_tree().paused = false
	await _frames(5)
	GameState.damage_sanity(200.0)
	await _frames(5)
	_log("story: ending kalah shift_over=" + str(GameState.shift_over) + " alasan=" + GameState.end_reason + " judul='" + hud._end_title.text + "'")
	if not GameState.shift_over or GameState.end_reason != "sanity":
		fails += 1
	if not hud._end_open or not "Sebelum Pagi" in hud._end_title.text:
		fails += 1
	if not "menatap terlalu lama" in hud._end_body.text or not "satwa dilindungi" in hud._end_body.text:
		fails += 1
		_log("story: ending kalah FAIL isi/payat")
	await _shot("ending_lose")
	_log("story: HASIL fails=" + str(fails) + " -> " + ("PASS" if fails == 0 else "FAIL"))

func _mode_verify() -> void:
	# Audit registry sprite + daftar semua Sprite3D di scene.
	var missing := SpriteRegistry.validate()
	_log("verify: registry ALL_NAMES=" + str(SpriteRegistry.ALL_NAMES.size()) + " missing=" + str(missing))
	await _frames(30)
	var names := {}
	_walk_sprites(get_tree().current_scene, names)
	var total := 0
	for k in names:
		total += int(names[k])
	_log("verify: total Sprite3D=" + str(total) + " unique=" + str(names.size()))
	for k in ["chainsaw.png", "meter.png", "guard_front.png", "elephant_front.png", "hunter.png", "poacher_mask.png", "poacher_ghost.png", "rocks.png", "banana.png", "gate.png", "barrels.png", "sacks.png", "crate_tall.png", "crate_low.png", "log.png", "blood.png", "giant_eye.png", "giant_foot.png"]:
		_log("verify: " + k + " count=" + str(names.get(k, 0)))
	# Sprite yang TIDAK boleh ada lagi (dihapus di v5).
	_log("verify: giant_eye_socket.png count=" + str(names.get("giant_eye_socket.png", 0)) + " (harus 0)")

func _walk_sprites(n: Node, names: Dictionary) -> void:
	if n is Sprite3D:
		var spr := n as Sprite3D
		var texname := str(spr.texture.resource_path).get_file() if spr.texture != null else "?"
		names[texname] = int(names.get(texname, 0)) + 1
		_log("sprite " + texname + " pos=" + str(spr.global_position))
	for c in n.get_children():
		_walk_sprites(c, names)

func _mode_win() -> void:
	GameState.set_generator(true)
	GameState.complete_task("radio")
	GameState.complete_task("log")
	GameState.sanity = 100.0
	GameState.stability = 100.0
	GameState.shift_minutes = 470.0
	var ok := await _wait_until(func() -> bool: return GameState.shift_over, 30.0)
	_log("win: shift_over=" + str(ok) + " sanity=" + str(GameState.sanity) + " stability=" + str(GameState.stability) + " fuel=" + str(GameState.fuel) + " tasks=" + str(GameState.tasks))
	_log("win: success expected=true")

func _mode_lose() -> void:
	GameState.damage_sanity(200.0)
	await _frames(5)
	_log("lose: shift_over=" + str(GameState.shift_over) + " sanity=" + str(GameState.sanity))
	_log("lose: success expected=false")

func _mode_audio() -> void:
	var audio := get_tree().get_first_node_in_group("audio")
	for f in ["wind.wav", "generator_hum.wav", "radio_static.wav", "door_creak.wav", "footstep.wav", "heartbeat.wav", "giant_thud.wav"]:
		var s := load("res://assets/audio/" + f) as AudioStreamWAV
		_log("wav " + f + " loaded=" + str(s != null) + " len=" + (str(s.get_length()) if s else "n/a") + "s rate=" + (str(s.mix_rate) if s else "n/a"))
	_log("audio wind.playing=" + str(audio.wind.playing))
	audio.play_creak()
	await _frames(2)
	_log("audio creak.playing=" + str(audio.creak_player.playing))
	audio.play_static()
	await _frames(2)
	_log("audio static.playing=" + str(audio.static_player.playing))
	audio.play_thud()
	await _frames(2)
	_log("audio thud.playing=" + str(audio.thud_player.playing) + " pitch=" + str(audio.thud_player.pitch_scale) + " stream=" + str(audio.thud_player.stream.resource_path if audio.thud_player.stream else "null") + " (pitch harus 1.0, stream harus giant_thud.wav)")
	GameState.set_generator(true)
	await _frames(2)
	_log("audio hum.playing=" + str(audio.generator_hum.playing))
	GameState.damage_sanity(70.0) # sanity 100 -> 30, heartbeat harus nyala
	await _frames(2)
	_log("audio heartbeat.playing(sanity30)=" + str(audio.heartbeat.playing))
	GameState.restore_sanity(80.0)
	await _frames(2)
	_log("audio heartbeat.playing(sanity100)=" + str(audio.heartbeat.playing))
	_log("audio: sandbox tanpa sound card, status playing di atas adalah bukti jalur kode, bukan suara yang terdengar")

func _mode_touch() -> void:
	# Paksa kontrol sentuh tampil (desktop, tanpa layar sentuh) + screenshot.
	var touch := get_tree().get_first_node_in_group("touch_controls")
	if touch == null:
		_log("touch: TouchControls tidak ditemukan (FAIL)")
		return
	touch.force_show()
	await _frames(5)
	_log("touch: visible=" + str(touch.visible) + " children=" + str(touch.get_child_count()))
	await _set_view(Vector3(0, 0.45, 1.3), 0, 0)
	await _shot("touch")
	# Simulasikan joystick: dorong maju 2 detik lewat touch_move, sampel posisi.
	_player.touch_move = Vector2(0, -1)
	var p0 := _player.global_position
	var f0 := Engine.get_physics_frames()
	for i in range(4):
		await _wait_sec(0.5)
		var cols := ""
		for j in range(_player.get_slide_collision_count()):
			var c: KinematicCollision3D = _player.get_slide_collision(j)
			cols += str(c.get_collider()) + " "
		_log("touch: t=" + str((i + 1) * 0.5) + "s pos=" + str(_player.global_position) + " vel=" + str(_player.velocity) + " floor=" + str(_player.is_on_floor()) + " cols=[" + cols + "] physics_frames=" + str(Engine.get_physics_frames() - f0))
	_player.touch_move = Vector2.ZERO
	var moved := _player.global_position.distance_to(p0)
	# Pintu TERTUTUP menghentikan jalan di 2,85 m (pintu di z=-2,0), jadi
	# ambang > 2,0 m, bukan > 4 m. Yang penting: joystick menggerakkan
	# pemain dengan kecepatan jalan penuh (3,2 m/detik, vel z -3,2).
	_log("touch: joystick maju 2 detik, jarak tempuh=" + str(moved) + " m (harus > 2, berhenti di pintu tertutup)")
	for i in range(_player.get_slide_collision_count()):
		var c: KinematicCollision3D = _player.get_slide_collision(i)
		var col: Object = c.get_collider()
		var col3d := col as Node3D
		_log("touch: tabrakan dengan " + str(col) + " parent=" + str(col.get_parent()) + " body_pos=" + (str(col3d.global_position) if col3d != null else "?") + " di " + str(c.get_position()) + " normal=" + str(c.get_normal()))
	# Simulasikan tombol senter.
	var before: bool = _player.flashlight_on
	_player.toggle_flashlight()
	_log("touch: tombol senter toggle " + str(before) + " -> " + str(_player.flashlight_on))
	await _shot("touch_flashlight")

func _mode_pause() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		_log("pause: HUD tidak ditemukan (FAIL)")
		return
	_log("pause: paused sebelum=" + str(get_tree().paused))
	hud.toggle_pause()
	await _frames(5)
	_log("pause: paused sesudah=" + str(get_tree().paused) + " (harus true)")
	await _shot("pause")
	hud.toggle_pause()
	await _frames(3)
	_log("pause: paused setelah resume=" + str(get_tree().paused) + " (harus false)")

func _mode_save() -> void:
	# Simpan di tengah shift, baca balik, bandingkan isinya.
	GameState.shift_minutes = 123.0
	GameState.sanity = 77.0
	GameState.stability = 88.0
	GameState.fuel = 55.0
	GameState.set_generator(true)
	GameState.complete_task("radio")
	var ok := SaveGame.save()
	_log("save: SaveGame.save()=" + str(ok) + " has_save=" + str(SaveGame.has_save()))
	var d := SaveGame.load_data()
	_log("save: data=" + str(d))
	var done_tasks: Array = d.get("tasks_done", [])
	var match_ok := float(d.get("shift_minutes", -1)) == 123.0 and float(d.get("sanity", -1)) == 77.0 and float(d.get("fuel", -1)) == 55.0 and bool(d.get("generator_on", false)) and "radio" in done_tasks
	_log("save: roundtrip cocok=" + str(match_ok) + " (harus true)")
	SaveGame.clear()
	_log("save: setelah clear has_save=" + str(SaveGame.has_save()) + " (harus false)")

# --- Playtest: pemain manusia (simulasi) -----------------------------------

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
	# Kamera ~1.62 m di atas origin pemain.
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
	# Jalur pemain sungguhan: event aksi E sungguhan ke viewport.
	# Input.action_press() TIDAK memicu _unhandled_input (hanya mengubah
	# state Input singleton), jadi pakai Input.parse_input_event.
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
	_log("playtest: aim " + str(target) + " prompt='" + prompt + "'")
	if expect_in_prompt != "" and not expect_in_prompt in prompt:
		_log("playtest: prompt TIDAK mengandung '" + expect_in_prompt + "' (FAIL langkah ini)")
		return false
	await _press_interact()
	return true

func _mode_playtest() -> void:
	GameState.reset_shift()
	var fails := 0
	_log("playtest: mulai, jam=" + GameState.clock_text() + " pos=" + str(_player.global_position))
	# 1. Buka pintu: jalan ke pintu, E.
	var ok := await _walk_toward(Vector3(0, 0, -1.4), 6.0, 0.5)
	_log("playtest: jalan ke pintu ok=" + str(ok) + " pos=" + str(_player.global_position))
	if not ok:
		fails += 1
	if not await _interact_at(Vector3(0, 1.4, -2.0), "Pintu"):
		fails += 1
	await _wait_sec(1.0)
	_log("playtest: pintu terbuka=" + str(GameState.door_open) + " (harus true)")
	if not GameState.door_open:
		fails += 1
	# 2. Keluar pos, jalan ke generator, nyalakan.
	ok = await _walk_toward(Vector3(0, 0, -4.5), 6.0, 0.8)
	_log("playtest: keluar pos ok=" + str(ok) + " pos=" + str(_player.global_position))
	if not ok:
		fails += 1
	ok = await _walk_toward(Vector3(3.6, 0, -1.2), 8.0, 2.2)
	_log("playtest: jalan ke generator ok=" + str(ok) + " pos=" + str(_player.global_position))
	if not ok:
		fails += 1
	if not await _interact_at(Vector3(3.6, 0.5, -1.2), "Generator"):
		fails += 1
	await _frames(5)
	_log("playtest: generator nyala=" + str(GameState.generator_on) + " tugas generator=" + str(GameState.is_task_done("generator")))
	if not GameState.generator_on:
		fails += 1
	# 3. Kembali masuk pos, DUA kaki supaya tidak nyangkut di sudut
	# tangga/dinding depan: dulu ke depan pintu di luar, baru lurus
	# masuk lewat celah pintu. Jalan diagonal langsung dari generator
	# mentok di sudut tangga (x~1,0, z~-2,65) dan tidak bisa geser.
	ok = await _walk_toward(Vector3(0, 0, -4.0), 8.0, 0.5)
	_log("playtest: ke depan pintu ok=" + str(ok) + " pos=" + str(_player.global_position))
	if not ok:
		fails += 1
	ok = await _walk_toward(Vector3(0, 0, 1.3), 8.0, 0.5)
	_log("playtest: kembali ke pos ok=" + str(ok) + " pos=" + str(_player.global_position))
	if not ok:
		fails += 1
	# 4. Radio, lalu buku jaga, lalu lentera (tugas berurutan).
	if not await _interact_at(Vector3(-1.55, 1.27, 1.35), "Radio"):
		fails += 1
	_log("playtest: tugas radio=" + str(GameState.is_task_done("radio")))
	if not GameState.is_task_done("radio"):
		fails += 1
	if not await _interact_at(Vector3(-1.02, 1.14, 1.28), "Buku"):
		fails += 1
	_log("playtest: tugas log=" + str(GameState.is_task_done("log")) + " sanity=" + str(GameState.sanity))
	if not GameState.is_task_done("log"):
		fails += 1
	var lantern := get_node_or_null("Main/Lantern")
	var lantern_before: bool = lantern.is_on if lantern != null else false
	if not await _interact_at(Vector3(1.85, 1.06, 1.5), "Lentera"):
		fails += 1
	var lantern_after: bool = lantern.is_on if lantern != null else false
	_log("playtest: lentera toggle " + str(lantern_before) + " -> " + str(lantern_after) + " (harus berubah)")
	if lantern_before == lantern_after:
		fails += 1
	# Nyalakan lagi supaya pos tidak gelap untuk sisa shift.
	if not lantern_after:
		await _interact_at(Vector3(1.85, 1.06, 1.5), "Lentera")
	# 5. Tutup pintu, lalu event pemburu 01:30 (lewati dengan pintu tertutup).
	# Jalan dulu ke dekat pintu: raycast interaksi cuma 3,4 m, dari
	# lentera (1,85, 1,5) pintu tidak terjangkau.
	ok = await _walk_toward(Vector3(0, 0, -1.0), 6.0, 0.5)
	_log("playtest: jalan ke pintu (tutup) ok=" + str(ok) + " pos=" + str(_player.global_position))
	if not ok:
		fails += 1
	# Pintu yang TERBUKA tidak lagi di celah pintu: panelnya mengayun
	# ke samping (pivot -102 derajat, panel di sekitar (-0.6, 1.4, -1.5)).
	# Pemain manusia menatap panel yang terbuka itu untuk menutupnya;
	# membidik celah kosong (0, 1.4, -2.0) tidak mengenai apa-apa.
	if not await _interact_at(Vector3(-0.6, 1.4, -1.5), "Pintu"):
		fails += 1
	await _wait_sec(1.0)
	_log("playtest: pintu tertutup=" + str(not GameState.door_open) + " (harus true)")
	if GameState.door_open:
		fails += 1
	GameState.sanity = 100.0
	GameState.shift_minutes = 209.0
	var hunter := get_tree().get_first_node_in_group("hunter_event")
	ok = await _wait_until(func() -> bool: return hunter._active, 6.0)
	_log("playtest: event pemburu mulai=" + str(ok))
	if not ok:
		fails += 1
	ok = await _wait_until(func() -> bool: return GameState.is_task_done("hunter"), 20.0)
	_log("playtest: tugas hunter selesai (pintu tertutup 12 dtk)=" + str(ok) + " sanity=" + str(GameState.sanity))
	if not ok:
		fails += 1
	await _shot("playtest_hunter_done")
	# 6. Kaki Giant 03:30, lihat lewat jendela.
	GameState.sanity = 100.0
	GameState.shift_minutes = 329.0
	await _set_view(Vector3(0, 0.45, 0.2), 180, 0)
	var giant := get_tree().get_first_node_in_group("giant_event")
	ok = await _wait_until(func() -> bool: return giant.active_event == "foot", 6.0)
	_log("playtest: event kaki mulai=" + str(ok))
	if not ok:
		fails += 1
	await _wait_sec(4.0)
	await _shot("playtest_foot")
	ok = await _wait_until(func() -> bool: return giant.active_event == "", 12.0)
	_log("playtest: event kaki selesai=" + str(ok) + " sanity=" + str(GameState.sanity))
	if not ok:
		fails += 1
	# 7. Mata Giant 04:45.
	GameState.sanity = 100.0
	GameState.shift_minutes = 404.0
	ok = await _wait_until(func() -> bool: return giant.active_event == "eye", 6.0)
	_log("playtest: event mata mulai=" + str(ok))
	if not ok:
		fails += 1
	await _wait_sec(3.0)
	await _shot("playtest_eye")
	ok = await _wait_until(func() -> bool: return giant.active_event == "", 14.0)
	_log("playtest: event mata selesai=" + str(ok) + " sanity=" + str(GameState.sanity))
	if not ok:
		fails += 1
	# 8. Bertahan sampai 06:00.
	GameState.sanity = 100.0
	GameState.stability = 100.0
	GameState.set_generator(true)
	GameState.shift_minutes = 470.0
	ok = await _wait_until(func() -> bool: return GameState.shift_over, 30.0)
	_log("playtest: shift_over=" + str(ok) + " sanity=" + str(GameState.sanity) + " stability=" + str(GameState.stability) + " tugas=" + str(GameState.tasks))
	if not ok:
		fails += 1
	_log("playtest: HASIL fails=" + str(fails) + " -> " + ("PASS" if fails == 0 else "FAIL"))
