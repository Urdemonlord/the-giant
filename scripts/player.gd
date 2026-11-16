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
var shake_strength := 0.0
## Input sentuh (diisi TouchControls): x = strafe, y = maju/mundur (-1 = maju).
var touch_move := Vector2.ZERO
## Dipakai test rig playtest untuk mengarahkan pandangan tanpa mouse.
var look_override := false

## Dipanggil event Giant: getaran tanah mengguncang kamera sesaat.
func shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight

signal prompt_changed(text: String)
signal footstep

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
		apply_look(-event.relative.x * MOUSE_SENS, -event.relative.y * MOUSE_SENS)
	if event.is_action_pressed("flashlight"):
		toggle_flashlight()
	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	var horizontal := Vector2(velocity.x, velocity.z).length()
	if horizontal > 0.4 and is_on_floor():
		bob_time += delta * horizontal * 1.6
		camera.position.y = sin(bob_time * 2.0) * 0.035
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = 2.4 / horizontal
			footstep.emit()
	else:
		camera.position.y = lerpf(camera.position.y, 0.0, delta * 8.0)
	# Guncangan (langkah Giant): acak kecil yang meluruh cepat.
	if shake_strength > 0.001:
		camera.position.x = randf_range(-1.0, 1.0) * shake_strength * 0.05
		camera.position.y += randf_range(-1.0, 1.0) * shake_strength * 0.05
		shake_strength = lerpf(shake_strength, 0.0, delta * 3.0)
	else:
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 8.0)
	_update_prompt()

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
