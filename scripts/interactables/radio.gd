extends StaticBody3D
## Radio pos di meja jaga. Tiap interaksi memutar potongan siaran berikutnya.
## Siaran terakhir bukan suara manusia biasa. Itu disengaja.

const LINES: Array[String] = [
	"...krrk... pos jaga taman, masuk...",
	"Harian Rimba: gajah liar masuk kebun sawit, petani rugi miliaran...",
	"...krrk... sawit adalah anugerah Tuhan untuk rakyat Malayunesia...",
	"Jangan jawab kalau ada yang mengetuk dari arah hutan.",
	"...krrk... mereka masih berdiri di sana... jangan lihat matanya...",
]

var _index := -1

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Tanpa kotak gelap: radio adalah sprite dari sheet.
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	# Hitbox pas ukuran radio, bukan pemurah: hitbox lama (0.7 lebar)
	# menutupi koran di ujung kiri meja dari arah spawn, jadi koran
	# tidak bisa dibidik (raycast mengenai radio dulu).
	# v11: hitbox ikut sprite yang diangkat (alas di permukaan meja):
	# tinggi 0,42 -> 0,6, tengah y +0,13 (1,10..1,70). Lebar/depan
	# tetap, supaya tidak menyentuh hitbox koran/buku.
	col.size = Vector3(0.55, 0.6, 0.32)
	shape.shape = col
	shape.position = Vector3(0, 0.13, 0)
	add_child(shape)
	var spr := SpriteRegistry.billboard("radio", 0.0022)
	if spr != null:
		# v11: alas sprite TEPAT di permukaan meja (1,11), bukan
		# terkubur 0,087 m di dalam papan seperti sejak v2: tengah
		# sprite 1,407 -> lokal y 0,137 (tekstur penuh, margin bawah 0).
		spr.position = Vector3(0, 0.137, -0.2)
		add_child(spr)

func get_prompt() -> String:
	return "Radio - Tekan E untuk dengarkan"

func interact() -> void:
	_index = (_index + 1) % LINES.size()
	GameState.show_message("RADIO: " + LINES[_index])
	GameState.complete_task("radio")
	var audio := get_tree().get_first_node_in_group("audio")
	if audio != null:
		# Suara siaran yang cocok dengan baris teks + burst statis
		# (suara "mencari" frekuensi). Teks tetap tampil seperti dulu.
		if audio.has_method("play_radio_voice"):
			audio.play_radio_voice(_index)
		if audio.has_method("play_static"):
			audio.play_static()
