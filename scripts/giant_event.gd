extends Node
## Event THE GIANT: ia tidak pernah tampil utuh (sesuai storyboard).
## Panel 04 - kaki raksasa lewat di jendela belakang (~03:30).
## Panel 07 - mata raksasa menempel di kaca jendela (~04:45).
## Keduanya sprite dari sheet Arya (giant_foot / giant_eye), di kabut,
## gelap, hanya sebagian yang terlihat lewat celah jendela.
## (elephant_front dipakai terpisah sebagai siluet jauh di main.gd.)

const TRIGGER_FOOT_MINUTE := Balance.GIANT_FOOT_TRIGGER_MINUTE
const TRIGGER_EYE_MINUTE := Balance.GIANT_EYE_TRIGGER_MINUTE
const FOOT_DURATION := Balance.GIANT_FOOT_DURATION
const EYE_DURATION := Balance.GIANT_EYE_DURATION

var active_event := "" # "", "foot", "eye" - dibaca test rig
var _foot_done := false
var _eye_done := false
var _active := false
var _elapsed := 0.0
var _node: Node3D = null
var _spr: Sprite3D = null
var _thud_done := false
var _dust: Sprite3D = null # kepulan debu saat kaki menghentak
var _dust_age := 0.0

func _ready() -> void:
	add_to_group("giant_event")

func _process(delta: float) -> void:
	if GameState.shift_over:
		return
	if not _foot_done and GameState.shift_minutes >= TRIGGER_FOOT_MINUTE:
		_start_foot()
	elif not _eye_done and GameState.shift_minutes >= TRIGGER_EYE_MINUTE:
		_start_eye()
	# Debu memudar sendiri, juga setelah event selesai.
	if _dust != null:
		_dust_age += delta
		var k := clampf(_dust_age / 1.6, 0.0, 1.0)
		_dust.modulate.a = 0.55 * (1.0 - k)
		_dust.position.y = 0.35 + _dust_age * 0.35
		_dust.scale = Vector3.ONE * (1.0 + _dust_age * 0.5)
		if _dust_age >= 1.6:
			_dust.queue_free()
			_dust = null
	if not _active:
		return
	_elapsed += delta
	var player := get_tree().get_first_node_in_group("player")
	if active_event == "foot":
		# Kaki melangkah pelan dari kiri ke kanan, lewat jendela belakang.
		var t := clampf(_elapsed / FOOT_DURATION, 0.0, 1.0)
		_node.position.x = lerpf(LevelData.GIANT_FOOT_START.x, LevelData.GIANT_FOOT_END_X, t)
		_node.position.y = LevelData.GIANT_FOOT_START.y + sin(t * PI) * 0.12 # sedikit terangkat saat melangkah
		if player != null and player.has_method("look_dot_towards"):
			if float(player.look_dot_towards(_node.global_position)) > Balance.GIANT_FOOT_LOOK_DOT:
				GameState.damage_sanity(Balance.GIANT_FOOT_LOOK_DRAIN * delta)
		if player != null and player.has_method("shake"):
			player.shake(Balance.GIANT_FOOT_SHAKE)
		if not _thud_done and t >= 0.5:
			_thud_done = true
			_play_thud()
		if _elapsed >= FOOT_DURATION:
			_end_event()
			GameState.show_message("Getarannya berhenti. Ia sudah lewat. Untuk malam ini.")
	elif active_event == "eye":
		# Mata menempel di kaca, bergeser sedikit, tidak berkedip.
		if _node != null:
			_node.position.x = sin(_elapsed * 0.6) * 0.08
		if player != null and player.has_method("look_dot_towards"):
			if float(player.look_dot_towards(_node.global_position)) > Balance.GIANT_EYE_LOOK_DOT:
				GameState.damage_sanity(Balance.GIANT_EYE_LOOK_DRAIN * delta)
				if player.has_method("shake"):
					player.shake(Balance.GIANT_EYE_SHAKE)
		if _elapsed >= EYE_DURATION:
			_end_event()
			GameState.damage_sanity(Balance.GIANT_EYE_END_DRAIN)
			GameState.show_message("Mata itu mundur ke kabut. Kamu masih bisa mendengar napasnya.")

func _start_foot() -> void:
	_foot_done = true
	_active = true
	active_event = "foot"
	_elapsed = 0.0
	_thud_done = false
	_spawn("giant_foot", LevelData.GIANT_FOOT_START, LevelData.GIANT_FOOT_HEIGHT_M, Color(0.85, 0.85, 0.9, 1.0))
	_play_thud()
	GameState.show_message("Tanah bergetar. Sesuatu yang sangat besar lewat di belakang pos.")
	GameState.damage_sanity(Balance.GIANT_FOOT_START_DRAIN)

func _start_eye() -> void:
	_eye_done = true
	_active = true
	active_event = "eye"
	_elapsed = 0.0
	# Mata v9 ronde 2: crop 52x50 px dengan rongga tepat di tengah
	# (blotch kedua di luar crop), kulit diterangkan + kontras naik,
	# catchlight kecil DI bola mata asli (sheet ~(213,97), dicek
	# dengan marker), sprite UNSHADED supaya tidak gelap (billboard
	# menghadap menjauhi bulan; ronde 1 shaded + lampu 1,5 tetap
	# tidak kebaca di screenshot). Batas jujur: mata asli di sheet
	# cuma ~15 px, jadi tetap soft kalau dilihat dekat; yang
	# diperbaiki adalah keterbacaannya, bukan detailnya.
	_spawn("giant_eye", LevelData.GIANT_EYE_POS, LevelData.GIANT_EYE_HEIGHT_M, Color(1.0, 0.95, 0.85, 1.0))
	if _spr != null:
		_spr.shaded = false # mata menempel di kaca, diterangi dari dalam pos
		# HDR modulate: tonemapper FILMIC proyek (main.tscn) + kabut +
		# shader VHS menggelapkan tekstur sampai ~39% di screenshot
		# (diukur: tekstur mean 103 -> window mean 40). Modulate 2,2x
		# mengangkatnya kembali ke keterbacaan tanpa mengubah grade
		# global game. Catchlight ikut jadi putih HDR yang bertahan.
		_spr.modulate = Color(2.2, 2.1, 1.9, 1.0)
	# Kilau hangat di kaca supaya mata kebaca di gelap.
	var glint := OmniLight3D.new()
	glint.position = Vector3(0, 0, -0.4)
	glint.light_color = Color(1.0, 0.75, 0.4)
	glint.light_energy = 1.5
	glint.omni_range = 4.0
	_node.add_child(glint)
	var audio := get_tree().get_first_node_in_group("audio")
	if audio != null and audio.has_method("play_static"):
		audio.play_static()
	GameState.show_message("Ada mata di kaca jendela. Jangan lihat matanya.")
	GameState.damage_sanity(Balance.GIANT_EYE_START_DRAIN)

func _spawn(sprite_name: String, pos: Vector3, height_m: float, tint: Color, offset := Vector3.ZERO) -> void:
	_node = Node3D.new()
	_node.position = pos
	var tex := SpriteRegistry.texture(sprite_name)
	if tex != null:
		_spr = Sprite3D.new()
		_spr.texture = tex
		_spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_spr.pixel_size = height_m / float(tex.get_height())
		_spr.modulate = tint
		_spr.shaded = true
		_spr.position = offset
		_node.add_child(_spr)
	get_parent().add_child(_node)

func _end_event() -> void:
	_active = false
	active_event = ""
	if _node != null:
		_node.queue_free()
	_node = null
	_spr = null

func _play_thud() -> void:
	var audio := get_tree().get_first_node_in_group("audio")
	if audio != null and audio.has_method("play_thud"):
		audio.play_thud()
	_spawn_dust()

func _spawn_dust() -> void:
	# Kepulan debu di tanah di bawah kaki yang menghentak: kaki yang
	# kelihatan di jendela terangkat mid-stride, jadi debunya naik dari
	# tanah tempat langkah itu mendarat. Memudar + mengembang 1,6 dtk.
	if _node == null:
		return
	if _dust != null:
		_dust.queue_free()
	var tex := SpriteRegistry.texture("fog_puff")
	if tex == null:
		return
	_dust = Sprite3D.new()
	_dust.texture = tex
	_dust.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dust.pixel_size = 2.4 / float(tex.get_height())
	_dust.modulate = Color(0.7, 0.72, 0.62, 0.55)
	_dust.shaded = false
	_dust.position = Vector3(_node.position.x, 0.35, _node.position.z)
	get_parent().add_child(_dust)
	_dust_age = 0.0
