extends CanvasLayer
## HUD dibangun dari kode supaya main.tscn tetap ramping.
## Crosshair titik di tengah, prompt di bawah tengah, SANITY/STABILITY
## di kiri bawah (VBox), jam + tugas di kanan atas, pesan fade di bawah.
## Tidak ada panel yang menutupi tengah layar.

var _prompt_label: Label
var _message_label: Label
var _clock_label: Label
var _tasks_label: Label
var _sanity_bar: ProgressBar
var _stability_bar: ProgressBar
var _end_label: Label
var _msg_tween: Tween
var _rec_label: Label
var _blink_t := 0.0
var _pause_panel: PanelContainer
var _save_btn: Button
var _paused := false

func _ready() -> void:
	add_to_group("hud")
	# HUD harus tetap jalan saat tree di-pause (menu jeda + tombolnya).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_build_pause_menu()
	GameState.sanity_changed.connect(func(v: float) -> void: _sanity_bar.value = v)
	GameState.stability_changed.connect(func(v: float) -> void: _stability_bar.value = v)
	GameState.clock_changed.connect(_on_clock)
	GameState.task_completed.connect(func(_id: String) -> void: _refresh_tasks())
	GameState.message_shown.connect(show_message)
	GameState.shift_ended.connect(_on_shift_ended)
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("prompt_changed"):
		player.prompt_changed.connect(func(t: String) -> void: _prompt_label.text = t)
	_refresh_tasks()
	_on_clock(GameState.shift_minutes)

func _label(text: String, size: int, color := Color(0.85, 0.83, 0.76)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func _make_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(190, 10)
	return bar

func _build() -> void:
	# --- Lapisan analog horror: satu shader layar penuh (post-process) ---
	# Mengambil SCREEN_TEXTURE lalu: tracking tear, chromatic aberration,
	# desaturasi ke hijau-abu sakit, scanlines, grain, vignette, flicker.
	# Rect ini ditambah PALING AWAL, jadi label HUD di atasnya tidak
	# ikut rusak dan tetap kebaca. v5 cuma punya grain 0.055 + scanline
	# samar, tanpa tear / CA / desaturasi / flicker.
	var fx := ColorRect.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.color = Color(1, 1, 1, 1)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture;
uniform float grain : hint_range(0.0, 1.0) = 0.13;
uniform float scanline : hint_range(0.0, 1.0) = 0.10;
uniform float ca : hint_range(0.0, 0.01) = 0.0016;
uniform float desat : hint_range(0.0, 1.0) = 0.45;
uniform float vignette : hint_range(0.0, 1.0) = 0.38;
uniform float flicker : hint_range(0.0, 0.2) = 0.04;
uniform float tear_shift : hint_range(0.0, 0.1) = 0.02;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	// Tracking tear: di ~70% jendela 4 detik, sebuah pita horizontal
	// bergeser selama 0.16 detik, lalu kembali normal.
	float cycle = floor(TIME / 4.0);
	float phase = fract(TIME / 4.0);
	float tear_on = step(hash(vec2(cycle, 7.0)), 0.7) * step(phase, 0.04);
	float band_y = hash(vec2(cycle, 13.0));
	float band = step(abs(uv.y - band_y), 0.03) * tear_on;
	uv.x += band * tear_shift * (hash(vec2(cycle, 3.0)) - 0.5) * 2.0;
	// Chromatic aberration, makin kuat ke tepi layar.
	float edge = length(uv - 0.5) * 2.0;
	vec2 off = vec2(ca * (0.5 + edge), 0.0);
	vec3 col;
	col.r = texture(screen_texture, uv + off).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - off).b;
	// Desaturasi ke hijau-abu sakit (palet moodboard).
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 sick = vec3(lum) * vec3(0.92, 1.0, 0.88);
	col = mix(col, sick, desat);
	// Scanlines.
	col *= 1.0 - scanline * (0.5 + 0.5 * sin(uv.y * 2262.0));
	// Grain VHS bergerak.
	float n = hash(uv * vec2(1280.0, 720.0) + vec2(TIME * 60.0, -TIME * 47.0));
	col += (n - 0.5) * grain;
	// Vignette.
	float d = length(uv - 0.5) * 2.0;
	col *= 1.0 - vignette * smoothstep(0.6, 1.4, d);
	// Flicker: napas halus + sesekali redup mendadak.
	float dip = step(0.94, hash(vec2(floor(TIME * 3.0), 5.0))) * 0.08;
	col *= 1.0 - dip + flicker * sin(TIME * 13.0) * 0.5;
	COLOR = vec4(col, 1.0);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("grain", Balance.VHS_GRAIN)
	sm.set_shader_parameter("scanline", Balance.VHS_SCANLINE)
	sm.set_shader_parameter("ca", Balance.VHS_CA)
	sm.set_shader_parameter("desat", Balance.VHS_DESATURATE)
	sm.set_shader_parameter("vignette", Balance.VHS_VIGNETTE)
	sm.set_shader_parameter("flicker", Balance.VHS_FLICKER)
	sm.set_shader_parameter("tear_shift", Balance.VHS_TEAR_SHIFT)
	fx.material = sm
	add_child(fx)
	# REC + label kamera, kiri atas (berkedip).
	_rec_label = _label("● REC   CAM 07", 16, Color(0.85, 0.25, 0.15))
	_rec_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_rec_label.offset_left = 18
	_rec_label.offset_right = 220
	_rec_label.offset_top = 12
	_rec_label.offset_bottom = 40
	add_child(_rec_label)

	var dot := ColorRect.new()
	dot.color = Color(0.9, 0.9, 0.85, 0.85)
	dot.custom_minimum_size = Vector2(4, 4)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-2, -2)
	dot.size = Vector2(4, 4)
	add_child(dot)

	_prompt_label = _label("", 17)
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.offset_left = -300
	_prompt_label.offset_right = 300
	_prompt_label.offset_top = -118
	_prompt_label.offset_bottom = -88
	add_child(_prompt_label)

	_message_label = _label("", 18, Color(0.92, 0.88, 0.74))
	_message_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.offset_left = -340
	_message_label.offset_right = 340
	_message_label.offset_top = -84
	_message_label.offset_bottom = -24
	_message_label.modulate.a = 0.0
	add_child(_message_label)

	var stats := VBoxContainer.new()
	stats.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stats.offset_left = 18
	stats.offset_right = 226
	stats.offset_top = -96
	stats.offset_bottom = -14
	stats.add_theme_constant_override("separation", 3)
	add_child(stats)
	stats.add_child(_label("SANITY", 13, Color(0.7, 0.68, 0.6)))
	_sanity_bar = _make_bar()
	stats.add_child(_sanity_bar)
	stats.add_child(_label("STABILITY", 13, Color(0.7, 0.68, 0.6)))
	_stability_bar = _make_bar()
	stats.add_child(_stability_bar)

	_clock_label = _label("22:00", 26)
	_clock_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock_label.offset_left = -120
	_clock_label.offset_right = -18
	_clock_label.offset_top = 12
	_clock_label.offset_bottom = 44
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_clock_label)

	_tasks_label = _label("", 14, Color(0.75, 0.73, 0.66))
	_tasks_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tasks_label.offset_left = -318
	_tasks_label.offset_right = -18
	_tasks_label.offset_top = 50
	_tasks_label.offset_bottom = 190
	_tasks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_tasks_label)

	_end_label = _label("", 32, Color(0.95, 0.9, 0.8))
	_end_label.set_anchors_preset(Control.PRESET_CENTER)
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_label.offset_left = -420
	_end_label.offset_right = 420
	_end_label.offset_top = -40
	_end_label.offset_bottom = 40
	add_child(_end_label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

## Dipakai tombol II di TouchControls dan tombol ESC.
func toggle_pause() -> void:
	if GameState.shift_over:
		return
	_paused = not _paused
	get_tree().paused = _paused
	_pause_panel.visible = _paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _paused else Input.MOUSE_MODE_CAPTURED

func _build_pause_menu() -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_panel.offset_left = -190
	_pause_panel.offset_right = 190
	_pause_panel.offset_top = -150
	_pause_panel.offset_bottom = 150
	_pause_panel.visible = false
	add_child(_pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_pause_panel.add_child(box)
	var title := _label("JEDA", 32, Color(0.92, 0.88, 0.74))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = "Lanjutkan"
	resume_btn.custom_minimum_size = Vector2(0, 48)
	resume_btn.add_theme_font_size_override("font_size", 19)
	resume_btn.pressed.connect(toggle_pause)
	box.add_child(resume_btn)
	_save_btn = Button.new()
	_save_btn.text = "Simpan Shift"
	_save_btn.custom_minimum_size = Vector2(0, 48)
	_save_btn.add_theme_font_size_override("font_size", 19)
	_save_btn.pressed.connect(_on_save_pressed)
	box.add_child(_save_btn)
	var quit_btn := Button.new()
	quit_btn.text = "Keluar ke Menu"
	quit_btn.custom_minimum_size = Vector2(0, 48)
	quit_btn.add_theme_font_size_override("font_size", 19)
	quit_btn.pressed.connect(_on_quit_pressed)
	box.add_child(quit_btn)

func _on_save_pressed() -> void:
	if SaveGame.save():
		_save_btn.text = "Tersimpan"
	else:
		_save_btn.text = "Gagal menyimpan"
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void: _save_btn.text = "Simpan Shift")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	_paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(delta: float) -> void:
	# REC berkedip pelan seperti kamera CCTV rusak.
	_blink_t += delta
	if _rec_label:
		_rec_label.modulate.a = 0.55 + 0.45 * sin(_blink_t * 2.4)

func show_message(text: String) -> void:
	_message_label.text = text
	if _msg_tween and _msg_tween.is_running():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_message_label.modulate.a = 1.0
	_msg_tween.tween_interval(3.4)
	_msg_tween.tween_property(_message_label, "modulate:a", 0.0, 1.2)

func _on_clock(_minutes: float) -> void:
	_clock_label.text = GameState.clock_text()

func _refresh_tasks() -> void:
	var lines: Array[String] = []
	for id in GameState.tasks.keys():
		var t: Dictionary = GameState.tasks[id]
		lines.append(("[x] " if t["done"] else "[ ] ") + str(t["label"]))
	_tasks_label.text = "\n".join(lines)

func _on_shift_ended(success: bool) -> void:
	_end_label.text = "06:00 - Shift selesai. Kamu masih di sini." if success else "Shift berakhir. Pos kosong sebelum pagi."
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
