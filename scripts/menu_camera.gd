extends Camera3D
## Kamera menu utama: sapuan sinematik pelan di atas latar pos jaga.
## Pola sama seperti intro pan v14 (+-6 derajat / 24 dtk), tapi lebih
## pelan (+-5 derajat / 26 dtk) supaya latar menu terasa hidup tanpa
## membuat yang melihatnya pusing. Hanya hidup di scene menu (node ini
## dibuat oleh main.gd saat mode backdrop); ikut ter-free saat ganti
## scene ke permainan, jadi tidak ada yang bocor ke shift.

var _t := 0.0
var _base_yaw := 0.0

func _ready() -> void:
	_base_yaw = rotation.y

func _process(delta: float) -> void:
	_t += delta
	rotation.y = _base_yaw + deg_to_rad(5.0) * sin(_t * TAU / 26.0)
