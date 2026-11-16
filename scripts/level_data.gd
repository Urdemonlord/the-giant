class_name LevelData
## Satu-satunya tempat posisi/ukuran level THE GIANT tinggal.
## Level masih code-built (bukan scene editor): pos, pagar, hutan, dan
## properti dibangun prosedural oleh main.gd / guard_post.gd, tapi SEMUA
## angka posisi/ukuran yang dulu tersebar di fungsi-fungsi itu sekarang
## dibaca dari sini. Geser benda = ubah satu baris di sini.
## Posisi benda interaktif (generator/radio/buku/lentera) juga di sini
## dan DITERAPKAN main.gd saat _ready, jadi main.tscn bukan lagi
## satu-satunya sumber kebenaran untuk posisi mereka.

## --- Pos jaga ---------------------------------------------------------------
const POST_WIDTH := 5.0 # lebar (x)
const POST_DEPTH := 4.0 # kedalaman (z)
const POST_WALL_HEIGHT := 2.6
const POST_FLOOR_Y := 0.35 # lantai panggung
const POST_DOOR_WIDTH := 1.0
const POST_DOOR_HEIGHT := 2.05
const POST_WINDOW_WIDTH := 1.4
const POST_WINDOW_SILL_Y := 0.95 # tinggi ambang bawah jendela (dari lantai)
const POST_WINDOW_TOP_Y := 1.85 # tinggi ambang atas jendela (dari lantai)
const POST_PORCH_LIGHT_POS := Vector3(0, 2.4, -2.6)
const POST_DESK_POS := Vector3(-1.30, 1.07, 1.35) # meja jaga (y sudah + lantai)
const POST_DESK_WIDTH := 2.2 # v10: 1,7 -> 2,2, meja lama terlalu sempit
const POST_DESK_DEPTH := 0.8 # untuk 6 benda (3 kolom x 2 baris), lihat bawah
const POST_DESK_TOP_Y := 1.07 # tengah papan meja (FLOOR_Y + 0.72);
# PERMUKAAN meja = 1,11 (papan tebal 0,08). Benda di atas meja harus
# y >= 1,11: koran/surat sempat TERKUBUR di dalam papan (y 1,07) sejak
# v7 dan cuma kelihatan dari sisi yang menjulur keluar meja — ketahuan
# di screenshot v15_desk_top, diperbaiki di v10 (y 1,12).

## --- Spawn & benda interaktif (diterapkan main.gd di _ready) ----------------
const PLAYER_SPAWN := Vector3(0, 0.45, 1.3)
const PLAYER_HEAD_HEIGHT := 1.62
const GENERATOR_POS := Vector3(3.6, 0, -1.2)
const GENERATOR_ROT_Y_DEG := 0.0 # v10: -23 -> 0, generator sejajar dinding timur
## TATA LETAK MEJA v10 (Arya: "tata letak barang-barangnya juga rapiin"):
## meja 2,2 x 0,8, grid 3 kolom x 2 baris, tiap benda punya zona sendiri,
## hitbox TIDAK saling tumpang (dicek di bawah: radio/logbook/lentera/
## koran/surat sudah dihitung, bukan kira-kira).
## Baris belakang (z 1,64): radio kiri, meter tengah (visual saja), lentera kanan.
## Baris depan (z 1,14): koran kiri, buku jaga tengah, surat kanan.
## Kertas lurus (rotasi 0 di main.gd), bukan miring: lebih rapi + hitbox
## persis 0,5 x 0,5. Lentera PINDAH dari peti kayu (1,85, 1,5) ke meja,
## y naik 1,06 -> 1,27 supaya alas sprite tidak tenggelam ke permukaan meja
## (sprite lentera 0,50 m, alas di node y - 0,20).
const RADIO_POS := Vector3(-1.98, 1.27, 1.64)
const LOGBOOK_POS := Vector3(-1.30, 1.14, 1.20) # z 1,20: buku tidak menjulur keluar tepi depan meja (dulu 1,14, menjulur 7 cm)
const LANTERN_POS := Vector3(-0.55, 1.27, 1.64)
const METER_POS := Vector3(-1.30, 1.335, 1.64) # meter getar, visual saja; v11: y 1,29 -> 1,335 supaya alas sprite (0,45 m) tepat di permukaan meja (1,11), bukan terkubur 0,045 m
const NEWSPAPER_POS := Vector3(-1.98, 1.12, 1.14) # y 1,12: di ATAS permukaan meja (1,11), bukan terkubur
const PERMIT_POS := Vector3(-0.55, 1.12, 1.14)

## --- Terrain / pagar ---------------------------------------------------------
const GROUND_SIZE := 90.0
const PATH_POS := Vector3(0, 0.02, -10.0)
const PATH_SIZE := Vector3(2.2, 0.04, 16.0)
const FENCE_Z := -16.0
const FENCE_HALF_WIDTH := 16.0
const FENCE_GATE_HALF_GAP := 2.0 # celah gerbang x -1.5..1.5 (tiang genap)
const GATE_POS := Vector3(0, 0, -15.7)
const SIGN_PARK_POS := Vector3(3.2, 0, -15.6)
const SIGN_NO_LOGGING_POS := Vector3(-4.4, 0, -15.6)
const SIGN_NO_ELEPHANT_POS := Vector3(-6.8, 0, -15.6) # v10: z -14,2 -> -15,6, sejajar pagar seperti dua papan lain

## --- Hutan -------------------------------------------------------------------
const FOREST_RING_COUNT := 90
const FOREST_RING_RADIUS_MIN := 19.0
const FOREST_RING_RADIUS_MAX := 34.0
const FOREST_NEAR_COUNT := 14
const FOREST_NEAR_RADIUS_MIN := 11.0
const FOREST_NEAR_RADIUS_MAX := 17.0
const FOREST_SEED := 20261116

## Properti berserakan: [nama sprite, posisi, pixel_size].
## Cerita tanpa kata: tunggul + gading + jerat + darah = penebangan liar.
## v10 (Arya: rapiin tata letak): TIDAK lagi tersebar acak. Tiga baris
## lurus: (1) bukti penebangan di sisi BARAT jalan (x -4,5, z -6,5..-12,
## urutan tunggul-jerat-darah-gading seperti jejak), (2) kayu di sisi
## TIMUR jalan (x 7,5, z -5,5..-8,5: log-tunggul-batu), (3) sisi timur
## pos (x 4,4, z -3,8..1,2: karung-tong-gregaji-generator-peti, sejajar
## dinding timur). Semak di garis pagar (z -14,5), bukan di tengah halaman.
const SCATTER_PROPS: Array = [
	["stump", Vector3(7.5, 0.28, -7.0), 0.0035],
	["stump", Vector3(-4.5, 0.28, -6.5), 0.0035],
	["tusks", Vector3(-4.5, 0.2, -12.0), 0.003],
	["chainsaw", Vector3(4.4, 0.35, -2.5), 0.0035],
	["log", Vector3(7.5, 0.21, -5.5), 0.004],
	["rocks", Vector3(7.5, 0.22, -8.5), 0.005],
	["barrels", Vector3(4.4, 0.28, -3.2), 0.006],
	["sacks", Vector3(4.4, 0.28, -3.8), 0.005],
	["crate_tall", Vector3(4.4, 0.3, 1.2), 0.005],
	["crate_low", Vector3(4.4, 0.2, 0.4), 0.005],
	["bush2", Vector3(8.0, 0.4, -14.5), 0.006],
	["bush2", Vector3(-5.0, 0.4, -14.5), 0.006],
	["bush2", Vector3(5.0, 0.4, -14.5), 0.006],
	["bush2", Vector3(-8.0, 0.4, -14.5), 0.006],
]

## Decal di tanah: [nama sprite, posisi, pixel_size].
const GROUND_DECALS: Array = [
	["blood", Vector3(-4.5, 0.04, -10.5), 0.009],
	# v11: jejak kaki + jerat BUKAN billboard tegak lagi — keduanya
	# benda yang tergeletak di tanah, jadi decal datar seperti darah.
	# y 0,05 supaya menempel tanah (bukan 0,06/0,25 dari tabel
	# billboard); ukuran jejak ~0,5 m, jerat ~0,9 m.
	["footprint", Vector3(1.2, 0.05, -9.0), 0.0015],
	["snare", Vector3(-4.5, 0.05, -9.0), 0.003],
]

## Billboard statis: [nama sprite, posisi, pixel_size, tint].
## Pisang, bangunan jauh, gajah di kabut, pemburu liar, kabut rendah
## (kabut dibuat acak di main.gd, bukan dari tabel ini).
const BILLBOARDS: Array = [
	["banana", Vector3(5.5, 0.0, -15.5), 0.0114, Color(0.8, 0.85, 0.8, 1.0)],
	["banana", Vector3(-9.0, 0.0, -14.5), 0.0114, Color(0.75, 0.8, 0.75, 1.0)],
	["watchtower", Vector3(-14.0, 0.0, -24.0), 0.03, Color(0.75, 0.75, 0.75, 1.0)],
	["guard_hut", Vector3(15.0, 0.0, -19.0), 0.03, Color(0.8, 0.8, 0.8, 1.0)],
	["tower_tall", Vector3(22.0, 0.0, -30.0), 0.035, Color(0.6, 0.6, 0.6, 1.0)],
	["gate", Vector3(0, 0, -15.7), 0.016, Color(1.0, 1.0, 1.0, 1.0)],
	["guard_front", Vector3(3.0, 0, -7.0), 0.0073, Color(0.7, 0.7, 0.7, 1.0)],
	["elephant_shadow", Vector3(7.0, 0.0, -36.0), 0.055, Color(0.4, 0.4, 0.45, 0.55)],
	["elephant_side", Vector3(-20.0, 0.0, -26.0), 0.02, Color(0.55, 0.55, 0.55, 0.8)],
	["elephant_front", Vector3(-10.0, 0.0, -30.0), 0.0176, Color(0.5, 0.5, 0.55, 0.8)],
	["poacher_mask", Vector3(0, 0, -15.5), 0.0071, Color(0.65, 0.6, 0.6, 0.95)],
	["poacher_ghost", Vector3(-13.0, 0, -22.0), 0.0079, Color(0.85, 0.85, 0.9, 0.75)],
]

## --- Event: posisi spawn ------------------------------------------------------
const HUNTER_POS_1 := Vector3(-1.6, 0.0, -11.0)
const HUNTER_POS_2 := Vector3(1.9, 0.0, -12.5)
const HUNTER_HEIGHT_M := 1.8
# v9: STAGING diperbaiki, bukan potongan. Dulu pusat y 2,25 + tinggi
# 4,5 m -> telapak di y ~0, di bawah ambang, yang kelihatan cuma tengah
# kaki. Sekarang pusat y 2,8 + tinggi 3,4 m -> telapak di y ~1,1-1,9,
# TEPAT di band jendela (ambang 1,30-2,20, mata pemain 2,07).
# Potongan kaki BARU dari gajah samping sempat dicoba tapi GAGAL
# (terlalu sempit + terang, hilang di kabut, v14f); tekstur v5 (kaki
# gajah depan, 120x218, gelap + lebar 1,87 m) dikembalikan karena
# TERBUKTI kebaca sebagai siluet di v14. Kaki ini terangkat mid-stride
# (langkah raksasa), debu + dentum di tanah di bawahnya menjual injakannya.
const GIANT_FOOT_START := Vector3(-3.5, 2.8, 3.4)
const GIANT_FOOT_END_X := 3.5
const GIANT_FOOT_HEIGHT_M := 3.4
const GIANT_EYE_POS := Vector3(0, 1.75, 2.25) # tengah jendela belakang
const GIANT_EYE_HEIGHT_M := 1.5 # v9: 1,1 -> 1,5 m, mata memenuhi jendela
