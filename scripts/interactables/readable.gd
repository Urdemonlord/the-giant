extends StaticBody3D
## Dokumen yang bisa dibaca di meja jaga: koran atau surat izin.
## doc_id dipilih di main.tscn ("newspaper" / "permit"); isi teks
## tinggal di sini supaya mudah di-review, bukan di scene.
## Interaksi (E) membuka panel baca di HUD; game di-pause selama
## membaca, E lagi / tombol Tutup untuk menutup. Tidak menambah tugas
## baru: ini konten cerita, bukan gameplay baru.

@export var doc_id := "newspaper"

const DOCS := {
	"newspaper": {
		"title": "HARIAN RIMBA POST",
		"prompt": "Koran - Tekan E untuk membaca",
		"body": "Gajah Liar Masuk Kebun Sawit, Petani Rugi Miliaran\n\nTAMAN NASIONAL MALAYUNESIA — Seekor gajah liar masuk ke kebun sawit di pinggir kawasan dan merusak tanaman warga. Kerugian ditaksir miliaran rupiah.\n\nPemerintah daerah meminta warga tetap tenang dan tidak mendekati hewan tersebut.\n\nYang tidak ditulis koran ini: kebun itu dulunya hutan tempat gajah-gajah itu hidup dan mati.\n\n— Koran ini dipakai sebagai alas makan di pos. Tintanya luntur kena hujan.",
	},
	"permit": {
		"title": "SURAT KEPUTUSAN — PELEPASAN KAWASAN HUTAN",
		"prompt": "Surat Izin - Tekan E untuk membaca",
		"body": "Dengan ini, kawasan hutan seluas 12.400 hektar dilepas untuk perkebunan sawit.\n\nPemegang izin wajib menjaga satwa dilindungi di dalam kawasan.\n\nStempel basah di pojok kertas. Di pinggirnya, tulisan tangan:\n\"gajah sudah tidak ada di sini\"\n\nPadahal kuburan gajah ada di belakang pos ini.",
	},
}

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Kertas tipis di atas meja + garis-garis cetakan, supaya dari
	# jarak meja kebaca sebagai dokumen, bukan kotak polos.
	# Sumbu panjang searah x (meja lebih lebar daripada dalam),
	# supaya tidak menjulur jauh ke luar tepi depan meja.
	var paper := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.46, 0.012, 0.36)
	paper.mesh = pb
	paper.position = Vector3(0, 0.01, 0)
	var mat := StandardMaterial3D.new()
	# Koran agak kusam, surat lebih putih bersih.
	mat.albedo_color = Color(0.82, 0.78, 0.66) if doc_id == "newspaper" else Color(0.9, 0.88, 0.8)
	mat.roughness = 0.9
	paper.material_override = mat
	add_child(paper)
	# Garis headline + baris teks (kotak gelap tipis di atas kertas).
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.12, 0.11, 0.1)
	for i in range(4):
		var line := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.3 if i == 0 else 0.28, 0.002, 0.02 if i == 0 else 0.012)
		line.mesh = lb
		line.position = Vector3(0, 0.018, -0.16 + float(i) * 0.09)
		line.material_override = ink
		add_child(line)
	if doc_id == "permit":
		# Stempel merah di pojok.
		var stamp := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(0.09, 0.002, 0.09)
		stamp.mesh = sb
		stamp.position = Vector3(0.11, 0.018, 0.16)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.6, 0.15, 0.12)
		stamp.material_override = sm
		add_child(stamp)
	# Hitbox pemurah seperti radio/buku jaga: kertas tipis susah
	# dibidik raycast kalau collider-nya setipis kertasnya.
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(0.55, 0.35, 0.55)
	shape.shape = col
	shape.position = Vector3(0, 0.12, 0)
	add_child(shape)

func get_prompt() -> String:
	return str(DOCS[doc_id]["prompt"]) if DOCS.has(doc_id) else "Dokumen - Tekan E untuk membaca"

func interact() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_document"):
		hud.show_document(str(DOCS[doc_id]["title"]), str(DOCS[doc_id]["body"]))
