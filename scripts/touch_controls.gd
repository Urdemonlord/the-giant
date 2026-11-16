extends CanvasLayer
## Kontrol sentuh Android: joystick virtual (kiri) + geser kanan untuk
## melihat + tombol E / SENTER / jeda.
## Tampil otomatis kalau DisplayServer.is_touchscreen_available(), atau
## kalau game dijalankan dengan argumen `-- touch=1` (untuk tes di desktop
## dan test rig mode=touch). Joystick mengambang: muncul di titik jari
## menyentuh separuh kiri layar. Tombol dibuat dari Button biasa supaya
## bisa ditekan jari maupun mouse.

const JOY_RADIUS := 85.0
const LOOK_SENS := 0.0045

var _joy_base: Panel
var _joy_knob: Panel
var _joy_active := -1
var _joy_center := Vector2.ZERO
var _look_active := -1

func _ready() -> void:
	add_to_group("touch_controls")
	visible = false
	_build()
	var force := false
	for a in OS.get_cmdline_user_args():
		if str(a) == "touch=1":
			force = true
	if force or DisplayServer.is_touchscreen_available():
		visible = true

## Dipakai test rig: paksa tampil walau di desktop tanpa layar sentuh.
func force_show() -> void:
	visible = true

func _panel_circle(size: float, alpha: float) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, alpha)
	sb.set_corner_radius_all(int(size * 0.5))
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _touch_button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 22)
	b.modulate = Color(1, 1, 1, 0.85)
	return b

func _build() -> void:
	_joy_base = _panel_circle(180, 0.10)
	_joy_base.position = Vector2(60, 460)
	_joy_base.visible = false
	add_child(_joy_base)
	_joy_knob = _panel_circle(80, 0.30)
	_joy_knob.position = Vector2(110, 510)
	_joy_knob.visible = false
	add_child(_joy_knob)

	var hint := Label.new()
	hint.text = "Joystick kiri: jalan   |   Geser kanan: lihat"
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.offset_left = -300
	hint.offset_right = 300
	hint.offset_top = -36
	hint.offset_bottom = -12
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7, 0.8))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	# Tombol aksi di kanan bawah (E besar, senter di atasnya).
	var interact_btn := _touch_button("E", Vector2(1090, 560), Vector2(110, 110))
	interact_btn.pressed.connect(_on_interact)
	add_child(interact_btn)
	var light_btn := _touch_button("SENTER", Vector2(1090, 440), Vector2(110, 60))
	light_btn.pressed.connect(_on_flashlight)
	add_child(light_btn)
	# Tombol jeda di kiri atas, di bawah label REC (kanan atas ditempati jam).
	var pause_btn := _touch_button("II", Vector2(18, 52), Vector2(64, 48))
	pause_btn.add_theme_font_size_override("font_size", 18)
	pause_btn.pressed.connect(_on_pause)
	add_child(pause_btn)

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _on_interact() -> void:
	var p := _player()
	if p != null and p.has_method("try_interact"):
		p.try_interact()

func _on_flashlight() -> void:
	var p := _player()
	if p != null and p.has_method("toggle_flashlight"):
		p.toggle_flashlight()

func _on_pause() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("toggle_pause"):
		hud.toggle_pause()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			var vp := get_viewport().get_visible_rect().size
			if t.position.x < vp.x * 0.45 and _joy_active == -1:
				_joy_active = t.index
				_joy_center = t.position
				_joy_base.position = t.position - Vector2(90, 90)
				_joy_knob.position = t.position - Vector2(40, 40)
				_joy_base.visible = true
				_joy_knob.visible = true
			elif _look_active == -1:
				_look_active = t.index
		else:
			if t.index == _joy_active:
				_joy_active = -1
				_joy_base.visible = false
				_joy_knob.visible = false
				var p := _player()
				if p != null:
					p.touch_move = Vector2.ZERO
			elif t.index == _look_active:
				_look_active = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_active:
			var offset := d.position - _joy_center
			if offset.length() > JOY_RADIUS:
				offset = offset.normalized() * JOY_RADIUS
			_joy_knob.position = _joy_center + offset - Vector2(40, 40)
			var p := _player()
			if p != null:
				# Atas layar = maju (y negatif = maju, sama seperti
				# Input.get_vector: move_forward memberi y -1).
				p.touch_move = offset / JOY_RADIUS
		elif d.index == _look_active:
			var p2 := _player()
			if p2 != null and p2.has_method("apply_look"):
				p2.apply_look(-d.relative.x * LOOK_SENS, -d.relative.y * LOOK_SENS)
