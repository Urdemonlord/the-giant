extends Control
## Menu utama THE GIANT v24 — Opsi B (diegetic, meja pos jaga).
## Rebuild konsep (bukan poles) atas kritik desain 2026-11-18:
## menu v17-v21 mencampur dua arah visual (layar CCTV REC CAM 07 +
## kertas fisik ditempel rata) dan kertasnya mengambang di atas
## backdrop. v22 memilih SATU arah: kamera menyorot MEJA KAYU pos
## jaga di depan jendela selatan (lihat main.gd _setup_menu_backdrop).
## Buku jaga terbuka tergeletak di atas meja, lentera fisik menyala
## di sampingnya, hutan gelap + Giant di luar jendela. Buku itu
## sendiri adalah menu-nya: klik baris tulisan di halaman untuk
## memilih. Lentera sudah ada sebagai benda di meja, bukan ikon.
##
## v24 (kritik kedua 2026-11-18, list Luci: game-ui-ux,
## create-game-assets, unslop): SEMUA teks statis sekarang DI-BAKE
## ke tekstur halaman (tools/make_menu_book_v24.py, multiply tinta
## gelap di atas foto perkamen asli) — bukan lagi Label3D yang
## ditempel rata di atas kertas. Tiga alasan: (1) lipatan gelap
## diagonal di halaman kanan sudah tidak menabrak Continue/Options
## (zona teks diratakan dulu di generator); (2) teks menyatu dengan
## serat kertas (ink blend), bukan teks UI digital; (3) CA yang
## tersisa dari sprite logo v20 ikut hilang (warnanya tidak dipakai
## lagi, hanya mask alpha-nya). Satu-satunya Label3D yang tersisa
## adalah sub Continue yang DINAMIS (ringkasan save, baru ada kalau
## pemain punya save) — teks statis "no record on file" ikut
## di-bake ke varian halaman mati. Bar sorot kuning solid DIGANTI
## outline tinta merah (4 quad tipis di sekeliling baris) — sorot
## pilihan sekarang coretan tinta, bukan bar UI.
##
## Yang dihapus dari menu (bukan disembunyikan): label REC CAM 07 +
## dot REC, overlay scanline/tear CCTV, ikon lentera di tombol
## Continue, stempel/coretan merah di bawah Exit, jejak kaki di bawah
## tombol, panel kertas tempel + tombol strip kertas. HUD di dalam
## game BOLEH tetap VHS — yang dihapus hanya di menu.
## Yang dijawab dari kritik: (1) baris menu jadi tulisan dengan
## highlight redup saat hover — zona teks halaman dibuat tenang
## (blur tengah) supaya tidak bertabrakan dengan kerut foto;
## (2) "Buku jaga, Pos 07" masuk ke dalam halaman paling atas dengan
## tinta gelap (mesin tik), padding lega di sekitar judul, garis
## merah diberi jarak dari judul; (3) satu arah visual (meja), tanpa
## CCTV; (4) ambient lebih gelap + bulan dikuatkan jadi rim light
## (di main.gd, bukan di sini).
##
## Cara kerja: teks menu adalah tinta di tekstur halaman buku 3D
## (cover + 2 halaman dari foto perkamen asli v20). Klik/hover
## dihitung dari raycast kamera menu ke bidang meja (lihat
## _ray_to_book) — bukan tombol Control. Keyboard tetap jalan
## (atas/bawah + Enter). Layar Options tetap formulir Control (lembar
## formulir di atas meja) supaya slider/toggle tetap bisa dipakai;
## ia memakai tekstur kertas yang sama + tinta gelap.
##
## START = reset shift, masuk main.tscn (lewat intro).
## CONTINUE = load user://savegame.json (kalau ada), masuk main.tscn.
## OPTIONS = layar peralatan pos (pengaturan + cara main).
## EXIT = keluar dari game (disembunyikan di web: quit tidak
## menutup tab browser).

var _options_scroll: ScrollContainer
var _master_slider: HSlider
var _sens_slider: HSlider
var _fullscreen_check: CheckButton
var _grain_check: CheckButton
var _fx_mat: ShaderMaterial
var _ui_layer: CanvasLayer

## v22: buku jaga 3D di atas meja (bukan panel Control).
## Geometri meja: tengah (-1.30, 1.11, 1.35), 2,2 x 0,8. Buku
## 2,0 x 0,70 menutupi hampir seluruh meja; halaman kiri
## x -2,27..-1,31, halaman kanan x -1,29..-0,33; z 0,95..1,61.
## y: cover 1,1175 (puncak 1,125), halaman 1,130, highlight 1,133,
## teks 1,136. Jarak antar lapis 0,003-0,005: cukup untuk hindari
## z-fighting, cukup rapat untuk terlihat menempel di halaman.
const BOOK_CENTER := Vector3(-1.30, 1.13, 1.28)
const PAGE_Y := 1.130
const HIGHLIGHT_Y := 1.133
const TEXT_Y := 1.136
const INK := Color(0.13, 0.10, 0.07) # tinta gelap (mesin tik)
const INK_BODY := Color(0.22, 0.19, 0.15) # tinta isi (sub-teks)
const INK_RULE := Color(0.45, 0.13, 0.08) # garis merah (tinta)
## v24: bar sorot kuning solid (v22-v23) DIGANTI outline tinta
## merah: 4 quad tipis membentuk bingkai di sekeliling baris yang
## di-hover/dipilih — coretan tinta, bukan bar UI. Warna sama
## dengan garis merah di bawah judul (INK_RULE), alpha 0,35 hover /
## 0,70 pilihan. Teks di-bake ke halaman (lihat header), jadi
## tidak ada lagi label yang perlu di-sorot.
const BAR_HOVER := 0.70
const BAR_SEL := 1.0
## Halaman kanan, disimpan supaya _refresh_continue bisa menukar
## teksturnya antara varian aktif / mati (Continue di-bake di
## tekstur, bukan Label3D lagi).
var _page_right: Sprite3D

## Baris menu: nama, pusat (x, z di bidang meja), setengah ukuran
## (x, z), aksi. Kiri-kanan halaman kanan (x -1,27..-0,35).
var _rows: Array = []
var _hovered := ""
var _selected := 0

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
	# (main.gd: tidak ada shift/event/HUD, kamera meja sendiri).
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
	_build_grade()
	_build_book()
	_build_book_text()
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

## v22: grade halus, BUKAN bingkai CCTV. Shader VHS yang sama
## dipakai HUD, tapi parameternya dimatikan satu per satu: tidak ada
## scanline, tidak ada tracking tear, tidak ada flicker; grain kecil
## saja (ikut Settings), desat + CA + vignette tipis sebagai grade
## foto, bukan sebagai layar monitor rusak.
func _build_grade() -> void:
	var fx := ColorRect.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.color = Color(1, 1, 1, 1)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/vhs.gdshader") as Shader
	sm.set_shader_parameter("grain", Balance.MENU_GRADE_GRAIN if Settings.grain_on() else 0.0)
	sm.set_shader_parameter("scanline", Balance.MENU_GRADE_SCANLINE)
	sm.set_shader_parameter("ca", Balance.MENU_GRADE_CA)
	sm.set_shader_parameter("desat", Balance.MENU_GRADE_DESAT)
	sm.set_shader_parameter("vignette", Balance.MENU_GRADE_VIGNETTE)
	sm.set_shader_parameter("flicker", Balance.MENU_GRADE_FLICKER)
	sm.set_shader_parameter("tear_shift", Balance.MENU_GRADE_TEAR)
	fx.material = sm
	_fx_mat = sm
	_ui_layer.add_child(fx)

func _menu_camera() -> Camera3D:
	return get_node_or_null("Backdrop/MenuCamera") as Camera3D

## --- Buku jaga 3D ----------------------------------------------------------
## Cover kulit gelap + 2 halaman foto perkamen (v22, dari foto asli
## yang sama dengan ledger v20) + garis lipatan tengah. Halaman
## adalah Sprite3D DATAR (SpriteRegistry.flat): tepi atas tekstur ke
## arah +z, terbaca benar dari sisi -z (kursi di depan meja) — sama
## seperti buku jaga kecil di dalam permainan. Halaman di-shade
## supaya cahaya lentera hangat benar-benar jatuh di atasnya.
func _build_book() -> void:
	var backdrop := get_node_or_null("Backdrop") as Node3D
	if backdrop == null:
		push_error("[Menu] Backdrop tidak ada, buku tidak dibangun")
		return
	var cover_mat := StandardMaterial3D.new()
	cover_mat.albedo_color = Color(0.09, 0.07, 0.05)
	cover_mat.roughness = 0.9
	var cover := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(2.02, 0.015, 0.72)
	cover.mesh = cb
	cover.position = Vector3(BOOK_CENTER.x, 1.1175, BOOK_CENTER.z)
	cover.material_override = cover_mat
	backdrop.add_child(cover)
	# Garis lipatan tengah (bayangan jilid).
	var spine_mat := StandardMaterial3D.new()
	spine_mat.albedo_color = Color(0.05, 0.04, 0.03)
	spine_mat.roughness = 1.0
	var spine := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.03, 0.006, 0.70)
	spine.mesh = sb
	spine.position = Vector3(-1.30, 1.131, BOOK_CENTER.z)
	spine.material_override = spine_mat
	backdrop.add_child(spine)
	# Halaman kiri + kanan (0,96 x 0,66: tekstur persegi di-squash
	# di sumbu z supaya muat di meja 0,80 — kerut kertas sedikit
	# melebar horizontal, tidak masalah untuk kertas).
	# v25: kiri-kanan halaman DITUKAR dari dugaan awal. Kamera
	# menghadap selatan (+z), jadi +x adalah KIRI pembaca: halaman
	# kiri (judul) ada di x -0,81, halaman kanan (baris menu) di
	# x -1,79. Sebelumnya terbalik (buku terbaca judul di kanan).
	for side in ["l", "r"]:
		var page := SpriteRegistry.flat("menu_book_page_" + side + "_v25", 0.96 / 1024.0)
		if page == null:
			continue
		if side == "r":
			_page_right = page
		page.shaded = true
		# v25 ronde 2: alpha_cut DISCARD, bukan blending transparan.
		# Sprite3D transparan di-sort berdasarkan jarak dari kamera:
		# halaman (pusat z 1,28) lebih dekat dari teks di tepi jauh
		# buku (z 1,39-1,54), jadi halaman digambar SETELAH teks dan
		# menutupinya — header, logo, Start, Continue hilang total
		# di dua screenshot v25 pertama, padahal sub-baris di tepi
		# dekat (z < 1,3) terbaca. Dengan discard, halaman jadi
		# opaque (piksel alpha < 0,5 dibuang, sisanya penuh) dan
		# depth test yang menentukan: teks di y 1,136 di atas halaman
		# y 1,130 selalu menang. Tepi sobek tetap bekerja (alpha 0
		# dibuang), hanya sedikit lebih keras.
		page.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		page.scale = Vector3(1.0, 0.6875, 1.0)
		page.position = Vector3(-0.81 if side == "l" else -1.79, PAGE_Y, BOOK_CENTER.z)
		backdrop.add_child(page)

## Satu Label3D tinta di atas halaman: tergeletak menghadap atas,
## puncak huruf ke +z (selatan, menjauhi kamera di utara) supaya
## terbaca benar dari kursi. Rotasi SAMA dengan SpriteRegistry.flat
## (-90 X, lalu 180 Z) dengan alasan yang sama.
## v25: UNSHADED (dulu shaded=true). Tinta gelap di bawah lentera
## (0,3 m, energi 1,2) ikut terbakar sampai putih — header + logo
## di tepi jauh buku hilang total di screenshot v25 pertama. Tinta
## tidak menyala sendiri: warnanya konstan (0,13), kertasnya yang
## menerima cahaya. Jadi teks selalu terbaca, terang atau gelap.
func _book_label(text: String, font_size: int, pixel: float, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = MENU_FONT
	l.font_size = font_size
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 0
	l.shaded = false
	l.rotation = Vector3(-PI * 0.5, 0, PI)
	return l

## Satu baris menu: bar merah pilihan + (opsional) sub-baris
## dinamis. v25 (mockup Arya): teks baris ("Start", "Continue",
## "Options", "Exit") tetap DI-BAKE ke tekstur halaman kanan
## (tools/make_menu_book_v25.py, tinta gelap multiply) — baris
## adalah data, bukan Button; klik/hover lewat raycast
## (_ray_to_book), keyboard lewat ui_up/ui_down/ui_accept.
## Baris terpilih/hover DITUTUPI sprite bar merah
## (menu_bar_<row>_v25.png, 900x150): bar tinta merah + teks
## TERANG di posisi yang sama persis dengan teks bake gelap +
## segitiga play di Start — menggantikan outline tinta merah v24
## (bingkai 4 quad). Bar: SpriteRegistry.flat (rotasi sama dengan
## halaman), squash z 0,6875 yang sama, y 1,133 di atas halaman
## 1,130, unshaded (merah mockup konstan, tidak ikut lentera),
## alpha blending (bukan DISCARD) supaya hover 0,70 vs terpilih
## 1,0 benar-benar beda. render_priority default: baris terpilih
## tidak pernah menutupi sub-teks dinamis Continue (z 1,245,
## di luar bar z 1,272..1,368).
func _add_row(row_name: String, center: Vector3, half: Vector2,
		action: Callable) -> Dictionary:
	var backdrop := get_node_or_null("Backdrop") as Node3D
	var bar := SpriteRegistry.flat("menu_bar_" + row_name.to_lower() + "_v25", 0.96 / 1024.0)
	if bar != null:
		bar.scale = Vector3(1.0, 0.6875, 1.0)
		bar.position = Vector3(center.x, HIGHLIGHT_Y, center.z)
		bar.shaded = false
		bar.visible = false
		backdrop.add_child(bar)
	var row := {
		"name": row_name, "center": center, "half": half,
		"sub": null, "bar": bar,
		"action": action, "enabled": true,
	}
	_rows.append(row)
	return row

## Sub-baris DINAMIS (hanya Continue): ringkasan save, baru ada
## kalau pemain punya save. Dibuat kosong — _refresh_continue
## yang mengisi/mengosongkannya. Teks statis "no record on this slot"
## TIDAK lagi di sini: ia di-bake ke varian halaman mati.
func _add_sub(row: Dictionary, z: float) -> void:
	var backdrop := get_node_or_null("Backdrop") as Node3D
	var sub := _book_label("", 22, 0.0022, INK_BODY)
	sub.position = Vector3((row["center"] as Vector3).x, TEXT_Y, z)
	backdrop.add_child(sub)
	row["sub"] = sub

func _build_book_text() -> void:
	var backdrop := get_node_or_null("Backdrop") as Node3D
	if backdrop == null:
		return
	# v25: halaman kiri (logo THE GIANT + siluet kepala gajah,
	# "Buku jaga, Pos 07", garis merah, "Taman Nasional
	# Malayunesia.") semuanya DI-BAKE ke tekstur
	# menu_book_page_l_v25 — tidak ada lagi Label3D/logo/rule di
	# sini. Halaman kanan: empat baris menu di-bake ke tekstur;
	# yang dibangun di sini hanya data baris (rect klik/hover +
	# BAR MERAH pilihan) dan sub dinamis Continue.
	# Urutan baca atas-bawah = jauh-dekat: Start 1,48 / Continue
	# 1,32 (+ sub 1,245) / Options 1,16 / Exit 1,02. Batas rect
	# saling menempel tanpa tumpang tindih.
	_add_row("Start", Vector3(-1.79, TEXT_Y, 1.48), Vector2(0.46, 0.06), _on_new_game)
	var cont := _add_row("Continue", Vector3(-1.79, TEXT_Y, 1.32), Vector2(0.46, 0.10), _on_continue)
	_add_sub(cont, 1.245)
	_add_row("Options", Vector3(-1.79, TEXT_Y, 1.16), Vector2(0.46, 0.06), _show_options)
	_add_row("Exit", Vector3(-1.79, TEXT_Y, 1.02), Vector2(0.46, 0.06), _on_exit)
	_refresh_continue()

## --- Input: raycast ke bidang meja -----------------------------------------
## Klik/hover dihitung dari kamera menu ke bidang y = TEXT_Y. Bukan
## tombol Control: tidak ada Control di atas buku (yang ada hanya
## grade + formulir Options). Saat Options terbuka, input diserahkan
## ke formulir (return lebih awal) supaya slider/toggle bisa diklik.
func _input(event: InputEvent) -> void:
	if _options_scroll != null and _options_scroll.visible:
		return
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_click_at(mb.position)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_click_at(st.position)

func _unhandled_input(event: InputEvent) -> void:
	# v18: Esc di layar Options kembali ke menu utama.
	if _options_scroll.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		_show_main()
		get_viewport().set_input_as_handled()
		return
	if _options_scroll.visible:
		return
	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_activate_selected()
		get_viewport().set_input_as_handled()

func _ray_to_book(screen_pos: Vector2) -> Vector3:
	var cam := _menu_camera()
	if cam == null:
		return Vector3.INF
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return Vector3.INF
	var t := (TEXT_Y - from.y) / dir.y
	if t < 0.0:
		return Vector3.INF
	return from + dir * t

func _row_at(p: Vector3) -> Dictionary:
	for row in _rows:
		if not bool(row["enabled"]):
			continue
		var c := row["center"] as Vector3
		var h := row["half"] as Vector2
		if absf(p.x - c.x) <= h.x and absf(p.z - c.z) <= h.y:
			return row
	return {}

func _update_hover(screen_pos: Vector2) -> void:
	var p := _ray_to_book(screen_pos)
	var row := _row_at(p) if p != Vector3.INF else {}
	var row_name := str(row.get("name", ""))
	if row_name != _hovered:
		_hovered = row_name
		_refresh_highlights()

func _click_at(screen_pos: Vector2) -> void:
	var p := _ray_to_book(screen_pos)
	if p == Vector3.INF:
		return
	var row := _row_at(p)
	if row.is_empty():
		return
	_selected = _rows.find(row)
	_refresh_highlights()
	_pop_selection()
	(row["action"] as Callable).call()

func _move_selection(d: int) -> void:
	if _rows.is_empty():
		return
	var n := _rows.size()
	for i in range(n):
		_selected = (_selected + d + n) % n
		if bool(_rows[_selected]["enabled"]):
			break
	_refresh_highlights()
	_pop_selection()

func _activate_selected() -> void:
	if _rows.is_empty():
		return
	var row: Dictionary = _rows[_selected]
	if not bool(row["enabled"]):
		return
	(row["action"] as Callable).call()

## v23 (Luci: game-feel): pop kecil saat pilihan BERPINDAH
## (keyboard / klik), bukan saat hover — hover adalah aksi rutin,
## di-juice berlebihan bikin mual (skill). Pop 1,0 -> 1,05 ->
## 1,0, TRANS_BACK 0,18 dtk, tween lama di-kill supaya tidak
## bertarung, dan SELALU kembali tepat ke 1,0 (juice yang tidak
## kembali ke rest berhenti terbaca sebagai feedback).
var _pop_tween: Tween

func _pop_selection() -> void:
	if _rows.is_empty():
		return
	var bar := _rows[_selected]["bar"] as Node3D
	if bar == null:
		return
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	bar.scale = Vector3(1.0, 0.6875, 1.0)
	_pop_tween = bar.create_tween()
	_pop_tween.tween_property(bar, "scale", Vector3(1.05, 0.7219, 1.0), 0.09) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(bar, "scale", Vector3(1.0, 0.6875, 1.0), 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _refresh_highlights() -> void:
	for i in range(_rows.size()):
		var row: Dictionary = _rows[i]
		var bar := row["bar"] as Sprite3D
		# Baris mati (Continue tanpa save): tanpa bar — coret
		# + tinta redup SUDAH di-bake ke varian halaman mati,
		# bukan sinyal runtime lagi.
		if not bool(row["enabled"]):
			if bar != null:
				bar.visible = false
			continue
		var active := str(row["name"]) == _hovered or i == _selected
		if bar == null:
			continue
		bar.visible = active
		# v25: hover 0,70 (bar merah tembus pandang ringan),
		# terpilih 1,0 (bar penuh seperti mockup).
		bar.modulate = Color(1, 1, 1, BAR_SEL if i == _selected else BAR_HOVER)

## --- API untuk rig -----------------------------------------------------------
func row_names() -> Array[String]:
	var out: Array[String] = []
	for row in _rows:
		out.append(str(row["name"]))
	return out

func row_label(row_name: String) -> String:
	# v24: teks baris di-bake ke tekstur halaman — teks yang
	# terbaca SAMA dengan nama barisnya.
	for row in _rows:
		if str(row["name"]) == row_name:
			return str(row["name"])
	return ""

func row_enabled(row_name: String) -> bool:
	for row in _rows:
		if str(row["name"]) == row_name:
			return bool(row["enabled"])
	return false

func row_sub(row_name: String) -> String:
	for row in _rows:
		if str(row["name"]) == row_name:
			var sub := row["sub"] as Label3D
			if sub != null and str(sub.text) != "":
				return str(sub.text)
			# v24: "no record on file" di-bake ke varian halaman
			# mati, bukan Label3D lagi — tapi kontrak API rig
			# tetap: baris mati mengembalikan teks itu.
			if not bool(row["enabled"]):
				return "no record on this slot"
			return ""
	return ""

func screen_pos_for_row(row_name: String) -> Vector2:
	var cam := _menu_camera()
	if cam == null:
		return Vector2.ZERO
	for row in _rows:
		if str(row["name"]) == row_name:
			return cam.unproject_position(row["center"] as Vector3)
	return Vector2.ZERO

func activate_row(row_name: String) -> void:
	for row in _rows:
		if str(row["name"]) == row_name and bool(row["enabled"]):
			(row["action"] as Callable).call()
			return

func is_main_visible() -> bool:
	return _options_scroll == null or not _options_scroll.visible

func is_options_visible() -> bool:
	return _options_scroll != null and _options_scroll.visible

## Cari sisa-sisa CCTV di menu (dipakai rig): teks REC/CAM, dot REC.
## Hanya UI menu sendiri (_ui_layer: grade + formulir Options).
## Backdrop TIDAK dipindai: HUD permainan yang tersembunyi di
## dalamnya BOLEH tetap VHS (REC di sana bukan menu).
func has_cctv() -> bool:
	if _ui_layer == null:
		return false
	return _find_text(_ui_layer, ["REC", "CAM 07"])

func _find_text(node: Node, needles: Array) -> bool:
	if node is Label:
		var t := str((node as Label).text)
		for n in needles:
			if str(n) in t:
				return true
	for c in node.get_children():
		if _find_text(c, needles):
			return true
	return false

## --- Layar Options: lembar formulir -----------------------------------------
## Formulir Control di atas meja (lembar yang ditarik penjaga dari
## laci): latar kertas foto yang sama + tinta gelap. Slider + saklar
## di-skin ringan (bukan default abu-abu Godot lagi): track gelap,
## pegangan hangat, kotak centang tinta.
func _build_options_box() -> void:
	# v18: layar peralatan pos — pengaturan yang benar-benar jalan
	# + cara main. Satu kolom yang sama dengan menu, bisa di-scroll:
	# isinya lebih panjang dari layarnya.
	_options_scroll = ScrollContainer.new()
	_options_scroll.set_anchors_preset(Control.PRESET_CENTER)
	_options_scroll.offset_left = -230
	_options_scroll.offset_right = 230
	_options_scroll.offset_top = -290
	_options_scroll.offset_bottom = 290
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_options_scroll.visible = false
	var form_sb := StyleBoxTexture.new()
	form_sb.texture = SpriteRegistry.texture("menu_form_page")
	form_sb.content_margin_left = 30
	form_sb.content_margin_right = 30
	form_sb.content_margin_top = 24
	form_sb.content_margin_bottom = 24
	_options_scroll.add_theme_stylebox_override("panel", form_sb)
	_ui_layer.add_child(_options_scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	_options_scroll.add_child(box)

	box.add_child(_label("Peralatan pos", 22, INK))
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
	# tinggal empat baris. Isi + keycap sama dengan intro/jeda.
	box.add_child(_section_label("Cara main"))
	box.add_child(_controls_block(15))
	var how := _label("Nyalakan generator, cek radio, tulis laporan di buku jaga.\nKalau ada yang berdiri diam di luar dan menatap pos: tutup pintu, tunggu di dalam.\nJangan lihat matanya.\n\nDi layar sentuh: joystick kiri untuk jalan, geser kanan untuk melihat,\ntombol E untuk interaksi, SENTER untuk senter.", 15, INK_BODY)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(how)

	var back_btn := _menu_button("Kembali")
	back_btn.pressed.connect(_show_main)
	box.add_child(back_btn)

func _section_label(text: String) -> Label:
	# Label seksi formulir: kecil, redup, tanpa titik.
	return _label(text, 16, Color(0.35, 0.32, 0.27))

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
	var lab := _label(label_text, 16, INK_BODY)
	lab.custom_minimum_size = Vector2(140, 0)
	row.add_child(lab)
	var sl := HSlider.new()
	sl.min_value = min_v
	sl.max_value = max_v
	sl.step = step
	sl.value = value
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 28)
	# v22: track gelap + pegangan hangat (bukan default abu-abu).
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.16, 0.13, 0.10)
	track.set_corner_radius_all(2)
	track.content_margin_top = 10
	track.content_margin_bottom = 10
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_icon_override("grabber", _grabber_tex(Color(0.85, 0.66, 0.23)))
	sl.add_theme_icon_override("grabber_highlight", _grabber_tex(Color(0.96, 0.80, 0.35)))
	sl.add_theme_icon_override("grabber_disabled", _grabber_tex(Color(0.45, 0.43, 0.38)))
	# Fokus keyboard harus kelihatan (garis kuning, sama dengan tombol).
	sl.add_theme_stylebox_override("focus", _focus_style())
	row.add_child(sl)
	var val := Label.new()
	val.custom_minimum_size = Vector2(52, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_override("font", MENU_FONT)
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", INK)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(val)
	sl.value_changed.connect(func(v: float) -> void: on_change.call(v, val))
	on_change.call(value, val)
	return sl

func _grabber_tex(color: Color) -> ImageTexture:
	var img := Image.create(16, 28, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var edge := Color(0.12, 0.10, 0.08, 1)
	for x in range(16):
		for y in range(28):
			if x < 2 or x >= 14 or y < 2 or y >= 26:
				img.set_pixel(x, y, edge)
	return ImageTexture.create_from_image(img)

## Satu baris saklar: CheckButton dengan gaya yang sama (font +
## fokus kuning). Nilai langsung diterapkan saat diubah.
func _toggle_row(label_text: String, pressed: bool, on_change: Callable) -> CheckButton:
	var cb := CheckButton.new()
	cb.text = label_text
	cb.button_pressed = pressed
	cb.add_theme_font_override("font", MENU_FONT)
	cb.add_theme_font_size_override("font_size", 16)
	cb.add_theme_color_override("font_color", INK_BODY)
	cb.add_theme_icon_override("unchecked", _check_tex(false))
	cb.add_theme_icon_override("checked", _check_tex(true))
	cb.add_theme_stylebox_override("focus", _focus_style())
	cb.toggled.connect(func(on: bool) -> void: on_change.call(on))
	return cb

func _check_tex(checked: bool) -> ImageTexture:
	var img := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink := Color(0.13, 0.10, 0.07, 1)
	for x in range(18):
		for y in range(18):
			if x < 2 or x >= 16 or y < 2 or y >= 16:
				img.set_pixel(x, y, ink)
	if checked:
		var warm := Color(0.85, 0.66, 0.23, 1)
		for x in range(5, 13):
			for y in range(5, 13):
				img.set_pixel(x, y, warm)
	return ImageTexture.create_from_image(img)

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
		_fx_mat.set_shader_parameter("grain", Balance.MENU_GRADE_GRAIN if Settings.grain_on() else 0.0)

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
			cell.add_child(_label(str(pair[1]), size, INK_BODY))
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
	_hovered = ""
	_refresh_highlights()
	_options_scroll.visible = true
	# game-ui-ux: satu kontrol fokus saat layar dibuka.
	_master_slider.grab_focus()

func _show_main() -> void:
	_options_scroll.visible = false
	_selected = 0
	_refresh_highlights()
	# v22: tidak ada lagi tombol Control di menu utama, jadi tidak
	# ada grab_focus ke tombol — navigasi keyboard lewat _selected.

func _refresh_continue() -> void:
	# v25: baris Continue membawa info simpanan di DUA tempat —
	# tekstur halaman kanan (varian aktif vs mati) + sub Label3D
	# dinamis (ringkasan save). Kalau ada save: halaman aktif +
	# sub "22:00, Sanity 100". Kalau tidak ada: halaman mati
	# (Continue tinta redup + coret + "no record on this slot"
	# di-bake) + sub kosong.
	for row in _rows:
		if str(row["name"]) != "Continue":
			continue
		var sub := row["sub"] as Label3D
		if SaveGame.has_save():
			row["enabled"] = true
			if _page_right != null:
				_page_right.texture = SpriteRegistry.texture("menu_book_page_r_v25")
			if sub != null:
				sub.text = SaveGame.summary_text().replace("Continue - ", "")
				sub.modulate = INK_BODY
		else:
			row["enabled"] = false
			if _page_right != null:
				_page_right.texture = SpriteRegistry.texture("menu_book_page_r_disabled_v25")
			if sub != null:
				sub.text = ""
		break

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
