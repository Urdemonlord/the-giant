extends StaticBody3D
## Generator di samping pos. Interaksi: nyala/matikan.
## Bahan bakar dikuras oleh Main selama menyala.

@export var sprite_name := "generator"

var _light: OmniLight3D
## v14 (generator sekarat): lampu generator ikut berkedip saat bahan
## bakar menipis, seirama lampu teras (dadu sendiri, bukan sinkron).
var _flicker_slice := 0.0
var _flicker_mult := 1.0

func _process(delta: float) -> void:
	if _light == null or not GameState.generator_on:
		return
	if GameState.fuel < Balance.GEN_FLICKER_FUEL:
		_flicker_slice -= delta
		if _flicker_slice <= 0.0:
			_flicker_slice = 0.15
			var p := 0.30 if GameState.fuel < Balance.GEN_SPUTTER_FUEL else 0.15
			_flicker_mult = randf_range(0.3, 0.6) if randf() < p else 1.0
		_light.light_energy = 0.7 * _flicker_mult
	else:
		_light.light_energy = 0.7

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	GameState.generator_changed.connect(_on_generator_changed)
	_on_generator_changed(GameState.generator_on, GameState.fuel)

func _build_visual() -> void:
	# Tanpa kotak merah: generator adalah sprite dari sheet.
	# Alas gelap tipis saja supaya sprite tidak melayang.
	var base := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.1, 0.14, 0.6)
	base.mesh = bb
	base.position.y = 0.07
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.12, 0.1, 0.09)
	base.material_override = bmat
	add_child(base)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(1.3, 1.0, 0.85)
	shape.shape = col
	shape.position.y = 0.5
	add_child(shape)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 1.1, 0)
	_light.light_color = Color(1.0, 0.75, 0.45)
	_light.light_energy = 0.0
	_light.omni_range = 5.0
	add_child(_light)
	_add_sprite()

func _add_sprite() -> void:
	var spr := SpriteRegistry.billboard(sprite_name, 0.0035, Color(1, 1, 1, 0.92))
	if spr == null:
		return
	spr.position = Vector3(0, 0.55, -0.45)
	add_child(spr)

func get_prompt() -> String:
	if GameState.fuel <= 0.0:
		return "Generator - bahan bakar habis"
	return "Generator - Tekan E untuk %s" % ("matikan" if GameState.generator_on else "nyalakan")

func interact() -> void:
	if GameState.fuel <= 0.0 and not GameState.generator_on:
		GameState.show_message("Tidak ada bahan bakar.")
		return
	GameState.set_generator(not GameState.generator_on)
	GameState.show_message("Generator menyala. Lampu pos hidup." if GameState.generator_on else "Generator mati. Gelap lagi.")

func _on_generator_changed(is_on: bool, _fuel: float) -> void:
	if _light:
		_light.light_energy = 0.7 if is_on else 0.0
