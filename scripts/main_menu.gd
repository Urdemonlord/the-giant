extends Control
## Menu utama / layar intro THE GIANT.
## Dibangun dari kode supaya menu.tscn tetap ramping.
## MULAI SHIFT BARU = reset shift, masuk main.tscn.
## LANJUTKAN = load user://savegame.json (kalau ada), masuk main.tscn.
## CARA MAIN = panel kontrol + cerita singkat. Tidak ada yang berubah
## dari gameplay inti: satu level, satu pos jaga, Malayunesia.
## v16 (arah unslop, sama dengan HUD): produk = menu shift malam
## lewat kamera pos yang rusak; karakter = tenang, waspada,
## birokratis; dunia = pos jaga berkabut + lentera + VHS; momen =
## cahaya lentera teras di kanan frame; signature = "● REC   CAM 07".
## Latar BUKAN gambar — scene main hidup di belakang teks (split
## asimetris: teks kiri, pos kanan), bukan tumpukan terpusat di atas
## hitam.

var _help_label: Label
var _continue_btn: Button
var _start_btn: Button
var _ui_layer: CanvasLayer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# v16: latar 3D hidup — scene main yang sama, mode backdrop
	# (main.gd: tidak ada shift/event/HUD, kamera menu sendiri).
	# Dibuat SEBELUM _build() supaya UI tergambar di atasnya; ikut
	# ter-free saat ganti scene, tidak ada yang bocor ke permainan.
	var level: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	level.name = "Backdrop"
	level.set_meta("menu_backdrop", true)
	add_child(level)
	# v16: VHS + UI tinggal di CanvasLayer layer 1 (pola yang sama
	# dengan HUD): fx digambar PERTAMA di layer itu, jadi
	# screen_texture-nya berisi 3D backdrop; UI ditambah setelahnya
	# supaya tetap bersih. fx di layer 0 (Control) TIDAK bisa membaca
	# screen_texture — sampelnya putih kosong (terbukti di rig v20:
	# mean_lum 0.625 dengan fx di layer 0, 0.108 tanpa fx).
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "MenuLayer"
	_ui_layer.layer = 1
	add_child(_ui_layer)
	_build()
	# v15: fokus ke tombol mulai (keyboard/gamepad langsung jalan).
	_start_btn.grab_focus()
	# Hook uji headless: jalankan menu dengan `-- menu_autostart=1`
	# untuk membuktikan tombol MULAI masuk ke scene main.
	for a in OS.get_cmdline_user_args():
		if str(a) == "menu_autostart=1":
			await get_tree().process_frame
			await get_tree().process_frame
			_on_new_game()

func _build() -> void:
	# v16: latar belakang BUKAN lagi ColorRect hitam — di belakang
	# kontrol ini ada scene main hidup (Backdrop). Yang pertama
	# digambar adalah shader VHS yang sama dengan game (satu file
	# dengan hud.gd: assets/shaders/vhs.gdshader), jadi latar menu
	# kelihatan lewat kamera pos yang rusak; teks menu ditambah
	# SETELAH-nya supaya tetap bersih (persis pola HUD: fx dulu,
	# teks belakangan).
	var fx := ColorRect.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.color = Color(1, 1, 1, 1)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/vhs.gdshader") as Shader
	sm.set_shader_parameter("grain", Balance.VHS_GRAIN)
	sm.set_shader_parameter("scanline", Balance.VHS_SCANLINE)
	sm.set_shader_parameter("ca", Balance.VHS_CA)
	sm.set_shader_parameter("desat", Balance.VHS_DESATURATE)
	sm.set_shader_parameter("vignette", Balance.VHS_VIGNETTE)
	sm.set_shader_parameter("flicker", Balance.VHS_FLICKER)
	sm.set_shader_parameter("tear_shift", Balance.VHS_TEAR_SHIFT)
	fx.material = sm
	_ui_layer.add_child(fx)
	# Vignette tipis di menu supaya tidak terasa seperti layar kosong.
	var vig := ColorRect.new()
	vig.color = Color(0, 0, 0, 0.35)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(vig)
	# v15: stempel yang sama dengan HUD ("● REC   CAM 07") — satu
	# detail signature yang mengikat menu dan game. Bukan dekorasi
	# baru, tapi identitas yang sudah ada dipakai konsisten.
	var rec := Label.new()
	rec.text = "● REC   CAM 07"
	rec.add_theme_font_size_override("font_size", 16)
	rec.add_theme_color_override("font_color", Color(0.85, 0.25, 0.15))
	rec.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rec.offset_left = 18
	rec.offset_right = 220
	rec.offset_top = 12
	rec.offset_bottom = 40
	rec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(rec)

	# v16: split asimetris (unslop §6 — bukan tumpukan terpusat):
	# teks di kolom kiri (88..548), pos jaga hidup di kanan frame.
	# Judul + label rata kiri, bukan tengah.
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 88
	box.offset_right = 548
	# v16: kotak 560 tinggi (bukan 420) — kolom kiri yang lebih
	# sempit membuat sub + bantuan membungkus lebih panjang; dengan
	# 420 paragraf sentuh + footer jatuh di luar layar saat Cara
	# main dibuka, dengan 500 masih terpotong sebaris. 560 memberi
	# ruang untuk semuanya sampai footer.
	box.offset_top = -280
	box.offset_bottom = 280
	box.add_theme_constant_override("separation", 14)
	_ui_layer.add_child(box)

	var title := Label.new()
	title.text = "THE GIANT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "Pos jaga, Taman Nasional Malayunesia. Shift malam 22:00 - 06:00.\nJaga pos ini. Jangan biarkan mereka kembali."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.75, 0.73, 0.66))
	box.add_child(sub)

	# v15: sentence case (dulu semua tombol kapital — template tell).
	# Judul "THE GIANT" tetap kapital: itu nama produk/logo, bukan label.
	_start_btn = _menu_button("Mulai shift baru")
	_start_btn.pressed.connect(_on_new_game)
	box.add_child(_start_btn)

	_continue_btn = _menu_button("Lanjutkan")
	_continue_btn.pressed.connect(_on_continue)
	box.add_child(_continue_btn)
	_refresh_continue()

	var help_btn := _menu_button("Cara main")
	help_btn.pressed.connect(func() -> void: _help_label.visible = not _help_label.visible)
	box.add_child(help_btn)

	_help_label = Label.new()
	_help_label.text = "WASD jalan, Shift lari, mouse melihat, E interaksi, F senter, ESC jeda.\nNyalakan generator, cek radio, tulis laporan di buku jaga.\nKalau ada yang berdiri diam di luar dan menatap pos: tutup pintu, tunggu di dalam.\nJangan lihat matanya.\n\nDi layar sentuh: joystick kiri untuk jalan, geser kanan untuk melihat,\ntombol E untuk interaksi, SENTER untuk senter."
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help_label.add_theme_font_size_override("font_size", 15)
	_help_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.6))
	_help_label.visible = false
	box.add_child(_help_label)

	var foot := Label.new()
	foot.text = "Sebuah cerita horor psikologis. Giant tidak pernah tampil utuh."
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	box.add_child(foot)

func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 20)
	# v15: gaya tombol yang sama dengan panel HUD (gelap hangat,
	# pinggir tipis, fokus kuning) supaya menu dan game satu bahasa.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.13, 0.11)
	normal.border_color = Color(0.45, 0.42, 0.34)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.18, 0.14)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.1, 0.09, 0.08)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color(0.95, 0.85, 0.45)
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	b.add_theme_color_override("font_hover_color", Color(0.96, 0.92, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.43, 0.38))
	return b

func _refresh_continue() -> void:
	if SaveGame.has_save():
		_continue_btn.text = SaveGame.summary_text()
		_continue_btn.disabled = false
	else:
		_continue_btn.text = "Lanjutkan (belum ada simpanan)"
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
