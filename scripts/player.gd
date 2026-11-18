extends CharacterBody3D
## First-person controller: WASD + mouse look, gaya No I'm Not a Human /
## FPS horor pelan. Klik layar untuk mengunci mouse, ESC untuk lepas.

const SPEED_WALK := Balance.PLAYER_WALK_SPEED
const SPEED_SPRINT := Balance.PLAYER_SPRINT_SPEED
const GRAVITY := Balance.PLAYER_GRAVITY
const MOUSE_SENS := Balance.PLAYER_MOUSE_SENS
const PITCH_LIMIT := deg_to_rad(Balance.PLAYER_PITCH_LIMIT_DEG)

var pitch := 0.0
var bob_time := 0.0
var step_timer := 0.0
var flashlight_on := false
## v14 (game-feel): trauma 0..1, bukan kekuatan acak per frame.
## shake() menambah trauma; _physics_process meluruhkannya dan
## menghitung offset dari summed sines (trauma^2). shake_strength
## dipertahankan sebagai alias baca supaya pemanggil lama (giant_event)
## tidak pecah, tapi sumber kebenarannya trauma.
var trauma := 0.0
var shake_strength := 0.0
var _shake_t := 0.0
var _shake_offset := Vector2.ZERO
var _shake_roll := 0.0
var _bob_y := 0.0 # bob dihaluskan supaya berhenti jalan tidak snap ke 0
## Input sentuh (diisi TouchControls): x = strafe, y = maju/mundur (-1 = maju).
var touch_move := Vector2.ZERO
## Dipakai test rig playtest untuk mengarahkan pandangan tanpa mouse.
var look_override := false

## Dipanggil event Giant: getaran tanah mengguncang kamera sesaat.
## v14: menambah trauma (game-feel), bukan set angka acak.
func shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
	shake_strength = trauma

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

signal prompt_changed(text: String)
signal footstep
## v27 (kritik #5, Luci: game-feel): hold-to-interact. Progress +
## selesai/batal dikirim ke HUD (bar progres). Interactable yang
## punya hold_duration() > 0 (generator, buku jaga) tidak langsung
## jalan di pencet — baru jalan setelah tombol ditahan penuh.
## Lepas tombol / bidikan lepas = batal, progres reset.
signal hold_progress_changed(progress: float, duration: float)
signal hold_ended(cancelled: bool)

var _hold_target: Object = null
var _hold_progress := 0.0
var _hold_duration := 0.0
var _hold_pitch_target := 0.0 # derajat, 0 = tidak ada perubahan pitch

## Dipakai TouchControls (tombol E: button_down/up) + _unhandled_input
## (keyboard E: pressed/released). Holdable -> mulai menahan;
## instan -> langsung interaksi seperti dulu.
func begin_hold_interact() -> void:
	var target := get_current_interactable()
	if target == null:
		return
	if target.has_method("hold_duration"):
		var d := float(target.hold_duration())
		if d > 0.0:
			_hold_target = target
			_hold_duration = d
			_hold_progress = 0.0
			_hold_pitch_target = float(target.hold_pitch_deg()) if target.has_method("hold_pitch_deg") else 0.0
			hold_progress_changed.emit(0.0, d)
			if target.has_method("hold_started"):
				target.hold_started()
			return
	_try_interact()

func end_hold_interact() -> void:
	if _hold_target != null:
		_cancel_hold()

func _cancel_hold() -> void:
	var t := _hold_target
	_hold_target = null
	_hold_progress = 0.0
	_hold_duration = 0.0
	_hold_pitch_target = 0.0
	if t != null and t.has_method("hold_ended"):
		t.hold_ended(true)
	hold_ended.emit(true)

func _ready() -> void:
	add_to_group("player")
	flashlight.visible = false

## Dipakai TouchControls / test rig: putar pandangan tanpa mouse.
func apply_look(delta_yaw: float, delta_pitch: float) -> void:
	rotate_y(delta_yaw)
	pitch = clampf(pitch + delta_pitch, -PITCH_LIMIT, PITCH_LIMIT)
	head.rotation.x = pitch

## Dipakai TouchControls: tombol E di layar.
func try_interact() -> void:
	_try_interact()

## Dipakai TouchControls: tombol senter di layar.
func toggle_flashlight() -> void:
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on

func _input(event: InputEvent) -> void:
	# v13: tangkap mouse DI SINI, bukan cuma di _unhandled_input.
	# Klik yang dimakan GUI (dot crosshair / label HUD di tengah
	# layar) tidak pernah sampai ke _unhandled_input, jadi dulu
	# pemain harus klik area kosong dulu sebelum look jalan — dan
	# tanpa petunjuk apa pun. Saat tree di-pause (intro/dokumen/
	# jeda), _input pemain tidak jalan (pausable), jadi klik tombol
	# di panel tidak ikut menangkap mouse.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# v27: saat menahan interaksi, pandangan TERKUNCI (game-feel:
		# momen rentan). Pemain tidak bisa menoleh ke belakang
		# sambil menarik tuas generator / menulis laporan — itu
		# yang bikin hold tegang, bukan cuma timer.
		if _hold_target == null:
			# v18: sensitivitas = bawaan Balance x pengali pilihan pemain
			# (Settings, diatur di Options menu utama; default 1.0).
			var s := MOUSE_SENS * Settings.mouse_sens()
			apply_look(-event.relative.x * s, -event.relative.y * s)
	if event.is_action_pressed("flashlight"):
		toggle_flashlight()
	if event.is_action_pressed("interact"):
		begin_hold_interact()
	elif event.is_action_released("interact"):
		end_hold_interact()

func _physics_process(delta: float) -> void:
	# v27: selama menahan interaksi, pemain BERDIAM — menarik tuas
	# / menulis laporan sambil jalan itu tidak masuk akal, dan
	# bergerak saat hold bisa menggeser bidikan keluar dari target
	# (pitch menunduk buku jaga membatalkan hold-nya sendiri).
	# Look sudah terkunci di _unhandled_input; di sini gerak yang
	# dikunci. Batal hanya dengan melepas tombol.
	var input_dir := Vector2.ZERO
	if _hold_target == null:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if touch_move.length() > 0.05:
			input_dir = touch_move
	var speed := SPEED_SPRINT if Input.is_action_pressed("sprint") else SPEED_WALK
	var dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

	# Head bob halus + bunyi langkah (placeholder: sinyal ke Audio).
	# v14: bob dan shake dihitung terpisah, lalu digabung SEKALI di
	# camera.position, supaya keduanya tidak saling menimpa y.
	var bob_y := 0.0
	var horizontal := Vector2(velocity.x, velocity.z).length()
	if horizontal > 0.4 and is_on_floor():
		bob_time += delta * horizontal * 1.6
		bob_y = sin(bob_time * 2.0) * 0.035
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = 2.4 / horizontal
			footstep.emit()
	# Guncangan (langkah Giant): trauma^2 + summed sines (game-feel
	# Pattern 1), meluruh di real time, snap ke rest saat habis.
	# Dulu randf_range tiap frame: buzz statis, bukan gempa.
	if trauma > 0.0:
		var real_dt := delta / maxf(Engine.time_scale, 0.0001)
		trauma = maxf(trauma - Balance.SHAKE_DECAY * real_dt, 0.0)
		var s := trauma * trauma
		_shake_t += real_dt * 30.0
		_shake_offset = Vector2(
			Balance.SHAKE_MAX_OFFSET * s * sin(_shake_t * 1.7),
			Balance.SHAKE_MAX_OFFSET * s * sin(_shake_t * 2.3))
		_shake_roll = Balance.SHAKE_MAX_ROLL * s * sin(_shake_t * 1.1)
		if trauma == 0.0:
			_shake_offset = Vector2.ZERO
			_shake_roll = 0.0
		shake_strength = trauma
	_bob_y = lerpf(_bob_y, bob_y, 1.0 - exp(-8.0 * delta))
	camera.position = Vector3(_shake_offset.x, _bob_y + _shake_offset.y, 0.0)
	camera.rotation.z = _shake_roll
	_update_fov(delta)
	_update_hold(delta)
	_update_prompt()

## v27: denyut hold. Pitch menunduk pelan kalau target memintanya
## (buku jaga: -32 derajat, menulis sambil menunduk). Selesai =
## interact() target jalan sekali. Batal HANYA dengan melepas tombol:
## look terkunci + gerak terkunci selama hold, jadi tidak ada cara
## lain bidikan lepas — kecuali pitch menunduk itu sendiri, yang
## menggeser ray dari buku ke surat di sebelahnya (ketahuan di
## holdprobe v27: ray kena Permit di 0,5 detik, hold batal).
## Cek "bidikan lepas = batal" sengaja TIDAK ADA di sini.
func _update_hold(delta: float) -> void:
	if _hold_target == null:
		return
	_hold_progress += delta
	hold_progress_changed.emit(_hold_progress, _hold_duration)
	if _hold_pitch_target != 0.0:
		pitch = lerpf(pitch, deg_to_rad(_hold_pitch_target), 1.0 - exp(-4.0 * delta))
		head.rotation.x = pitch
	# Getaran target selama menahan (generator: mesin menderu di
	# tangan). Trauma dijaga di angka kecil, meluruh sendiri saat
	# hold selesai — game-feel: kembali ke rest.
	if _hold_target.has_method("hold_shake_amount"):
		trauma = maxf(trauma, float(_hold_target.hold_shake_amount()))
	if _hold_progress >= _hold_duration:
		var t := _hold_target
		_hold_target = null
		_hold_progress = 0.0
		_hold_duration = 0.0
		_hold_pitch_target = 0.0
		if t.has_method("hold_ended"):
			t.hold_ended(false)
		hold_ended.emit(false)
		if t.has_method("interact"):
			t.interact()

## v14 (camera-systems): FOV menyempit halus saat Sanity rendah
## (terowongan) dan sedikit lagi saat event Giant aktif. Semua di-ease
## dengan 1-exp(-rate*dt), bukan snap.
func _update_fov(delta: float) -> void:
	var target := Balance.FOV_BASE
	if GameState.sanity < Balance.HEARTBEAT_SANITY_THRESHOLD:
		target -= Balance.FOV_SANITY_NARROW * (1.0 - GameState.sanity / Balance.HEARTBEAT_SANITY_THRESHOLD)
	var giant := get_tree().get_first_node_in_group("giant_event")
	if giant != null and str(giant.get("active_event")) != "":
		target -= Balance.FOV_EVENT_NARROW
	var k := 1.0 - exp(-2.0 * delta)
	camera.fov = lerpf(camera.fov, target, k)

func get_current_interactable() -> Object:
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider != null and collider.is_in_group("interactable"):
			return collider
	return null

func _update_prompt() -> void:
	var target := get_current_interactable()
	if target != null and target.has_method("get_prompt"):
		prompt_changed.emit(str(target.get_prompt()))
	else:
		prompt_changed.emit("")

func _try_interact() -> void:
	var target := get_current_interactable()
	if target != null and target.has_method("interact"):
		target.interact()

## Dipakai HunterEvent: -1..1, >0.6 berarti sedang menatap arah target.
func look_dot_towards(world_pos: Vector3) -> float:
	var forward := -camera.global_transform.basis.z
	var to_target := (world_pos - camera.global_position).normalized()
	return forward.dot(to_target)
