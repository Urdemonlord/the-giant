extends CanvasLayer
## HUD dibangun dari kode supaya main.tscn tetap ramping.
## Crosshair titik di tengah, prompt di bawah tengah, Sanity/Stability
## di kiri bawah (VBox), jam + tugas di kanan atas, pesan fade di bawah.
## Tidak ada panel yang menutupi tengah layar.
##
## v15 UI/UX — arah unslop (lima baris, diturunkan dari brief + produk):
## - Produk: shift malam orang pertama di pos jaga Malayunesia, dilihat
##   lewat kamera pos yang rusak, 22:00-06:00.
## - Karakter: tenang, waspada, birokratis.
## - Dunia: kamera pos rusak + buku log kertas — grain VHS, REC CAM 07,
##   dokumen ketikan, kertas bergaris, stempel karet.
## - Momen: cahaya lentera di atas meja; titik REC merah; headline koran
##   yang diketik.
## - Signature: stempel "● REC   CAM 07", dipakai di HUD dan menu utama,
##   tidak di tempat lain.
## Aturannya: chrome tenang, satu aksen (kuning lentera), hierarki jelas,
## ritme spasi 4px, sentence case, tanpa emoji, tanpa pil berpendar,
## tanpa label kapital yang di-track. Semua panel memakai _panel_style(),
## semua tombol memakai _style_button().

var _prompt_label: Label
var _message_label: Label
var _clock_label: Label
## v15: tugas bukan satu label lagi — satu label per tugas supaya yang
## sudah selesai bisa diredupkan (warna) sementara yang belum tetap
## terang. Bentuk [x]/[ ] tetap jadi penanda utama, bukan warna saja.
var _tasks_box: VBoxContainer
var _task_labels: Array[Label] = []
var _sanity_bar: ProgressBar
var _stability_bar: ProgressBar
var _doc_panel: PanelContainer
var _doc_title: Label
var _doc_body: Label
var _doc_close_btn: Button
var _intro_panel: PanelContainer
var _intro_start_btn: Button
var _end_panel: PanelContainer
var _end_title: Label
var _end_body: Label
var _end_replay_btn: Button
var _resume_btn: Button
var _msg_tween: Tween
var _rec_label: Label
var _blink_t := 0.0
## v14: material shader VHS disimpan supaya grain/desat/vignette
## bisa di-lerp mengikuti Sanity (kamera ikut rusak saat pemainnya).
var _fx_mat: ShaderMaterial
## v14 (polish #8): slow pan selama intro — kamera menyapu pelan
## keluar jendela. _pan_yaw = offset yaw saat ini, direset ke 0 saat
## intro ditutup supaya yaw pemain tidak bergeser.
var _player: Node3D
var _intro_t := 0.0
var _pan_yaw := 0.0
var _pause_panel: PanelContainer
var _save_btn: Button
var _paused := false
var _doc_open := false
var _intro_open := false
var _end_open := false

## Satu kalimat penutup faktual, tampil di akhir kedua ending.
## (Brief: ending ditutup satu kalimat faktual saja.)
const CLOSING_FACT := "Di Malayunesia, gajah adalah satwa dilindungi; setiap tahun, ribuan hektar hutan tempat mereka hidup berubah menjadi kebun sawit."

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
	_player = player as Node3D
	if player != null and player.has_signal("prompt_changed"):
		player.prompt_changed.connect(func(t: String) -> void: _prompt_label.text = t)
	_refresh_tasks()
	_on_clock(GameState.shift_minutes)

func _label(text: String, size: int, color := Color(0.85, 0.83, 0.76)) -> Label:
	var l := Label.new()
	# v13: label TIDAK BOLEH memakan klik/gerak mouse. Dulu semua label
	# default STOP, jadi klik di tengah layar + gerak mouse di atas
	# dot crosshair tidak pernah sampai ke player (mouse look kekunci
	# bahkan saat mouse sudah CAPTURED, karena kursor selalu di-warp
	# ke tengah layar, tepat di atas dot).
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func _make_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE # v13: jangan makan klik
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(190, 10)
	return bar

## v15: satu gaya panel untuk semua layar (dokumen, intro, akhir,
## jeda): gelap hangat, pinggir terang tipis 1px, radius 2 (bukan pil),
## margin isi 20/16 supaya teks tidak menempel ke pinggir.
func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.065, 0.055, 0.97)
	sb.border_color = Color(0.45, 0.42, 0.34)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb

## v15: satu gaya tombol untuk semua layar. Fokus keyboard/gamepad
## dapat garis aksen kuning (terlihat beda dari hover), supaya
## navigasi tanpa mouse tidak buta (game-ui-ux: fokus saat dibuka).
func _style_button(b: Button) -> void:
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

## v15: bilah status diwarnai secukupnya (Sanity hijau-abu sakit,
## Stability kuning lentera). Label di sebelahnya tetap jadi penanda
## utama, jadi warna cuma penanda kedua (bukan satu-satunya sinyal).
func _style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.09)
	bg.set_corner_radius_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)

## v15: satu tombol keyboard sebagai keycap kecil (unslop §7):
## kotak gelap, pinggir tipis, radius 3. Dipakai blok kontrol di
## intro dan menu jeda — pemain belajar kontrol sekali di sana.
func _keycap(text: String, size: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.15, 0.12)
	sb.border_color = Color(0.5, 0.47, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(_label(text, size, Color(0.92, 0.88, 0.74)))
	return p

## v15: blok daftar kontrol (2 baris x 3 pasangan keycap + aksi).
## Dipakai intro dan menu jeda supaya pemain belajar kontrol sekali
## di awal, bukan diomeli label tengah layar tiap Alt-Tab.
func _controls_block(size: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var rows: Array = [
		[["WASD", "Jalan"], ["Shift", "Lari"], ["Mouse", "Melihat"]],
		[["E", "Interaksi"], ["F", "Senter"], ["Esc", "Jeda"]],
	]
	for row in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for pair in row:
			var cell := HBoxContainer.new()
			cell.add_theme_constant_override("separation", 6)
			cell.add_child(_keycap(str(pair[0]), size))
			cell.add_child(_label(str(pair[1]), size, Color(0.75, 0.73, 0.66)))
			h.add_child(cell)
		v.add_child(h)
	return v

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
	# v17: shader VHS pindah ke res://assets/shaders/vhs.gdshader
	# (satu file bersama menu utama) supaya kedua layar tidak bisa
	# drift. Isi shader TIDAK berubah — cuma tempat tinggalnya.
	var sh := load("res://assets/shaders/vhs.gdshader") as Shader
	var sm := ShaderMaterial.new()
	sm.shader = sh
	# v18: grain ikut Settings (Options menu) — mati = 0, bukan bawaan.
	sm.set_shader_parameter("grain", Balance.VHS_GRAIN if Settings.grain_on() else 0.0)
	sm.set_shader_parameter("scanline", Balance.VHS_SCANLINE)
	sm.set_shader_parameter("ca", Balance.VHS_CA)
	sm.set_shader_parameter("desat", Balance.VHS_DESATURATE)
	sm.set_shader_parameter("vignette", Balance.VHS_VIGNETTE)
	sm.set_shader_parameter("flicker", Balance.VHS_FLICKER)
	sm.set_shader_parameter("tear_shift", Balance.VHS_TEAR_SHIFT)
	fx.material = sm
	_fx_mat = sm
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
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE # v13: dot di tengah
	# layar TIDAK BOLEH memakan gerak mouse (dulu STOP: tiap motion
	# event mendarat di atas dot dan tidak sampai ke player).
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
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE # v13
	stats.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stats.offset_left = 18
	stats.offset_right = 226
	stats.offset_top = -96
	stats.offset_bottom = -14
	stats.add_theme_constant_override("separation", 3)
	add_child(stats)
	# v15: sentence case (dulu "SANITY"/"STABILITY" kapital di-track —
	# template tell). Bilah diwarnai secukupnya, label tetap penanda.
	stats.add_child(_label("Sanity", 13, Color(0.7, 0.68, 0.6)))
	_sanity_bar = _make_bar()
	_style_bar(_sanity_bar, Color(0.6, 0.66, 0.52))
	stats.add_child(_sanity_bar)
	stats.add_child(_label("Stability", 13, Color(0.7, 0.68, 0.6)))
	_stability_bar = _make_bar()
	_style_bar(_stability_bar, Color(0.82, 0.66, 0.3))
	stats.add_child(_stability_bar)

	_clock_label = _label("22:00", 26)
	_clock_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock_label.offset_left = -120
	_clock_label.offset_right = -18
	_clock_label.offset_top = 12
	_clock_label.offset_bottom = 44
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_clock_label)

	# v15: satu label per tugas (dulu satu label untuk semua baris).
	# Yang selesai diredupkan, yang belum tetap terang — penanda utama
	# tetap bentuk [x]/[ ], warna cuma penanda kedua.
	_tasks_box = VBoxContainer.new()
	_tasks_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tasks_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tasks_box.offset_left = -318
	_tasks_box.offset_right = -18
	_tasks_box.offset_top = 50
	_tasks_box.offset_bottom = 190
	_tasks_box.add_theme_constant_override("separation", 2)
	add_child(_tasks_box)
	for id in GameState.tasks.keys():
		var tl := _label("", 14, Color(0.85, 0.83, 0.76))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_tasks_box.add_child(tl)
		_task_labels.append(tl)

	# v15: petunjuk "Klik untuk mengunci mouse" DIHAPUS. Tugasnya
	# (memberi tahu pemain) pindah ke blok kontrol di intro + jeda,
	# dan mouse dikunci otomatis saat jendela kembali fokus
	# (_notification) + klik di mana saja (player._input). Label
	# tengah layar yang mengomel tiap Alt-Tab tidak kembali lagi.
	_build_doc_panel()
	_build_intro_panel()
	_build_end_panel()

func _panel_box(width: int) -> PanelContainer:
	# Panel baca/akhir yang sama gayanya: gelap, pinggir terang tipis.
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -width
	p.offset_right = width
	p.offset_top = -190
	p.offset_bottom = 190
	p.visible = false
	p.add_theme_stylebox_override("panel", _panel_style())
	add_child(p)
	return p

func _panel_column(panel: PanelContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box

func _big_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 19)
	_style_button(b)
	return b

## Panel baca dokumen (koran / surat). Game di-pause selama membaca.
func _build_doc_panel() -> void:
	_doc_panel = _panel_box(320)
	var box := _panel_column(_doc_panel)
	_doc_title = _label("", 22, Color(0.95, 0.9, 0.78))
	_doc_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_doc_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_doc_title)
	_doc_body = _label("", 17)
	_doc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_doc_body)
	_doc_close_btn = _big_button("Tutup (E)")
	_doc_close_btn.pressed.connect(close_document)
	box.add_child(_doc_close_btn)

func show_document(title: String, body: String) -> void:
	_doc_title.text = title
	_doc_body.text = body
	_doc_panel.visible = true
	_doc_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# v15: fokus ke tombol tutup supaya keyboard/E langsung jalan
	# tanpa mouse (game-ui-ux: satu kontrol fokus saat layar dibuka).
	_doc_close_btn.grab_focus()

func close_document() -> void:
	if not _doc_open:
		return
	_doc_panel.visible = false
	_doc_open = false
	get_tree().paused = false
	# v13: dulu mouse tetap VISIBLE setelah dokumen ditutup, jadi
	# pemain harus klik dulu (tanpa petunjuk) sebelum look jalan.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Intro shift (brief v7): 3 baris, bisa di-skip dengan E / tombol.
func _build_intro_panel() -> void:
	_intro_panel = _panel_box(320)
	var box := _panel_column(_intro_panel)
	# v15: sentence case (dulu "POS JAGA 07 — 22:00" kapital + em dash
	# ber-spasi — dua template tell sekaligus). Judulnya nama pos saja;
	# jam + tempat sudah ada di badan teks.
	var title := _label("Pos Jaga 07", 24, Color(0.95, 0.9, 0.78))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var body := _label("Taman Nasional Malayunesia. Shift malam: 22:00 sampai 06:00.\n\nTugasmu: jaga lampu tetap menyala, tulis laporan, dan jangan buka pintu untuk yang mengetuk dari arah hutan.\n\nPenjaga sebelumnya pergi tanpa pamit. Di atas meja ada koran dan surat yang tidak ia bawa. Bacalah.", 17)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	# v15: kontrol diajarkan sekali di sini (pengganti petunjuk tengah
	# layar yang dihapus): keycap + aksi, bukan satu baris teks padat.
	box.add_child(_controls_block(15))
	_intro_start_btn = _big_button("Mulai shift (E)")
	_intro_start_btn.pressed.connect(close_intro)
	box.add_child(_intro_start_btn)

func show_intro() -> void:
	_intro_panel.visible = true
	_intro_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# v15: fokus ke tombol mulai (keyboard/gamepad langsung jalan).
	_intro_start_btn.grab_focus()

func close_intro() -> void:
	if not _intro_open:
		return
	_intro_panel.visible = false
	_intro_open = false
	# v14: kembalikan yaw pan intro ke 0 supaya pandangan pemain
	# mulai dari arah spawn semula, bukan dari ujung sapuan.
	if _pan_yaw != 0.0 and _player != null and _player.has_method("apply_look"):
		_player.apply_look(-_pan_yaw, 0.0)
		_pan_yaw = 0.0
	get_tree().paused = false
	# v13: dulu mouse tetap VISIBLE setelah intro ditutup. Ini akar
	# bug "view kekunci" di Windows: pemain baru tidak tahu harus
	# klik dulu, dan klik di tengah layar dimakan dot crosshair.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Layar akhir beneran (brief v7): judul + payoff cerita + satu
## kalimat faktual + tombol kembali ke menu / main lagi. Menggantikan
## label teks satu baris yang dulu cuma bilang shift selesai.
func _build_end_panel() -> void:
	_end_panel = _panel_box(360)
	var box := _panel_column(_end_panel)
	_end_title = _label("", 26, Color(0.95, 0.9, 0.78))
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_end_title)
	_end_body = _label("", 17)
	_end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_end_body)
	var menu_btn := _big_button("Kembali ke Menu")
	menu_btn.pressed.connect(_on_end_menu_pressed)
	box.add_child(menu_btn)
	_end_replay_btn = _big_button("Main Lagi")
	_end_replay_btn.pressed.connect(_on_end_replay_pressed)
	box.add_child(_end_replay_btn)

func _on_end_menu_pressed() -> void:
	get_tree().paused = false
	_end_open = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_end_replay_pressed() -> void:
	get_tree().paused = false
	_end_open = false
	GameState.reset_shift()
	GameState.skip_intro = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# E menutup dokumen / intro yang sedang terbuka. Pemain dalam
	# keadaan pause, jadi E tidak sampai ke player (tidak memicu
	# interaksi kedua di belakang panel).
	# set_input_as_handled() WAJIB: _unhandled_input dipanggil dalam
	# urutan terbalik (anak terakhir dulu), jadi HUD menutup panel
	# DULU lalu event yang sama sampai ke player — tanpa ini, player
	# yang sudah tidak pause akan berinteraksi lagi dan membuka
	# dokumen yang sama persis (bug v12: E tidak bisa menutup surat).
	if event.is_action_pressed("interact"):
		if _doc_open:
			close_document()
			get_viewport().set_input_as_handled()
			return
		if _intro_open:
			close_intro()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause"):
		if _doc_open or _intro_open or _end_open:
			return
		toggle_pause()
		get_viewport().set_input_as_handled()

## Dipakai tombol II di TouchControls dan tombol ESC.
func toggle_pause() -> void:
	if GameState.shift_over:
		return
	_paused = not _paused
	get_tree().paused = _paused
	_pause_panel.visible = _paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _paused else Input.MOUSE_MODE_CAPTURED
	# v15: fokus ke Lanjutkan saat menu dibuka (keyboard/gamepad
	# langsung jalan); saat resume, fokus lepas bersama panel.
	if _paused:
		_resume_btn.grab_focus()

func _build_pause_menu() -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_panel.offset_left = -190
	_pause_panel.offset_right = 190
	_pause_panel.offset_top = -180
	_pause_panel.offset_bottom = 180
	_pause_panel.visible = false
	_pause_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_pause_panel.add_child(box)
	# v15: sentence case (dulu "JEDA" kapital di-track).
	var title := _label("Jeda", 28, Color(0.92, 0.88, 0.74))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_resume_btn = _big_button("Lanjutkan")
	_resume_btn.pressed.connect(toggle_pause)
	box.add_child(_resume_btn)
	_save_btn = _big_button("Simpan Shift")
	_save_btn.pressed.connect(_on_save_pressed)
	box.add_child(_save_btn)
	var quit_btn := _big_button("Keluar ke Menu")
	quit_btn.pressed.connect(_on_quit_pressed)
	box.add_child(quit_btn)
	# v15: kontrol diajarkan juga di sini — pemain yang lupa tombol
	# tidak perlu keluar ke menu untuk melihatnya.
	box.add_child(_controls_block(14))

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

func _notification(what: int) -> void:
	# v15: jendela kembali fokus (mis. habis Alt-Tab di Windows) —
	# kunci mouse lagi tanpa perlu klik atau petunjuk. Di desktop ini
	# langsung jalan; di web, pointer lock butuh gesture jadi
	# permintaan ini diabaikan browser dan klik pertama tetap
	# mengunci lewat player._input. Tidak jalan saat panel terbuka
	# (tombol butuh mouse VISIBLE).
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if not _paused and not _doc_open and not _intro_open and not _end_open and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	# REC berkedip pelan seperti kamera CCTV rusak.
	_blink_t += delta
	if _rec_label:
		_rec_label.modulate.a = 0.55 + 0.45 * sin(_blink_t * 2.4)
	# v14: kamera ikut rusak saat Sanity rendah — grain naik, warna
	# makin sakit, vignette makin menutup. Di-ease lewat nilai yang
	# di-set tiap frame (k 0..1 dari Sanity < 35).
	if _fx_mat != null:
		var k := 0.0
		if GameState.sanity < Balance.HEARTBEAT_SANITY_THRESHOLD:
			k = clampf((Balance.HEARTBEAT_SANITY_THRESHOLD - GameState.sanity) / Balance.HEARTBEAT_SANITY_THRESHOLD, 0.0, 1.0)
		# v18: grain mati (Settings) = 0 di semua Sanity, bukan cuma awal.
		var g0 := Balance.VHS_GRAIN if Settings.grain_on() else 0.0
		var g1 := Balance.VHS_GRAIN_LOW_SANITY if Settings.grain_on() else 0.0
		_fx_mat.set_shader_parameter("grain", lerpf(g0, g1, k))
		_fx_mat.set_shader_parameter("desat", lerpf(Balance.VHS_DESATURATE, Balance.VHS_DESAT_LOW_SANITY, k))
		_fx_mat.set_shader_parameter("vignette", lerpf(Balance.VHS_VIGNETTE, Balance.VHS_VIGNETTE_LOW_SANITY, k))
	# v14 (polish #8): slow pan selama intro — kamera menyapu pelan
	# +-6 derajat dalam 24 detik, kembali ke titik awal. Tree sedang
	# pause tapi HUD jalan (PROCESS_MODE_ALWAYS), jadi pan digerakkan
	# dari sini lewat apply_look; input mouse pemain sedang pause
	# sehingga tidak ada yang berebut yaw.
	if _intro_open and _player != null and _player.has_method("apply_look"):
		_intro_t += delta
		var target := deg_to_rad(6.0) * sin(_intro_t * TAU / 24.0)
		var d := target - _pan_yaw
		if absf(d) > 0.00005:
			_player.apply_look(d, 0.0)
			_pan_yaw = target
	# v15: tidak ada lagi label petunjuk di _process — dihapus.

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
	# Urutan label sama dengan urutan kunci tasks (insertion order),
	# jadi indeks ke-i selalu tugas yang sama di _build dan di sini.
	var i := 0
	for id in GameState.tasks.keys():
		if i >= _task_labels.size():
			break
		var t: Dictionary = GameState.tasks[id]
		var done := bool(t["done"])
		_task_labels[i].text = ("[x] " if done else "[ ] ") + str(t["label"])
		# Selesai = redup (muted), belum = terang. Bentuk [x]/[ ]
		# tetap yang membedakan, warna cuma penanda kedua.
		_task_labels[i].add_theme_color_override("font_color",
			Color(0.5, 0.48, 0.42) if done else Color(0.85, 0.83, 0.76))
		i += 1

func _on_shift_ended(success: bool) -> void:
	var reason := GameState.end_reason
	if success:
		_end_title.text = "06:00 — Fajar"
		_end_body.text = "Kamu masih di sini. Lampu pos masih menyala, laporan sudah tertulis, dan kabut akhirnya menipis. Di luar, hutan diam. Giant tidak pernah menampakkan dirinya utuh, dan pagi ini ia pergi seperti ia datang: tanpa penjelasan.\n\n" + CLOSING_FACT
	else:
		_end_title.text = "Shift Berakhir Sebelum Pagi"
		if reason == "sanity":
			_end_body.text = "Kamu menatap terlalu lama pada hal yang tidak seharusnya dilihat. Pagi datang, tapi pos jaga sudah kosong. Yang tertinggal hanya laporan setengah tertulis dan radio yang masih menyala.\n\n" + CLOSING_FACT
		else:
			_end_body.text = "Lampu padam dan gelap memakan pos ini sebelum pagi. Generator diam, lentera padam, dan kabut masuk lewat celah pintu.\n\n" + CLOSING_FACT
	_end_panel.visible = true
	_end_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# v15: fokus ke Main Lagi (aksi utama layar akhir).
	_end_replay_btn.grab_focus()
