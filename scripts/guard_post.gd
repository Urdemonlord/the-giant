extends Node3D
## Membangun pos jaga secara prosedural: lantai panggung, 4 dinding
## (celah pintu di depan, celah jendela di belakang/samping), atap,
## meja, kursi, dan pintu berengsel yang bisa dibuka.
## Setting WAJIB: ini pos jaga, bukan rumah tinggal.

const DoorScript := preload("res://scripts/interactables/door.gd")

# Ukuran pos dibaca dari LevelData (satu sumber kebenaran level).
const W := LevelData.POST_WIDTH # lebar (x)
const D := LevelData.POST_DEPTH # kedalaman (z)
const H := LevelData.POST_WALL_HEIGHT # tinggi dinding
const FLOOR_Y := LevelData.POST_FLOOR_Y # lantai panggung

var door_pivot: Node3D
var _porch: OmniLight3D
## v14 (generator sekarat): lampu teras berkedip saat bahan bakar
## menipis — redup singkat, bukan strobo. State dadu flicker di sini.
var _flicker_slice := 0.0
var _flicker_mult := 1.0

var _wood: StandardMaterial3D
var _wood_dark: StandardMaterial3D
var _roof_mat: StandardMaterial3D
var _door_mat: StandardMaterial3D

func _ready() -> void:
	_wood = _wood_mat(Color(0.85, 0.72, 0.55), Vector3(3.0, 1.5, 1.0))
	_wood_dark = _wood_mat(Color(0.55, 0.45, 0.33), Vector3(3.0, 3.0, 1.0))
	_roof_mat = _wood_mat(Color(0.5, 0.4, 0.3), Vector3(3.0, 3.0, 1.0))
	_door_mat = _tex_mat(SpriteRegistry.path_for("door"), Color(1, 1, 1))
	_build_floor()
	_build_walls()
	_build_roof()
	_build_door()
	_build_furniture()
	# Lampu teras depan: ikut generator, supaya dinding depan tidak
	# hitam pekat di malam hari.
	_porch = OmniLight3D.new()
	_porch.position = LevelData.POST_PORCH_LIGHT_POS
	_porch.light_color = Color(1.0, 0.72, 0.42)
	_porch.light_energy = 0.0
	_porch.omni_range = 7.0
	add_child(_porch)

func _process(delta: float) -> void:
	if _porch:
		var target := 0.9 if GameState.generator_on else 0.0
		# v14: generator sekarat = lampu teras ikut tersendat. Tiap
		# irisan 0,15 dtk dadu ulang: biasanya 1,0, kadang redup ke
		# 0,3-0,6. Makin parah saat bahan bakar < 10. Redup, bukan
		# kilat terang, jadi aman dari flash (<= ~2 redup/detik).
		if GameState.generator_on and GameState.fuel < Balance.GEN_FLICKER_FUEL:
			_flicker_slice -= delta
			if _flicker_slice <= 0.0:
				_flicker_slice = 0.15
				var p := 0.30 if GameState.fuel < Balance.GEN_SPUTTER_FUEL else 0.15
				_flicker_mult = randf_range(0.3, 0.6) if randf() < p else 1.0
			target *= _flicker_mult
		else:
			_flicker_mult = 1.0
		_porch.light_energy = lerpf(_porch.light_energy, target, 0.25)

# Kayu dari sprite sheet Arya, bukan warna datar: tekstur papan door.png
# dipakai sebagai albedo, diulang lewat uv1_scale supaya papan tidak melar.
func _wood_mat(tint: Color, uv_scale: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex := load("res://assets/textures/wood_planks.png") as Texture2D
	if tex != null:
		m.albedo_texture = tex
		m.uv1_scale = uv_scale
	m.albedo_color = tint
	m.roughness = 0.95
	return m

func _tex_mat(path: String, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex := load(path) as Texture2D
	if tex != null:
		m.albedo_texture = tex
	m.albedo_color = tint
	m.roughness = 0.95
	return m

func _box(parent: Node, size: Vector3, pos: Vector3, mat: Material, collide := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mesh.mesh = b
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		var shape := CollisionShape3D.new()
		var col := BoxShape3D.new()
		col.size = size
		shape.shape = col
		body.add_child(shape)
		parent.add_child(body)
	return mesh

func _build_floor() -> void:
	_box(self, Vector3(W + 0.6, 0.3, D + 0.6), Vector3(0, FLOOR_Y - 0.15, 0), _wood_dark)
	# 4 tiang panggung
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(self, Vector3(0.22, FLOOR_Y, 0.22), Vector3(sx * (W * 0.5 - 0.2), FLOOR_Y * 0.5 - 0.15, sz * (D * 0.5 - 0.2)), _wood_dark, false)
	# Tangga kecil di depan pintu: VISUAL saja (tanpa collision).
	# Playtest v10 membuktikan anak tangga setinggi 0,12 m memblokir
	# pemain yang jalan masuk: CharacterBody3D tidak bisa naik anak
	# tangga tanpa lompat (dan game ini tidak punya lompat), jadi pemain
	# bisa keluar pos tapi TIDAK BISA kembali masuk. Yang bisa
	# dilewati adalah ramp miring di bawah ini (satu-satunya collider).
	_box(self, Vector3(1.2, 0.12, 0.5), Vector3(0, 0.2, -D * 0.5 - 0.45), _wood_dark, false)
	_box(self, Vector3(1.2, 0.12, 0.5), Vector3(0, 0.06, -D * 0.5 - 0.8), _wood_dark, false)
	# Ramp masuk (tidak terlihat): permukaan dari tanah (z=-3.5, y=0)
	# naik ke lantai (z=-2.3, y=FLOOR_Y), kemiringan ~16 derajat,
	# masih di bawah floor_max_angle 45 derajat.
	var ramp := StaticBody3D.new()
	ramp.position = Vector3(0, FLOOR_Y * 0.5 - 0.038, -D * 0.5 - 0.9)
	ramp.rotation.x = -atan2(FLOOR_Y, 1.2)
	var rshape := CollisionShape3D.new()
	var rbox := BoxShape3D.new()
	rbox.size = Vector3(1.2, 0.08, 1.25)
	rshape.shape = rbox
	ramp.add_child(rshape)
	add_child(ramp)

func _build_walls() -> void:
	var t := 0.12
	var wy := FLOOR_Y + H * 0.5
	var front_z := -D * 0.5
	var back_z := D * 0.5
	# Dinding depan (z = -D/2): celah pintu lebar POST_DOOR_WIDTH di tengah
	var seg := (W - LevelData.POST_DOOR_WIDTH) * 0.5
	_box(self, Vector3(seg, H, t), Vector3(-(0.5 + seg * 0.5), wy, front_z), _wood)
	_box(self, Vector3(seg, H, t), Vector3(0.5 + seg * 0.5, wy, front_z), _wood)
	_box(self, Vector3(LevelData.POST_DOOR_WIDTH, H - LevelData.POST_DOOR_HEIGHT, t), Vector3(0, FLOOR_Y + LevelData.POST_DOOR_HEIGHT + (H - LevelData.POST_DOOR_HEIGHT) * 0.5, front_z), _wood) # kusen atas pintu
	# Dinding belakang: celah jendela POST_WINDOW_WIDTH di tengah
	var bseg := (W - LevelData.POST_WINDOW_WIDTH) * 0.5
	_box(self, Vector3(bseg, H, t), Vector3(-(0.7 + bseg * 0.5), wy, back_z), _wood)
	_box(self, Vector3(bseg, H, t), Vector3(0.7 + bseg * 0.5, wy, back_z), _wood)
	_box(self, Vector3(LevelData.POST_WINDOW_WIDTH, LevelData.POST_WINDOW_SILL_Y, t), Vector3(0, FLOOR_Y + LevelData.POST_WINDOW_SILL_Y * 0.5, back_z), _wood) # bawah jendela
	_box(self, Vector3(LevelData.POST_WINDOW_WIDTH, H - LevelData.POST_WINDOW_TOP_Y, t), Vector3(0, FLOOR_Y + LevelData.POST_WINDOW_TOP_Y + (H - LevelData.POST_WINDOW_TOP_Y) * 0.5, back_z), _wood) # atas jendela
	# Dinding samping penuh
	_box(self, Vector3(t, H, D), Vector3(-W * 0.5, wy, 0), _wood)
	_box(self, Vector3(t, H, D), Vector3(W * 0.5, wy, 0), _wood)

func _build_roof() -> void:
	_box(self, Vector3(W + 1.0, 0.1, D + 1.0), Vector3(0, FLOOR_Y + H + 0.18, 0), _roof_mat, false)
	_box(self, Vector3(W + 0.4, 0.14, 0.18), Vector3(0, FLOOR_Y + H + 0.05, 0), _wood_dark, false)

func _build_door() -> void:
	door_pivot = Node3D.new()
	door_pivot.position = Vector3(-0.5, FLOOR_Y, -D * 0.5)
	add_child(door_pivot)
	var door := StaticBody3D.new()
	door.set_script(DoorScript)
	door.position = Vector3(0.5, 1.025, 0)
	door_pivot.add_child(door)
	var mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(LevelData.POST_DOOR_WIDTH, LevelData.POST_DOOR_HEIGHT, 0.07)
	mesh.mesh = b
	# Pintu pakai gambar pintu dari sheet: papan kayu + engsel + lubang intip.
	mesh.material_override = _door_mat
	door.add_child(mesh)
	# Lubang intip: kotak gelap kecil setinggi mata (detail No I'm Not a Human)
	var peep := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.16, 0.1, 0.09)
	peep.mesh = pb
	peep.position = Vector3(0, 0.45, 0)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.02, 0.02, 0.02)
	peep.material_override = pm
	door.add_child(peep)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(LevelData.POST_DOOR_WIDTH + 0.05, LevelData.POST_DOOR_HEIGHT + 0.05, 0.2)
	shape.shape = col
	door.add_child(shape)

func _build_furniture() -> void:
	# Meja jaga di sisi kiri belakang. v10: lebar 1,7 -> 2,2 (LevelData),
	# 6 benda di grid 3x2, kaki di ujung (±1,0) supaya tidak goyah.
	_box(self, Vector3(LevelData.POST_DESK_WIDTH, 0.08, LevelData.POST_DESK_DEPTH), Vector3(LevelData.POST_DESK_POS.x, FLOOR_Y + 0.72, LevelData.POST_DESK_POS.z), _wood_dark)
	for sx in [-1.0, 1.0]:
		for sz in [-0.3, 0.3]:
			_box(self, Vector3(0.08, 0.72, 0.08), Vector3(LevelData.POST_DESK_POS.x + sx, FLOOR_Y + 0.36, LevelData.POST_DESK_POS.z + sz), _wood_dark, false)
	# Kursi (tetap di tengah meja, x -1,30 sudah pas sejak awal).
	_box(self, Vector3(0.45, 0.06, 0.45), Vector3(-1.3, FLOOR_Y + 0.45, 0.75), _wood_dark)
	_box(self, Vector3(0.45, 0.55, 0.06), Vector3(-1.3, FLOOR_Y + 0.75, 0.53), _wood_dark, false)
	# Peti kayu di sudut kanan (sekarang kosong, lentera pindah ke meja v10).
	_box(self, Vector3(0.7, 0.5, 0.7), Vector3(1.85, FLOOR_Y + 0.25, 1.5), _wood)
	# Meter getar di atas meja jaga (v9): sensor yang mendeteksi langkah
	# Giant. v10: pindah ke tengah baris belakang meja, di antara radio
	# dan lentera, tidak lagi setengah ketutup buku jaga.
	var mspr := SpriteRegistry.billboard("meter", 0.45 / 265.0)
	if mspr != null:
		mspr.position = LevelData.METER_POS
		add_child(mspr)
