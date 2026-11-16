class_name SaveGame
## Save/load shift THE GIANT: satu file JSON di user://savegame.json.
## Disimpan: jam shift, Sanity, Stability, bahan bakar, generator,
## tugas yang sudah selesai, posisi pemain, dan pintu terbuka/tutup.
## Dipakai menu utama ("Continue") dan menu pause ("Simpan Shift").
## TIDAK menyimpan: event yang sedang berjalan (pemburu/Giant) — kalau
## save dibuat di tengah event, load kembali ke keadaan tenang di jam
## yang sama; event akan terpicu ulang kalau jamnya belum lewat.

const SAVE_PATH := "user://savegame.json"

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func save() -> bool:
	var player := _player()
	var data := {
		"version": 1,
		"shift_minutes": GameState.shift_minutes,
		"sanity": GameState.sanity,
		"stability": GameState.stability,
		"fuel": GameState.fuel,
		"generator_on": GameState.generator_on,
		"door_open": GameState.door_open,
		"player_pos": _vec_to_array(player.global_position) if player != null else [0, 0.45, 1.3],
		"player_yaw": player.rotation.y if player != null else 0.0,
		"tasks_done": _tasks_done(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[SaveGame] tidak bisa menulis " + SAVE_PATH)
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

static func load_data() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed
	return {}

static func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

static func summary_text() -> String:
	var d := load_data()
	if d.is_empty():
		return ""
	return "Continue - %s, Sanity %d" % [GameState.clock_text_for(d.get("shift_minutes", 0.0)), int(d.get("sanity", 100.0))]

static func _tasks_done() -> Array:
	var done: Array = []
	for id in GameState.tasks.keys():
		if bool(GameState.tasks[id]["done"]):
			done.append(id)
	return done

static func _player() -> Node3D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node3D

static func _vec_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
