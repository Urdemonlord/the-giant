extends StaticBody3D
## Buku laporan jaga di meja. Satu interaksi = laporan malam ini tertulis.

var _written := false

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.34, 0.05, 0.46)
	mesh.mesh = box
	mesh.rotation.y = deg_to_rad(-14.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.32, 0.24)
	mesh.material_override = mat
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	# v10: kedalaman 0,6 -> 0,5, supaya tidak tumpang dengan hitbox
	# surat di baris depan (buku di baris belakang, surat di depan).
	col.size = Vector3(0.55, 0.3, 0.5)
	shape.shape = col
	add_child(shape)
	var spr := SpriteRegistry.billboard("logbook", 0.0018)
	if spr != null:
		spr.position = Vector3(0, 0.1, -0.18)
		add_child(spr)

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
