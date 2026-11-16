class_name Settings
## Pengaturan pemain THE GIANT: volume per bus audio, sensitivitas
## mouse, layar penuh, grain film. Satu file JSON di
## user://settings.json (pola yang sama dengan SaveGame, tapi file
## terpisah — Start menghapus save shift, dan pengaturan tidak boleh
## ikut terhapus). Semua akses lazy-load: dibaca sekali saat pertama
## dipakai, jadi aman dipanggil dari menu, HUD, player, atau rig.
## Volume disimpan linear 0..1, diterapkan sebagai dB ke bus
## (0 = -80 dB, sunyi). Sensitivitas adalah pengali 0.5-2.0 dari
## Balance.PLAYER_MOUSE_SENS.

const SETTINGS_PATH := "user://settings.json"
const BUS_NAMES := ["Master", "Ambience", "SFX", "Voice"]

static var _data: Dictionary = {}
static var _loaded := false

static func _defaults() -> Dictionary:
	return {
		"master": 1.0, "ambience": 1.0, "sfx": 1.0, "voice": 1.0,
		"mouse_sens": 1.0, "fullscreen": false, "grain": true,
	}

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_data = _defaults()
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		for k in parsed.keys():
			if k in _data:
				_data[k] = parsed[k]

static func save() -> void:
	_ensure_loaded()
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[Settings] tidak bisa menulis " + SETTINGS_PATH)
		return
	f.store_string(JSON.stringify(_data))
	f.close()

## Kembalikan semua ke bawaan (dipakai rig supaya tidak ada state uji
## yang bocor ke run berikutnya). Tidak ada tombol reset di UI.
static func reset_defaults() -> void:
	_data = _defaults()
	_loaded = true
	save()

static func vol(bus: String) -> float:
	_ensure_loaded()
	return clampf(float(_data.get(bus.to_lower(), 1.0)), 0.0, 1.0)

static func vol_db(bus: String) -> float:
	var v := vol(bus)
	if v <= 0.001:
		return -80.0
	return linear_to_db(v)

static func set_vol(bus: String, v: float) -> void:
	_ensure_loaded()
	_data[bus.to_lower()] = clampf(v, 0.0, 1.0)
	apply_bus(bus)
	save()

static func apply_bus(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, vol_db(bus))

static func apply_all_audio() -> void:
	for b in BUS_NAMES:
		apply_bus(b)

static func mouse_sens() -> float:
	_ensure_loaded()
	return clampf(float(_data.get("mouse_sens", 1.0)), 0.5, 2.0)

static func set_mouse_sens(v: float) -> void:
	_ensure_loaded()
	_data["mouse_sens"] = clampf(v, 0.5, 2.0)
	save()

static func fullscreen() -> bool:
	_ensure_loaded()
	return bool(_data.get("fullscreen", false))

static func set_fullscreen(on: bool) -> void:
	_ensure_loaded()
	_data["fullscreen"] = bool(on)
	apply_fullscreen()
	save()

static func apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen()
		else DisplayServer.WINDOW_MODE_WINDOWED)

static func grain_on() -> bool:
	_ensure_loaded()
	return bool(_data.get("grain", true))

static func set_grain(on: bool) -> void:
	_ensure_loaded()
	_data["grain"] = bool(on)
	save()

static func apply_all() -> void:
	apply_all_audio()
	apply_fullscreen()
