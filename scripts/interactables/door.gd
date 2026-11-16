extends StaticBody3D
## Pintu pos jaga. Menempel pada pivot engsel yang dibuat GuardPost.
## Buka/tutup dengan tween rotasi pivot. Status tersimpan di GameState.

var is_open := false
var _pivot: Node3D
var _tween: Tween

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("door")
	_pivot = get_parent() as Node3D

func get_prompt() -> String:
	return "Pintu - Tekan E untuk %s" % ("tutup" if is_open else "buka")

func interact() -> void:
	is_open = not is_open
	GameState.door_open = is_open
	var audio := get_tree().get_first_node_in_group("audio")
	if audio != null and audio.has_method("play_creak"):
		audio.play_creak()
	if _pivot == null:
		return
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	var target := deg_to_rad(-102.0) if is_open else 0.0
	_tween.tween_property(_pivot, "rotation:y", target, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Dipakai load save: pintu langsung terbuka tanpa animasi/tween.
func set_open_instant(open_state: bool) -> void:
	is_open = open_state
	GameState.door_open = open_state
	if _pivot != null:
		_pivot.rotation.y = deg_to_rad(-102.0) if open_state else 0.0
