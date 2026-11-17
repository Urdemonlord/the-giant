extends StaticBody3D
## Lentera di dalam pos. Interaksi: nyala/matikan OmniLight.
## Pos yang terang menahan Stability; gelap menggerusnya (diurus Main).

var is_on := true
var dim_factor := 1.0 # v22 menu: lentera diredupkan (0.6) supaya
# cahaya hangatnya tidak membakar tepi jauh buku jaga di menu.
# Default 1.0 = permainan tidak berubah.
var _light: OmniLight3D
var _flicker_t := 0.0

func _process(delta: float) -> void:
	# Nyala lentera berdenyut halus seperti api, bukan lampu neon.
	if not is_on or _light == null:
		return
	_flicker_t -= delta
	if _flicker_t <= 0.0:
		_flicker_t = 0.12
		_light.light_energy = 2.0 * dim_factor + randf_range(-0.18, 0.18) * dim_factor

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	_apply()

func _build_visual() -> void:
	# Tanpa kotak hitam: lentera adalah sprite dari sheet + cahaya.
	# Kotak gelap di versi lama yang bikin lentera kelihatan kotak hitam.
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	# v11: hitbox ikut sprite yang diangkat: 0,6 -> 0,65, tengah +0,03.
	col.size = Vector3(0.45, 0.65, 0.45)
	shape.shape = col
	shape.position = Vector3(0, 0.03, 0)
	add_child(shape)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 0.25, 0)
	_light.light_color = Color(1.0, 0.72, 0.4)
	_light.light_energy = 2.0 * dim_factor
	_light.omni_range = 9.0
	add_child(_light)
	var spr := SpriteRegistry.billboard("lantern", 0.0016)
	if spr != null:
		# v11: alas sprite di permukaan meja (1,11), bukan terkubur
		# 0,039 m: tengah 1,359 -> lokal y 0,089 (margin bawah 1 px).
		spr.position = Vector3(0, 0.089, -0.18)
		add_child(spr)

func get_prompt() -> String:
	return "Lentera - Tekan E untuk %s" % ("matikan" if is_on else "nyalakan")

func interact() -> void:
	is_on = not is_on
	_apply()

func _apply() -> void:
	if _light:
		_light.visible = is_on
