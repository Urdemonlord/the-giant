class_name SpriteRegistry
## Registry nama sprite THE GIANT.
## Dulu sprite di-load dengan string dinamis "sprites/%s.png" di 9 tempat;
## salah ketik satu huruf = sprite hilang diam-diam (fallback kotak / tidak
## muncul sama sekali, tanpa error). Sekarang semua nama yang dipakai game
## terdaftar di ALL_NAMES, dan load lewat fungsi di sini: nama tidak
## terdaftar atau file tidak ada -> push_error yang jelas + null.
## Audit: jalankan test rig mode=verify, ia memanggil validate() dan
## mencatat sprite yang hilang; game tetap jalan (fallback kotak).

## Semua sprite yang dipakai game (67). Satu nama = satu file
## res://assets/sprites/<nama>.png. Jangan tambah sprite baru tanpa
## mendaftarkannya di sini.
const ALL_NAMES: Array[String] = [
	"axe", "banana", "barrels", "battery", "blood", "bush1", "bush2",
	"bush3", "chainsaw", "crate_low", "crate_tall", "door",
	"elephant_back", "elephant_front", "elephant_shadow",
	"elephant_side", "fence_barbed", "fence_wood", "fog_puff",
	"footprint", "gate", "generator", "giant_eye", "giant_foot",
	"giant_foot_photo_v23",
	"guard_back", "guard_front", "guard_hut", "hunter",
	"hunter_rifle", "lantern", "log", "logbook", "meter",
	"menu_book_page_l_v24", "menu_book_page_r_v24",
	"menu_book_page_r_disabled_v24", "menu_btn_v20",
	"menu_btn_v20_hover", "menu_btn_v20_pressed",
	"menu_form_page",
	"menu_giant_v21",
	"menu_ledger_v20", "menu_ledger_v21", "menu_rec_v20",
	"menu_stamp_v20",
	"poacher_ghost", "poacher_mask", "radio", "radio_tower", "rocks",
	"sacks", "shovel", "sign_no_elephant", "sign_no_elephant2",
	"sign_no_logging", "sign_park", "snare", "stump", "tower_tall",
	"tree_big", "tree_dead", "tree_palm", "tree_tall", "tusks",
	"walkie_talkie", "watchtower",
]

static func path_for(sprite_name: String) -> String:
	return "res://assets/sprites/%s.png" % sprite_name

## Load tekstur sprite. Kembalikan null + push_error kalau bermasalah.
static func texture(sprite_name: String) -> Texture2D:
	if not sprite_name in ALL_NAMES:
		push_error("[SpriteRegistry] nama sprite tidak terdaftar: '%s' (cek ALL_NAMES di sprite_registry.gd)" % sprite_name)
		return null
	var path := path_for(sprite_name)
	if not ResourceLoader.exists(path):
		push_error("[SpriteRegistry] file sprite hilang: %s" % path)
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("[SpriteRegistry] gagal load tekstur: %s" % path)
	return tex

## Buat Sprite3D billboard dari nama terdaftar. Null kalau sprite bermasalah.
static func billboard(sprite_name: String, pixel_size: float, tint: Color = Color(1, 1, 1, 1)) -> Sprite3D:
	var tex := texture(sprite_name)
	if tex == null:
		return null
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.pixel_size = pixel_size
	spr.modulate = tint
	return spr

## Buat Sprite3D DATAR (bukan billboard) dari nama terdaftar: dibaringkan
## menghadap atas, tepi atas tekstur ke arah +z (terbaca benar dari sisi
## -z, mis. kursi di depan meja). Untuk benda yang tergeletak: buku,
## kertas, jejak. Null kalau sprite bermasalah.
static func flat(sprite_name: String, pixel_size: float, tint: Color = Color(1, 1, 1, 1)) -> Sprite3D:
	var tex := texture(sprite_name)
	if tex == null:
		return null
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	spr.pixel_size = pixel_size
	spr.modulate = tint
	# Datar menghadap atas + tepi atas ke +z: putar -90 derajat di X,
	# lalu 180 derajat di Z (balik dalam bidang) supaya tidak terbalik
	# dari sisi pembaca. Urutan Euler Godot (YXZ) = Rz dulu, baru Rx.
	spr.rotation = Vector3(-PI * 0.5, 0, PI)
	return spr

## Audit semua nama terdaftar. Kembalikan daftar nama yang filenya hilang.
static func validate() -> Array[String]:
	var missing: Array[String] = []
	for n in ALL_NAMES:
		if not ResourceLoader.exists(path_for(n)):
			missing.append(n)
	if not missing.is_empty():
		push_error("[SpriteRegistry] sprite hilang: %s" % ", ".join(missing))
	return missing
