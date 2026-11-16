extends Control
## Menu utama / layar intro THE GIANT.
## Dibangun dari kode supaya menu.tscn tetap ramping.
## MULAI SHIFT BARU = reset shift, masuk main.tscn.
## LANJUTKAN = load user://savegame.json (kalau ada), masuk main.tscn.
## CARA MAIN = panel kontrol + cerita singkat. Tidak ada yang berubah
## dari gameplay inti: satu level, satu pos jaga, Malayunesia.

var _help_label: Label
var _continue_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	# Hook uji headless: jalankan menu dengan `-- menu_autostart=1`
	# untuk membuktikan tombol MULAI masuk ke scene main.
	for a in OS.get_cmdline_user_args():
		if str(a) == "menu_autostart=1":
			await get_tree().process_frame
			await get_tree().process_frame
			_on_new_game()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.03, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Vignette tipis di menu supaya tidak terasa seperti layar kosong.
	var vig := ColorRect.new()
	vig.color = Color(0, 0, 0, 0.35)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -210
	box.offset_bottom = 210
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "THE GIANT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Pos jaga, Taman Nasional Malayunesia. Shift malam 22:00 - 06:00.\nJaga pos ini. Jangan biarkan mereka kembali."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.75, 0.73, 0.66))
	box.add_child(sub)

	var start_btn := _menu_button("MULAI SHIFT BARU")
	start_btn.pressed.connect(_on_new_game)
	box.add_child(start_btn)

	_continue_btn = _menu_button("LANJUTKAN")
	_continue_btn.pressed.connect(_on_continue)
	box.add_child(_continue_btn)
	_refresh_continue()

	var help_btn := _menu_button("CARA MAIN")
	help_btn.pressed.connect(func() -> void: _help_label.visible = not _help_label.visible)
	box.add_child(help_btn)

	_help_label = Label.new()
	_help_label.text = "WASD jalan, Shift lari, mouse melihat, E interaksi, F senter, ESC jeda.\nNyalakan generator, cek radio, tulis laporan di buku jaga.\nKalau ada yang berdiri diam di luar dan menatap pos: tutup pintu, tunggu di dalam.\nJangan lihat matanya.\n\nDi layar sentuh: joystick kiri untuk jalan, geser kanan untuk melihat,\ntombol E untuk interaksi, SENTER untuk senter."
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_label.add_theme_font_size_override("font_size", 15)
	_help_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	_help_label.visible = false
	box.add_child(_help_label)

	var foot := Label.new()
	foot.text = "Sebuah cerita horor psikologis. Giant tidak pernah tampil utuh."
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	box.add_child(foot)

func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 20)
	return b

func _refresh_continue() -> void:
	if SaveGame.has_save():
		_continue_btn.text = SaveGame.summary_text()
		_continue_btn.disabled = false
	else:
		_continue_btn.text = "LANJUTKAN (belum ada simpanan)"
		_continue_btn.disabled = true

func _on_new_game() -> void:
	GameState.resume_data = {}
	GameState.reset_shift()
	SaveGame.clear()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_continue() -> void:
	var data := SaveGame.load_data()
	if data.is_empty():
		return
	GameState.resume_data = data
	get_tree().change_scene_to_file("res://scenes/main.tscn")
