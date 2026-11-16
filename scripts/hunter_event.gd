extends Node
## Event pemburu: momen No I'm Not a Human versi THE GIANT.
## Sekitar 01:30 dua sosok berdiri diam di depan pos, menatap kamera pos.
## Mereka tidak mendekat. Itu yang bikin tidak enak.
## Menatap mereka menguras Sanity. Menutup pintu dan menunggu di dalam
## mengakhiri event dengan aman.

const TRIGGER_MINUTE := Balance.HUNTER_TRIGGER_MINUTE
const EVENT_DURATION := Balance.HUNTER_EVENT_DURATION
const SAFE_DOOR_CLOSED_TIME := Balance.HUNTER_SAFE_DOOR_CLOSED_TIME

var _triggered := false
var _active := false
var _elapsed := 0.0
var _door_closed_time := 0.0
var _hunters: Array[Node3D] = []

func _ready() -> void:
	add_to_group("hunter_event")

func _process(delta: float) -> void:
	if GameState.shift_over:
		return
	if not _triggered and GameState.shift_minutes >= TRIGGER_MINUTE:
		_start_event()
	if not _active:
		return
	_elapsed += delta
	var player := get_tree().get_first_node_in_group("player")
	# Menatap hanya menguras Sanity kalau pemburu benar-benar bisa
	# dilihat: pintu terbuka (atau pemain di luar). Pintu tertutup
	# berarti mereka di balik kayu solid, menatap dinding tidak
	# seharusnya membunuh pemain yang diam di dalam.
	# Satu sosok saja yang menguras per detik, bukan dua sekaligus.
	if player != null and GameState.door_open and player.has_method("look_dot_towards"):
		for h in _hunters:
			var eye_pos := h.global_position + Vector3(0, 2.6, 0)
			if float(player.look_dot_towards(eye_pos)) > Balance.HUNTER_LOOK_DOT:
				GameState.damage_sanity(Balance.HUNTER_LOOK_DRAIN * delta)
				break
	# Pintu tertutup + pemain di dalam = cara aman melewati event.
	if not GameState.door_open:
		_door_closed_time += delta
	else:
		_door_closed_time = 0.0
	if _door_closed_time >= SAFE_DOOR_CLOSED_TIME:
		_end_event(true)
	elif _elapsed >= EVENT_DURATION:
		_end_event(not GameState.door_open)

func _start_event() -> void:
	_triggered = true
	_active = true
	_elapsed = 0.0
	_door_closed_time = 0.0
	_spawn_hunter(LevelData.HUNTER_POS_1, "hunter_rifle")
	_spawn_hunter(LevelData.HUNTER_POS_2, "hunter") # varian kedua: potongan lama hunter.png
	var audio := get_tree().get_first_node_in_group("audio")
	if audio != null and audio.has_method("play_static"):
		audio.play_static()
	GameState.show_message("Radio berbunyi sendiri. Di luar, dua orang berdiri diam. Menatap pos.")
	GameState.damage_sanity(Balance.HUNTER_START_DRAIN)

func _spawn_hunter(pos: Vector3, sprite_name: String) -> void:
	var root := Node3D.new()
	root.position = pos
	# Sosoknya sprite pemburu dari sheet Arya, setinggi manusia
	# (1,8 m), bukan kapsul hitam. Yang kedua sedikit lebih gelap.
	var tex := SpriteRegistry.texture(sprite_name)
	if tex != null:
		var spr := Sprite3D.new()
		spr.texture = tex
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.pixel_size = LevelData.HUNTER_HEIGHT_M / float(tex.get_height())
		spr.position.y = 0.9
		spr.modulate = Color(0.55, 0.55, 0.55, 0.9) if _hunters.is_empty() else Color(0.4, 0.4, 0.4, 0.9)
		root.add_child(spr)
	get_parent().add_child(root)
	# Hadapkan ke pos jaga (origin).
	root.look_at(Vector3(0, 1.2, 0), Vector3.UP)
	_hunters.append(root)

func _end_event(safe: bool) -> void:
	_active = false
	for h in _hunters:
		h.queue_free()
	_hunters.clear()
	if safe:
		GameState.complete_task("hunter")
		GameState.show_message("Langkah kaki menjauh. Mereka pergi. Untuk malam ini.")
	else:
		GameState.damage_sanity(Balance.HUNTER_END_DRAIN)
		GameState.complete_task("hunter")
		GameState.show_message("Kamu berkedip. Mereka sudah tidak ada. Itu lebih buruk.")
