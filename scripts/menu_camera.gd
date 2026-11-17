extends Camera3D
## Kamera menu utama: sapuan sinematik pelan di atas meja pos jaga.
## v22: sapuan DIPERKECIL (+-3 derajat / 30 dtk, dulu +-5 / 26) —
## kamera sekarang dekat dengan buku (1,1 m), sapuan besar membuat
## buku bergeser terlalu jauh di frame dan baris klik ikut bergerak.
## Hanya hidup di scene menu (node ini dibuat oleh main.gd saat mode
## backdrop); ikut ter-free saat ganti scene ke permainan, jadi tidak
## ada yang bocor ke shift.

var _t := 0.0
var _base_yaw := 0.0

func _ready() -> void:
	_base_yaw = rotation.y

func _process(delta: float) -> void:
	_t += delta
	rotation.y = _base_yaw + deg_to_rad(3.0) * sin(_t * TAU / 30.0)
