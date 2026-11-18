extends Node
## Verifikasi cepat menu v26 (list Luci) — TANPA pan 6,5 dtk rig penuh.
## Dipakai saat CPU sempit (llvmpipe + kerja lain): buka menu, tunggu
## 12 frame, cek poin v26 (kepala Zunisha UTUH + bar merah + elemen tempat)
## + screenshot, keluar. Rig penuh
## (menu_shot.gd) tetap sumber PASS/FAIL lengkap; skrip ini hanya
## jalan pintas bukti visual + cek API yang sama.
## Jalankan: Xvfb :98, --resolution 1280x720 (desktop, prefix v29)
## atau 720x1280 (portrait, prefix v29p), scene menu_quick.tscn.
## Argumen `-- menu_with_save=1` membuat save dummy SEBELUM menu
## dibangun (Continue hidup, halaman kanan varian aktif); tanpa
## argumen, Continue mati (halaman kanan varian mati, coret di-bake).
##
## Beda dari v23: teks menu di-BAKE ke tekstur halaman, jadi tidak
## ada lagi Label3D baris / strike quad / bar sorot kuning yang bisa
## dicek sebagai node. Yang dicek sekarang: tekstur halaman kanan
## (aktif vs mati), outline tinta merah (bukan bar kuning), lentera
## di luar kertas (x < -2,27), kepala Zunisha di viewport, dan piksel
## tinta gelap di sekitar logo + baris Start (bukti visual bahwa
## teks bake terbaca).
const SHOT_DIR := "/home/hatch/workspace/godot/shots"
const RES_PATH := "res://scenes/menu.tscn"

var _prefix := "v29"
var _passes := 0
var _fails := 0
var _menu: Control
var _frames := 0
var _with_save := false
var _done := false

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	for a in OS.get_cmdline_user_args():
		if str(a) == "menu_with_save=1":
			_with_save = true
	if get_tree().root.size.y > get_tree().root.size.x:
		_prefix = "v29p"
	if _with_save:
		GameState.shift_minutes = 123.0
		GameState.sanity = 80.0
		GameState.stability = 65.0
		GameState.fuel = 40.0
		GameState.generator_on = true
		SaveGame.save()
	else:
		SaveGame.clear()
	_menu = (load(RES_PATH) as PackedScene).instantiate()
	add_child(_menu)

func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 12 or _done:
		return
	_done = true
	var img := get_viewport().get_texture().get_image()
	_check_all(img)
	var tag := "menu_with_save" if _with_save else "menu_no_save"
	img.save_png(SHOT_DIR + "/" + _prefix + "_" + tag + ".png")
	print("[QUICK] " + str(_passes) + " pass, " + str(_fails) + " fail")
	if not _with_save:
		SaveGame.clear()
	get_tree().quit(0 if _fails == 0 else 1)

func _pass(msg: String) -> void:
	_passes += 1
	print("[QUICK] PASS " + msg)

func _fail(msg: String) -> void:
	_fails += 1
	print("[QUICK] FAIL " + msg)

func _cam() -> Camera3D:
	return _menu.get_node_or_null("Backdrop/MenuCamera") as Camera3D

func _check_all(img: Image) -> void:
	# 1. Baris menu ada.
	var names: Array[String] = _menu.row_names()
	if names == ["Start", "Continue", "Options", "Exit"]:
		_pass("baris menu: Start, Continue, Options, Exit")
	else:
		_fail("baris menu: " + str(names))
	# 2. Continue + halaman kanan: varian tekstur harus cocok dengan
	# ada/tidaknya save. Tanpa save: Continue mati, sub
	# "no record on this slot", halaman kanan varian MATI (coret di-bake).
	# Dengan save: Continue hidup, sub ringkasan, halaman AKTIF.
	var cont_enabled: bool = _menu.row_enabled("Continue")
	var sub: String = _menu.row_sub("Continue")
	var page_tex := ""
	var page_right := _menu._page_right as Sprite3D
	if page_right != null and page_right.texture != null:
		page_tex = str(page_right.texture.resource_path)
	if _with_save:
		if cont_enabled and sub != "" and sub != "no record on this slot" and "menu_book_page_r_v25" in page_tex and "disabled" not in page_tex:
			_pass("Continue hidup dengan save, sub '" + sub + "', halaman aktif")
		else:
			_fail("Continue dengan save: enabled=" + str(cont_enabled) + " sub='" + sub + "' tex='" + page_tex + "'")
	else:
		if not cont_enabled and sub == "no record on this slot" and "menu_book_page_r_disabled_v25" in page_tex:
			_pass("Continue mati tanpa save, halaman mati (coret di-bake)")
		else:
			_fail("Continue tanpa save: enabled=" + str(cont_enabled) + " sub='" + sub + "' tex='" + page_tex + "'")
	# 3. Tanpa CCTV.
	if not _menu.has_cctv():
		_pass("tidak ada REC/CAM di menu")
	else:
		_fail("masih ada REC/CAM di menu")
	# 4. CA mati (v23, TIDAK DIUBAH v24/v25/v26 — poin kritik #2 sudah beres):
	# konstanta + parameter shader.
	if absf(float(Balance.MENU_GRADE_CA)) < 0.0001:
		_pass("MENU_GRADE_CA = 0")
	else:
		_fail("MENU_GRADE_CA = " + str(Balance.MENU_GRADE_CA))
	var ca := float(_menu._fx_mat.get_shader_parameter("ca"))
	if absf(ca) < 0.0001:
		_pass("parameter shader ca = 0 (teks tajam)")
	else:
		_fail("parameter shader ca = " + str(ca))
	# 5. Kepala Giant ZUNISHA UTUH di jendela (v26: aturan
	# tidak-pernah-utuh DICABUT). Kepala baru giant_head_zunisha_v26,
	# 5,2 m di z 12,5, tengah x 2,0. Yang dicek BUKAN cuma belalai
	# lagi (v25), tapi KEENAM titik penanda kepala — kubah, belalai,
	# gading kiri/kanan, telinga kiri/kanan — semuanya harus di
	# dalam viewport: kalau satu saja di luar, kepala tidak utuh.
	# Bukti utama tetap screenshot yang dibaca manusia; cek ini
	# hanya jaring pengaman geometri (proyeksi diukur probe v26:
	# kubah y layar ~+16 px pada pitch -18).
	var head := _find_sprite(_menu.get_node_or_null("Backdrop"), "giant_head_zunisha_v26")
	if head == null:
		_fail("sprite giant_head_zunisha_v26 tidak ada di backdrop")
	else:
		var cam := _cam()
		var vp := get_viewport().get_visible_rect()
		var points: Array = [
			["kubah", Vector3(2.0, 5.2, 12.5)],
			["belalai", Vector3(2.0, 1.5, 12.5)],
			["gading kiri", Vector3(-0.6, 1.0, 12.5)],
			["gading kanan", Vector3(4.2, 1.2, 12.5)],
			["telinga kiri", Vector3(-0.9, 3.8, 12.5)],
			["telinga kanan", Vector3(4.9, 3.8, 12.5)],
		]
		var all_in := true
		for pair in points:
			var sp := cam.unproject_position(pair[1] as Vector3)
			if not vp.has_point(sp):
				_fail("kepala Zunisha tidak utuh: " + str(pair[0]) + " di luar viewport: " + str(sp))
				all_in = false
		if all_in:
			_pass("kepala Zunisha UTUH di jendela (kubah+belalai+2 gading+2 telinga di viewport)")
	# 5b. Elemen tempat dari gambar 2: papan kuburan — v26 PINDAH
	# ke x -3,5, z 9 supaya terbaca UTUH (v25 di x 5,5 terpotong
	# kusen kiri). Dicek keempat sudutnya di dalam viewport.
	var sign := _find_sprite(_menu.get_node_or_null("Backdrop"), "menu_sign_graveyard_v25")
	if sign == null:
		_fail("elemen tempat menu_sign_graveyard_v25 tidak ada di backdrop")
	else:
		var cam3 := _cam()
		var vp3 := get_viewport().get_visible_rect()
		var sign_in := true
		for corner in [Vector3(-4.5, 1.69, 9.0), Vector3(-2.5, 1.69, 9.0),
				Vector3(-4.5, 0.0, 9.0), Vector3(-2.5, 0.0, 9.0)]:
			var sp3 := cam3.unproject_position(corner)
			if not vp3.has_point(sp3):
				_fail("papan kuburan terpotong: sudut " + str(corner) + " -> " + str(sp3))
				sign_in = false
		if sign_in:
			_pass("papan KAWASAN KUBURAN GAJAH utuh di jendela")
	# 6. Siluet badan utuh v21 (elephant_shadow) TIDAK BOLEH kembali
	# ke menu (gagal 3x: terbaca bukit/pohon). Yang boleh ada di
	# selatan sekarang hanya KEPALA Zunisha (cek #5) — kepala punya
	# telinga + belalai sebagai penanda gajah. Level permainan
	# SENDIRI punya elephant_shadow di kabut utara (7, 0, -36) —
	# itu BUKAN siluet menu; yang dicek di sini hanya sisi selatan
	# (z > 0, arah jendela).
	var sil := _find_menu_silhouette(_menu.get_node_or_null("Backdrop"))
	if sil == null:
		_pass("siluet badan utuh v21 tidak ada di menu selatan")
	else:
		_fail("siluet badan utuh v21 masih ada di " + str((sil as Sprite3D).position) + " (seharusnya dihapus)")
	# 7. Lentera di luar kertas (v24, kritik #1; v25/v26 tidak mengubah): x < -2,27
	# (tepi kiri kertas). Dulu v23: di atas judul, alas 6 px.
	var cam2 := _cam()
	var lantern := _menu.get_node_or_null("Backdrop/Lantern") as Node3D
	if lantern == null or cam2 == null:
		_fail("kamera/lentera menu tidak ada")
	elif lantern.position.x < -2.27:
		_pass("lentera di luar kertas (x %.2f, pojok kiri meja)" % lantern.position.x)
	else:
		_fail("lentera masih di atas kertas: x=" + str(lantern.position.x))
	# 8. Tinta gelap di sekitar tengah logo + tengah baris Start:
	# bukti piksel bahwa teks yang di-bake TERBACA (bukan hilang
	# di bawah kertas / terbakar cahaya). Logo di (-0,81, 1,133,
	# 1,37), Start di (-1,79, 1,136, 1,48).
	for label in [["logo THE GIANT", Vector3(-0.81, 1.133, 1.37), 60, 30],
			["baris Start", Vector3(-1.79, 1.136, 1.48), 48, 20]]:
		var sp := cam2.unproject_position(label[1] as Vector3)
		var vp_size := get_viewport().get_visible_rect().size
		var ip := Vector2(sp.x * img.get_width() / vp_size.x, sp.y * img.get_height() / vp_size.y)
		var darkest := 1.0
		for dx in range(-int(label[2]), int(label[2]) + 1, 4):
			for dy in range(-int(label[3]), int(label[3]) + 1, 3):
				var p := Vector2i(int(ip.x) + dx, int(ip.y) + dy)
				if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
					continue
				var c := img.get_pixel(p.x, p.y)
				var lum := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				if lum < darkest:
					darkest = lum
		if darkest < 0.45:
			_pass("tinta gelap di " + str(label[0]) + " (lum tergelap %.2f)" % darkest)
		else:
			_fail("tinta di " + str(label[0]) + " pucat/hilang (lum tergelap %.2f)" % darkest)

func _find_menu_silhouette(root: Node) -> Sprite3D:
	# Siluet menu (kalau ada) berdiri di sisi SELATAN (z > 0, arah
	# jendela). Level permainan sendiri punya elephant_shadow di
	# kabut utara (7, 0, -36) — itu bukan siluet menu.
	if root == null:
		return null
	for n in root.get_children():
		if n is Sprite3D:
			var t := (n as Sprite3D).texture
			if t != null and "elephant_shadow" in t.resource_path and (n as Sprite3D).position.z > 0.0:
				return n as Sprite3D
		var found := _find_menu_silhouette(n)
		if found != null:
			return found
	return null

func _find_sprite(root: Node, needle: String) -> Sprite3D:
	if root == null:
		return null
	for n in root.get_children():
		if n is Sprite3D:
			var t := (n as Sprite3D).texture
			if t != null and needle in t.resource_path:
				return n as Sprite3D
		var found := _find_sprite(n, needle)
		if found != null:
			return found
	return null
