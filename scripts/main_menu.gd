extends Control
## Menu utama THE GIANT — BUKU JAGA POS 07.
## Dibangun dari kode supaya menu.tscn tetap ramping.
## START = reset shift, masuk main.tscn (lewat intro).
## CONTINUE = load user://savegame.json (kalau ada), masuk main.tscn.
## OPTIONS = layar peralatan pos (pengaturan + cara main).
## EXIT = keluar dari game (disembunyikan di web: quit tidak
## menutup tab browser).
##
## v18 (arah unslop, tema buku jaga): menu INI buku jaga pos.
## Produk = daftar shift malam penjaga Pos 07, dibaca lewat kamera
## pos yang rusak. Karakter = tenang, waspada, birokratis.
## Dunia = buku log kertas + formulir ketikan + stempel karet,
## grain VHS, REC CAM 07, lentera. Momen = garis aturan buku
## (ruled line) di bawah judul + stempel REC. Signature = suara
## buku jaga: setiap teks adalah catatan di dunia (kepala log,
## catatan dinas, formulir peralatan), tidak pernah suara toko
## yang mendeskripsikan game.
## Footer blurb v15/v17 ("Sebuah cerita horor psikologis. Giant
## tidak pernah tampil utuh.") DIHAPUS — itu suara toko, bukan
## suara penjaga. Label tombol persis kata pemilik: Start,
## Continue, Options, Exit (bahasa Inggris karena begitu yang
## diminta; bukan pelanggaran sentence case, itu nama kanonik).
## v17: latar 3D hidup (scene main mode backdrop) tetap; sistem
## panel/tombol v15 tetap; stempel "● REC   CAM 07" tetap.
## v19: sprite Main UI — logo "THE GIANT" rusak VHS, panel kertas
## buku jaga (menu_ledger), tombol strip kertas (menu_btn*),
## dot REC + ikon lentera/jejak dari sheet Arya. Semua sprite baru
## digambar prosedural (tools/make_menu_sprites.py): PLACEHOLDER,
## bukan art final. Tombol default Godot sudah tidak ada lagi di
## menu utama; slider/check di Options masih default (dicatat di
## README, bukan disembunyikan).

var _menu_box: VBoxContainer
var _options_scroll: ScrollContainer
var _stamp: TextureRect
var _start_btn: Button
var _continue_btn: Button
var _options_btn: Button
var _exit_btn: Button
var _master_slider: HSlider
var _sens_slider: HSlider
var _fullscreen_check: CheckButton
var _grain_check: CheckButton
var _fx_mat: ShaderMaterial
var _ui_layer: CanvasLayer

## v22 ronde 2: font mono untuk seluruh menu (suara UI kamera,
## sesuai design read). Font default Godot adalah bagian paling
## generik kedua dari menu v18 setelah judul. DejaVu Sans Mono
## Bold (lisensi bebas, ikut di repo di assets/fonts/).
const MENU_FONT: Font = preload("res://assets/fonts/DejaVuSansMono-Bold.ttf")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# v18: pengaturan diterapkan dulu — volume bus, layar penuh —
	# sebelum menu dibangun, supaya menu sudah berbunyi/berukuran
	# seperti pilihan pemain dari frame pertama.
	Settings.apply_all()
	# v17: latar 3D hidup — scene main yang sama, mode backdrop
	# (main.gd: tidak ada shift/event/HUD, kamera menu sendiri).
	# Dibuat SEBELUM _build() supaya UI tergambar di atasnya; ikut
	# ter-free saat ganti scene, tidak ada yang bocor ke permainan.
	var level: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	level.name = "Backdrop"
	level.set_meta("menu_backdrop", true)
	add_child(level)
	# v17: VHS + UI tinggal di CanvasLayer layer 1 (pola yang sama
	# dengan HUD): fx digambar PERTAMA di layer itu, jadi
	# screen_texture-nya berisi 3D backdrop; UI ditambah setelahnya
	# supaya tetap bersih. fx di layer 0 (Control) TIDAK bisa membaca
	# screen_texture — sampelnya putih kosong (terbukti di rig v20:
	# mean_lum 0.625 dengan fx di layer 0, 0.108 tanpa fx).
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "MenuLayer"
	_ui_layer.layer = 1
	add_child(_ui_layer)
	_build_fx_and_stamp()
	_build_ledger()
	_build_menu_box()
	_build_options_box()
	_show_main()
	# Hook uji headless: jalankan menu dengan `-- menu_autostart=1`
	# untuk membuktikan tombol START masuk ke scene main.
	# `-- menu_test_exit=1` memanggil _on_exit untuk membuktikan
	# jalur keluar (proses harus berhenti, bukan jalan terus).
	for a in OS.get_cmdline_user_args():
		if str(a) == "menu_autostart=1":
			await get_tree().process_frame
			await get_tree().process_frame
			_on_new_game()
		elif str(a) == "menu_test_exit=1":
			await get_tree().process_frame
			await get_tree().process_frame
			_on_exit()

func _unhandled_input(event: InputEvent) -> void:
	# v18: Esc di layar Options kembali ke menu utama.
	if _options_scroll.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		_show_main()
		get_viewport().set_input_as_handled()

func _build_fx_and_stamp() -> void:
	# v17: latar belakang BUKAN lagi ColorRect hitam — di belakang
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
	# v18: grain ikut Settings — mati = 0, bukan bawaan.
	sm.set_shader_parameter("grain", Balance.VHS_GRAIN if Settings.grain_on() else 0.0)
	sm.set_shader_parameter("scanline", Balance.VHS_SCANLINE)
	sm.set_shader_parameter("ca", Balance.VHS_CA)
	sm.set_shader_parameter("desat", Balance.VHS_DESATURATE)
	sm.set_shader_parameter("vignette", Balance.VHS_VIGNETTE)
	sm.set_shader_parameter("flicker", Balance.VHS_FLICKER)
	sm.set_shader_parameter("tear_shift", Balance.VHS_TEAR_SHIFT)
	fx.material = sm
	_fx_mat = sm
	_ui_layer.add_child(fx)
	# Vignette tipis di menu supaya tidak terasa seperti layar kosong.
	var vig := ColorRect.new()
	vig.color = Color(0, 0, 0, 0.35)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(vig)
	# v19: stempel REC sebagai dot sprite + teks (dulu satu Label
	# dengan karakter "●"). Satu detail signature yang mengikat
	# menu dan game. Bukan dekorasi baru, tapi identitas yang
	# sudah ada dipakai konsisten.
	var rec_row := HBoxContainer.new()
	rec_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rec_row.offset_left = 18
	rec_row.offset_right = 220
	rec_row.offset_top = 12
	rec_row.offset_bottom = 40
	rec_row.add_theme_constant_override("separation", 8)
	rec_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(rec_row)
	var rec_dot := TextureRect.new()
	rec_dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rec_dot.texture = SpriteRegistry.texture("menu_rec_v20")
	rec_dot.custom_minimum_size = Vector2(22, 22)
	rec_dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rec_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rec_row.add_child(rec_dot)
	var rec := Label.new()
	rec.text = "REC   CAM 07"
	rec.add_theme_font_override("font", MENU_FONT)
	rec.add_theme_font_size_override("font_size", 16)
	rec.add_theme_color_override("font_color", Color(0.85, 0.25, 0.15))
	rec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rec_row.add_child(rec)

## v19: kertas buku jaga di belakang kolom menu (dan Options —
## keduanya di kolom yang sama, jadi satu panel cukup). Panel
## polos sudah tidak ada: teks menu sekarang duduk di atas kertas,
## bukan melayang di atas backdrop 3D.
func _build_ledger() -> void:
	var ledger := TextureRect.new()
	ledger.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ledger.texture = SpriteRegistry.texture("menu_ledger_v20")
	ledger.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	ledger.offset_left = 88
	ledger.offset_right = 548
	ledger.offset_top = -290
	ledger.offset_bottom = 290
	ledger.stretch_mode = TextureRect.STRETCH_SCALE
	ledger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(ledger)
	# v20: cap basah POS 07 sebagai node terpisah di sudut bawah kanan
	# kertas (bukan bagian dari tekstur ledger — di Options, teks
	# instruksi yang di-scroll menimpa posisi stempel). Hanya tampil
	# di menu utama; _show_options menyembunyikannya.
	_stamp = TextureRect.new()
	_stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stamp.texture = SpriteRegistry.texture("menu_stamp_v20")
	_stamp.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_stamp.offset_left = 400
	_stamp.offset_right = 510
	_stamp.offset_top = 240
	_stamp.offset_bottom = 290
	_stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_stamp)

func _build_menu_box() -> void:
	# v18: kolom kiri yang sama dengan v17 (88..548, split
	# asimetris: teks kiri, pos jaga hidup di kanan frame). Isinya
	# kepala buku jaga, bukan blurb toko.
	_menu_box = VBoxContainer.new()
	_menu_box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_menu_box.offset_left = 88
	_menu_box.offset_right = 548
	_menu_box.offset_top = -290
	_menu_box.offset_bottom = 290
	_menu_box.add_theme_constant_override("separation", 14)
	_ui_layer.add_child(_menu_box)

	# Kepala buku jaga: label kecil, tanpa titik — bukan paragraf.
	# (v22 ronde 2: lentera kecil di baris ini dihapus — pada 16x32
	# ia terbaca sebagai bintik debu, bukan lentera. Lentera tetap
	# ada sebagai ikon tombol Continue saat ada simpanan.)
	var head := _label("Buku jaga, Pos 07", 14, Color(0.6, 0.58, 0.5))
	_menu_box.add_child(head)

	# v19: logo judul sebagai sprite (huruf berat + rusak VHS),
	# bukan Label font default. Font default Godot di judul adalah
	# bagian paling generik dari menu v18.
	var logo := TextureRect.new()
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.texture = SpriteRegistry.texture("menu_logo_v20")
	logo.custom_minimum_size = Vector2(460, 124)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo.stretch_mode = TextureRect.STRETCH_SCALE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_box.add_child(logo)

	# Garis aturan buku (ruled line): pembatas kepala dan isi log.
	var rule := HSeparator.new()
	rule.custom_minimum_size = Vector2(0, 2)
	var rule_sb := StyleBoxFlat.new()
	rule_sb.bg_color = Color(0.45, 0.42, 0.34)
	rule.add_theme_stylebox_override("separator", rule_sb)
	_menu_box.add_child(rule)

	# Catatan dinas: tempat + jam shift + perintah jaga. Semua
	# kalimat sudah ada di game (subtitle pembuka shift), bukan
	# karangan baru — dipindah ke kepala log supaya menu berbunyi
	# seperti buku, bukan seperti halaman toko.
	var sub := _label("Taman Nasional Malayunesia.\nShift malam 22:00 - 06:00.\n\nJaga pos ini. Jangan biarkan mereka kembali.", 17, Color(0.75, 0.73, 0.66))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_box.add_child(sub)

	# v18: empat tombol persis kata pemilik. Start = shift baru
	# (lewat intro), Continue = lanjutkan simpanan, Options =
	# peralatan pos, Exit = keluar.
	_start_btn = _menu_button("Start")
	_start_btn.pressed.connect(_on_new_game)
	_menu_box.add_child(_start_btn)

	_continue_btn = _menu_button("Continue")
	_continue_btn.pressed.connect(_on_continue)
	_menu_box.add_child(_continue_btn)
	_refresh_continue()

	_options_btn = _menu_button("Options")
	_options_btn.pressed.connect(_show_options)
	_menu_box.add_child(_options_btn)

	_exit_btn = _menu_button("Exit")
	_exit_btn.pressed.connect(_on_exit)
	# Web: quit tidak menutup tab browser, jadi tombolnya
	# disembunyikan (bukan di-disable — tidak ada yang bisa dilakukan).
	_exit_btn.visible = not OS.has_feature("web")
	_menu_box.add_child(_exit_btn)

	# Jejak kaki dari sheet Arya di bawah tombol: penanda bahwa
	# seseorang sudah lewat sini sebelum pemain. Samar, miring.
	var track := TextureRect.new()
	track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	track.texture = SpriteRegistry.texture("footprint")
	track.custom_minimum_size = Vector2(42, 38)
	track.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	track.rotation = -0.3
	track.modulate = Color(1, 1, 1, 0.5)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_box.add_child(track)

func _build_options_box() -> void:
	# v18: layar peralatan pos — pengaturan yang benar-benar jalan
	# + cara main. Satu kolom yang sama dengan menu (88..548),
	# bisa di-scroll: isinya lebih panjang dari 560px.
	_options_scroll = ScrollContainer.new()
	_options_scroll.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_options_scroll.offset_left = 88
	_options_scroll.offset_right = 548
	_options_scroll.offset_top = -290
	_options_scroll.offset_bottom = 290
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_options_scroll.visible = false
	_ui_layer.add_child(_options_scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	_options_scroll.add_child(box)

	box.add_child(_label("Peralatan pos", 22, Color(0.95, 0.9, 0.78)))
	box.add_child(_section_label("Suara"))
	_master_slider = _slider_row(box, "Suara utama", 0.0, 1.0, 0.01, Settings.vol("Master"),
		func(v: float, val: Label) -> void:
			Settings.set_vol("Master", v)
			val.text = _pct(v))
	_slider_row(box, "Suara sekitar", 0.0, 1.0, 0.01, Settings.vol("Ambience"),
		func(v: float, val: Label) -> void:
			Settings.set_vol("Ambience", v)
			val.text = _pct(v))
	_slider_row(box, "Suara efek", 0.0, 1.0, 0.01, Settings.vol("SFX"),
		func(v: float, val: Label) -> void:
			Settings.set_vol("SFX", v)
			val.text = _pct(v))
	_slider_row(box, "Suara radio", 0.0, 1.0, 0.01, Settings.vol("Voice"),
		func(v: float, val: Label) -> void:
			Settings.set_vol("Voice", v)
			val.text = _pct(v))
	box.add_child(_section_label("Kamera dan layar"))
	_sens_slider = _slider_row(box, "Sensitivitas mouse", 0.5, 2.0, 0.1, Settings.mouse_sens(),
		func(v: float, val: Label) -> void:
			Settings.set_mouse_sens(v)
			val.text = "%.1fx" % v)
	_fullscreen_check = _toggle_row("Layar penuh", Settings.fullscreen(),
		func(on: bool) -> void: Settings.set_fullscreen(on))
	box.add_child(_fullscreen_check)
	_grain_check = _toggle_row("Grain film", Settings.grain_on(),
		func(on: bool) -> void:
			Settings.set_grain(on)
			_apply_grain_to_menu())
	box.add_child(_grain_check)
	# v18: "Cara main" pindah ke sini dari menu utama — menu utama
	# tinggal empat tombol. Isi + keycap sama dengan intro/jeda.
	box.add_child(_section_label("Cara main"))
	box.add_child(_controls_block(15))
	var how := _label("Nyalakan generator, cek radio, tulis laporan di buku jaga.\nKalau ada yang berdiri diam di luar dan menatap pos: tutup pintu, tunggu di dalam.\nJangan lihat matanya.\n\nDi layar sentuh: joystick kiri untuk jalan, geser kanan untuk melihat,\ntombol E untuk interaksi, SENTER untuk senter.", 15, Color(0.7, 0.68, 0.6))
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(how)

	var back_btn := _menu_button("Kembali")
	back_btn.pressed.connect(_show_main)
	box.add_child(back_btn)

func _section_label(text: String) -> Label:
	# Label seksi formulir: kecil, redup, tanpa titik.
	return _label(text, 16, Color(0.6, 0.58, 0.5))

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_override("font", MENU_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Satu baris slider: label kiri (lebar tetap), slider membentang,
## nilai kanan rata kanan. Nilai langsung diterapkan saat digeser.
func _slider_row(box: VBoxContainer, label_text: String, min_v: float, max_v: float, step: float, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var lab := _label(label_text, 16, Color(0.75, 0.73, 0.66))
	lab.custom_minimum_size = Vector2(140, 0)
	row.add_child(lab)
	var sl := HSlider.new()
	sl.min_value = min_v
	sl.max_value = max_v
	sl.step = step
	sl.value = value
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 28)
	# Fokus keyboard harus kelihatan (garis kuning, sama dengan tombol).
	sl.add_theme_stylebox_override("focus", _focus_style())
	row.add_child(sl)
	var val := Label.new()
	val.custom_minimum_size = Vector2(52, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_override("font", MENU_FONT)
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(val)
	sl.value_changed.connect(func(v: float) -> void: on_change.call(v, val))
	on_change.call(value, val)
	return sl

## Satu baris saklar: CheckButton dengan gaya yang sama (font +
## fokus kuning). Nilai langsung diterapkan saat diubah.
func _toggle_row(label_text: String, pressed: bool, on_change: Callable) -> CheckButton:
	var cb := CheckButton.new()
	cb.text = label_text
	cb.button_pressed = pressed
	cb.add_theme_font_override("font", MENU_FONT)
	cb.add_theme_font_size_override("font_size", 16)
	cb.add_theme_color_override("font_color", Color(0.75, 0.73, 0.66))
	cb.add_theme_stylebox_override("focus", _focus_style())
	cb.toggled.connect(func(on: bool) -> void: on_change.call(on))
	return cb

func _focus_style() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color(0.95, 0.85, 0.45)
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(2)
	return focus

func _pct(v: float) -> String:
	return "%d%%" % int(roundf(v * 100.0))

func _apply_grain_to_menu() -> void:
	if _fx_mat != null:
		_fx_mat.set_shader_parameter("grain", Balance.VHS_GRAIN if Settings.grain_on() else 0.0)

## v15: blok daftar kontrol (2 baris x 3 pasangan keycap + aksi).
## Salinan pola hud.gd _controls_block — menu tidak bisa memakai
## metode HUD (node lain), jadi polanya diduplikasi, bukan diimpor.
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

## v15: satu tombol keyboard sebagai keycap kecil (unslop §7):
## kotak gelap, pinggir tipis, radius 3. Sama dengan hud.gd.
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

func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_override("font", MENU_FONT)
	b.add_theme_font_size_override("font_size", 20)
	# v19: strip kertas dari sprite (normal/hover/pressed beda
	# jelas), bukan StyleBoxFlat polos. Tombol default Godot sudah
	# tidak ada lagi di menu utama.
	var normal := StyleBoxTexture.new()
	normal.texture = SpriteRegistry.texture("menu_btn_v20")
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover := StyleBoxTexture.new()
	hover.texture = SpriteRegistry.texture("menu_btn_v20_hover")
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	var pressed := StyleBoxTexture.new()
	pressed.texture = SpriteRegistry.texture("menu_btn_v20_pressed")
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", _focus_style())
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	b.add_theme_color_override("font_hover_color", Color(0.96, 0.92, 0.8))
	b.add_theme_color_override("font_pressed_color", Color(0.85, 0.8, 0.66))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.43, 0.38))
	return b

func _show_options() -> void:
	_menu_box.visible = false
	_stamp.visible = false
	_options_scroll.visible = true
	# game-ui-ux: satu kontrol fokus saat layar dibuka.
	_master_slider.grab_focus()

func _show_main() -> void:
	_options_scroll.visible = false
	_menu_box.visible = true
	_stamp.visible = true
	# game-ui-ux: fokus kembali ke tombol utama saat layar atas ditutup.
	_start_btn.grab_focus()

func _refresh_continue() -> void:
	if SaveGame.has_save():
		_continue_btn.text = SaveGame.summary_text()
		_continue_btn.disabled = false
		# v19: lentera menyala di tombol lanjutkan — penanda ada
		# shift yang belum selesai. Ikon diskalakan ke tinggi tombol.
		_continue_btn.icon = SpriteRegistry.texture("lantern")
		_continue_btn.expand_icon = true
	else:
		# Catatan buku jaga untuk shift yang tidak ada: tidak ada
		# simpanan yang bisa dilanjutkan.
		_continue_btn.text = "Continue - no record on file"
		_continue_btn.disabled = true
		_continue_btn.icon = null

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

func _on_exit() -> void:
	get_tree().quit()
