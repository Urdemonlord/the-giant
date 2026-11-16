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
	_apply_night_curve(delta)

## v14 (tension pacing): malam makin dalam sampai ~02:00, bertahan
## gelap sampai ~04:00, lalu fajar mengintip dari 05:00. Bulan, ambient,
## dan fog volumetrik di-lerp pelan (konstanta ~2 detik) supaya tidak
## ada lompatan yang kelihatan; semua angka di Balance, semua kecil.
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
	moon.light_energy = lerpf(moon.light_energy,
		0.75 - 0.20 * dark + 0.10 * dawn, k)
	env.ambient_light_energy = lerpf(env.ambient_light_energy,
		0.65 - 0.15 * dark + 0.05 * dawn, k)
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
			# v11: papan menghadap jalan (sisi +z, dari arah pos): dulu
			# -0,12 di sisi jauh, ketutup papan dari arah jalan.
			# v14: wajah papan unshaded + tint redup (0.55) supaya
			# tulisannya kebaca samar di gelap tanpa senter — dengan
			# senter tetap terbaca seperti dulu (shots16 sign_park).
			spr.shaded = false
			spr.modulate = Color(0.55, 0.58, 0.55, 1.0)
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
		var depth_k := clampf((r - 9.0) / (26.0 - 9.0), 0.0, 1.0)
		var puff_alpha := lerpf(0.38, 0.26, depth_k)
		_billboard(forest, "fog_puff", Vector3(fp.x, _rng.randf_range(0.4, 1.4), fp.z), _rng.randf_range(0.015, 0.024), Color(0.62, 0.68, 0.58, puff_alpha))
	# Gumpalan tetap di mid-ground (10-12 m), supaya selalu ada
	# struktur kabut yang kebaca dari pos dan gerbang. Ronde 1 pakai
	# tint GELAP untuk yang selatan — lewat jendela cuma jadi noda
	# samar di kabut (diukur: std jendela 14,1 vs 15,9 baseline) dan
	# di luar berisiko kelihatan gumpalan hitam; dikembalikan pucat
	# seperti gumpalan lain. Jendela belakang tetap dinding kabut:
	# pada 0,07/m, billboard apa pun di 10-14 m cuma ~40% kebaca
	# dengan latar kabut sewarna + desaturasi VHS. Batas jujur v14.
	for fp in [Vector3(-5.0, 0.8, 11.0), Vector3(1.5, 0.6, 12.0), Vector3(6.0, 0.9, 10.0),
			Vector3(-7.0, 0.8, -11.0), Vector3(8.0, 1.0, -12.0)]:
		_billboard(forest, "fog_puff", fp, 0.022, Color(0.62, 0.68, 0.58, 0.34))
	# Ground fog: lapisan kabut rendah merayap di permukaan tanah,
	# rapat di sekitar pos + jalan + gerbang, supaya tanah tidak bersih.
	for i in range(Balance.GROUND_FOG_COUNT):
		var ga := _rng.randf_range(0.0, TAU)
		var gr := _rng.randf_range(6.0, 13.0)
		var gp := Vector3(cos(ga) * gr, 0, sin(ga) * gr)
		if absf(gp.x) < 3.5 and gp.z > -16.0 and gp.z < 2.0:
			continue
		var gdepth_k := clampf((gr - 6.0) / (13.0 - 6.0), 0.0, 1.0)
		var ground_alpha := lerpf(0.42, 0.32, gdepth_k)
		_billboard(forest, "fog_puff", Vector3(gp.x, _rng.randf_range(0.15, 0.45), gp.z), _rng.randf_range(0.018, 0.026), Color(0.62, 0.68, 0.58, ground_alpha))

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
	spr.modulate = Color(0.8, 0.85, 0.85, 1.0)
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
	var spr := SpriteRegistry.billboard(sprite_name, pixel_size, Color(0.85, 0.85, 0.85, 0.95))
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
	spr.modulate = Color(1.6, 1.0, 1.0, 1.0) if sprite_name == "blood" else Color(0.85, 0.85, 0.85, 0.95)
	parent.add_child(spr)
