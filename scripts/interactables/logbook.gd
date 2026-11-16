extends StaticBody3D
## Buku laporan jaga di meja. Satu interaksi = laporan malam ini tertulis.

var _written := false

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# v11 (Arya: "itu masih tumpang tindih"): buku TERGELETAK DATAR.
	# Dulu sampulnya billboard tegak (0,49 m, selalu menghadap kamera)
	# di atas kotak datar: dari samping ia berdiri seperti tenda dan
	# menutupi radio + surat di belakangnya. Sekarang sampulnya
	# Sprite3D datar di atas kotak, rotasi 0, searah grid meja.
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.36, 0.05, 0.40)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.32, 0.24)
	mesh.material_override = mat
	add_child(mesh)
	# Sampul datar di atas kotak (jejak 0,36 x 0,40, tepi atas sampul
	# ke +z supaya terbaca benar dari kursi). Tekstur penuh tanpa
	# margin (diukur: alpha bbox 1..245 x 0..272 dari 246x273).
	var spr := SpriteRegistry.flat("logbook", 0.36 / 246.0)
	if spr != null:
		spr.position = Vector3(0, 0.028, 0)
		add_child(spr)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	# v11: 0,55 x 0,5 -> 0,42 x 0,46, pas jejak buku. Koran (x sampai
	# -1,73) dan surat (x dari -0,80) tetap tidak tersentuh, radio
	# (z dari 1,48) juga tidak (audit hitbox di test rig mode=verify).
	col.size = Vector3(0.42, 0.3, 0.46)
	shape.shape = col
	add_child(shape)

func get_prompt() -> String:
	return "Buku Jaga - sudah tertulis" if _written else "Buku Jaga - Tekan E untuk menulis laporan"

func interact() -> void:
	if _written:
		GameState.show_message("Laporan: 22.00 pos aman. 01.30 ada yang berdiri di luar. Bukan orang.")
		return
	_written = true
	GameState.complete_task("log")
	GameState.restore_sanity(Balance.LOGBOOK_SANITY_RESTORE)
	GameState.show_message("Kamu menulis laporan malam ini. Tanganmu gemetar, tapi tulisannya rapi.")
