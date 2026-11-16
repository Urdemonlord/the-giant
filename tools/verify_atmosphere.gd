extends Node
## Cek numerik perubahan suasana v14 (bukan screenshot): bus audio,
## jangkrik jalan, kedip lampu saat bahan bakar rendah, trauma shake
## meluruh, FOV menyempit saat Sanity rendah, kurva malam, dentum jauh.
## Jalankan: Godot --headless --path . res://tools/verify_atmosphere.tscn
## (scene, bukan --script: --script tidak memuat autoload GameState.)
## Keluar 0 kalau semua cek lolos, 1 kalau ada yang gagal.
## (Shader VHS + tampilan tidak bisa dicek headless — itu tugas rig
## mode=shots18 dengan screenshot.)

var _fails := 0
var _main: Node = null

func _ready() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	_run()

func _check(label: String, ok: bool, detail := "") -> void:
	print("[ATMO] " + ("PASS " if ok else "FAIL ") + label + " " + detail)
	if not ok:
		_fails += 1

func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame

func _wait_sec(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _run() -> void:
	# add_child di _ready langsung gagal ("parent busy setting up
	# children"): tunggu 2 frame dulu sampai scene ini selesai setup.
	await _frames(2)
	# main._ready menampilkan intro (dan pause tree) kalau bukan rig
	# run — lewati intro supaya _process semua node jalan.
	GameState.skip_intro = true
	_main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await _frames(60)
	# 1. Bus audio (audio-design): layout harus ke-load.
	_check("bus Ambience ada", AudioServer.get_bus_index("Ambience") >= 0)
	_check("bus SFX ada", AudioServer.get_bus_index("SFX") >= 0)
	_check("bus Voice ada", AudioServer.get_bus_index("Voice") >= 0)
	# 2. Ambience jalan di bus yang benar.
	var audio: Node = get_tree().get_first_node_in_group("audio")
	_check("audio node ada", audio != null)
	if audio != null:
		_check("wind jalan", audio.get("wind") != null and audio.get("wind").playing)
		_check("crickets jalan", audio.get("crickets") != null and audio.get("crickets").playing)
		_check("crickets di bus Ambience", audio.get("crickets") != null and audio.get("crickets").bus == "Ambience")
		_check("thud di bus SFX", audio.get("thud_player") != null and audio.get("thud_player").bus == "SFX")
		_check("voice di bus Voice", audio.get("voice_players").size() > 0 and audio.get("voice_players")[0].bus == "Voice")
	# 2b. Dentum jauh: dijadwalkan lalu bunyi di jendela jam yang benar.
	# HARUS sebelum bagian kurva malam: set shift_minutes=240 di sana
	# memicu event pemburu (210) yang masih aktif dan memblokir
	# dentum jauh (sengaja: dentum tidak boleh menumpuk event).
	GameState.shift_minutes = 120.0
	if audio != null:
		audio.set("_next_distant", 0.05)
	await _wait_sec(1.0)
	_check("dentum jauh bunyi", audio != null and audio.get("distant_thud") != null and audio.get("distant_thud").playing)
	# 3. Kedip lampu saat bahan bakar rendah (5 dtk sampling).
	GameState.fuel = 15.0
	GameState.set_generator(true)
	await _wait_sec(1.0)
	var guard_post: Node = _main.get_node_or_null("GuardPost")
	var porch: OmniLight3D = guard_post.get("_porch") if guard_post != null else null
	var generator: Node = _main.get_node_or_null("Generator")
	var gen_light: OmniLight3D = generator.get("_light") if generator != null else null
	_check("porch light ketemu", porch != null)
	_check("generator light ketemu", gen_light != null)
	var porch_min := 99.0
	var porch_max := -1.0
	var gen_min := 99.0
	var gen_max := -1.0
	for i in range(50):
		await _wait_sec(0.1)
		if porch != null:
			porch_min = minf(porch_min, porch.light_energy)
			porch_max = maxf(porch_max, porch.light_energy)
		if gen_light != null:
			gen_min = minf(gen_min, gen_light.light_energy)
			gen_max = maxf(gen_max, gen_light.light_energy)
	_check("porch kedip (min<0.6, max>0.8)", porch_min < 0.6 and porch_max > 0.8,
		"min=%.2f max=%.2f" % [porch_min, porch_max])
	_check("generator kedip (min<0.5, max>0.6)", gen_min < 0.5 and gen_max > 0.6,
		"min=%.2f max=%.2f" % [gen_min, gen_max])
	GameState.set_generator(false)
	GameState.fuel = 100.0
	# 4. Trauma shake meluruh (game-feel), bukan acak per frame.
	var player: Node = get_tree().get_first_node_in_group("player")
	_check("player ketemu", player != null)
	if player != null:
		player.shake(1.0)
		await _wait_sec(0.5)
		var trauma_mid: float = player.trauma
		_check("trauma meluruh (0.5 dtk -> ~0.4)", trauma_mid > 0.2 and trauma_mid < 0.6,
			"trauma=%.2f" % trauma_mid)
		await _wait_sec(1.5)
		_check("trauma habis (2 dtk -> 0)", player.trauma <= 0.001,
			"trauma=%.3f" % player.trauma)
		# 5. FOV menyempit saat Sanity rendah.
		GameState.sanity = 20.0
		await _wait_sec(1.0)
		_check("FOV menyempit saat Sanity 20", player.camera.fov < 71.5,
			"fov=%.2f" % player.camera.fov)
		GameState.sanity = 100.0
	# 6. Kurva malam: bulan redup jam 02:00, fog menebal sedikit.
	GameState.shift_minutes = 240.0
	await _wait_sec(3.0)
	var moon := _main.get_node_or_null("MoonLight") as DirectionalLight3D
	_check("bulan redup jam 02:00", moon != null and moon.light_energy < 0.65,
		"moon=%.2f" % (moon.light_energy if moon != null else -1.0))
	var env_node := _main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var vol := -1.0
	if env_node != null and env_node.environment != null:
		vol = env_node.environment.volumetric_fog_density
	_check("fog volumetrik menebal jam 02:00", vol > 0.033, "vol=%.4f" % vol)
	print("[ATMO] HASIL: " + ("PASS semua cek" if _fails == 0 else "FAIL (%d cek gagal)" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)
