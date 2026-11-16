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

func _ready() -> void:
	add_to_group("giant_event")

func _process(delta: float) -> void:
	if GameState.shift_over:
		return
	if not _foot_done and GameState.shift_minutes >= TRIGGER_FOOT_MINUTE:
		_start_foot()
	elif not _eye_done and GameState.shift_minutes >= TRIGGER_EYE_MINUTE:
		_start_eye()
	if not _active:
		return
	_elapsed += delta
	var player := get_tree().get_first_node_in_group("player")
	if active_event == "foot":
		# Kaki melangkah pelan dari kiri ke kanan, lewat jendela belakang.
		var t := clampf(_elapsed / FOOT_DURATION, 0.0, 1.0)
		_node.position.x = lerpf(LevelData.GIANT_FOOT_START.x, LevelData.GIANT_FOOT_END_X, t)
		_node.position.y = 2.25 + sin(t * PI) * 0.12 # sedikit terangkat saat melangkah
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
	_spawn("giant_foot", LevelData.GIANT_FOOT_START, LevelData.GIANT_FOOT_HEIGHT_M, Color(0.5, 0.5, 0.55, 0.95))
	_play_thud()
	GameState.show_message("Tanah bergetar. Sesuatu yang sangat besar lewat di belakang pos.")
	GameState.damage_sanity(Balance.GIANT_FOOT_START_DRAIN)

func _start_eye() -> void:
	_eye_done = true
	_active = true
	active_event = "eye"
	_elapsed = 0.0
	# Mata v5: SATU sprite crop rapat di sekeliling rongga mata gajah
	# (60x56 px di sheet, di-upscale Lanczos ke 360x336 + kontras).
	# Dulu dua lapis (kulit 70x65 + rongga 36x28) yang sama-sama blur;
	# sekarang mata memenuhi sprite dan dipasang tepat di tengah
	# jendela (LevelData.GIANT_EYE_POS). Batas jujur: mata asli di
	# sheet cuma ~25 px, jadi upscale tidak bisa menambah detail baru,
	# hanya memperbesar yang ada. Tidak ada filter/poles tambahan.
	_spawn("giant_eye", LevelData.GIANT_EYE_POS, LevelData.GIANT_EYE_HEIGHT_M, Color(1.0, 0.95, 0.85, 1.0))
	# Kilau redup di kaca supaya mata kebaca di gelap.
	var glint := OmniLight3D.new()
	glint.position = Vector3(0, 0, -0.4)
	glint.light_color = Color(1.0, 0.75, 0.4)
	glint.light_energy = 0.7
	glint.omni_range = 3.0
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
