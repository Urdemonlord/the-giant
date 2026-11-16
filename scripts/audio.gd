extends Node
## Manajer audio: semua suara disintesis prosedural jadi file .wav
## di assets/audio/ (lihat .src/tools di paket sumber / README).
## Tidak ada aset audio eksternal, tidak ada lisensi pihak ketiga.

var wind: AudioStreamPlayer
var generator_hum: AudioStreamPlayer
var static_player: AudioStreamPlayer
var creak_player: AudioStreamPlayer
var step_player: AudioStreamPlayer
var heartbeat: AudioStreamPlayer
var thud_player: AudioStreamPlayer

func _ready() -> void:
	add_to_group("audio")
	wind = _make_player("wind.wav", -22.0, true)
	generator_hum = _make_player("generator_hum.wav", -16.0, true)
	static_player = _make_player("radio_static.wav", -10.0, false)
	creak_player = _make_player("door_creak.wav", -8.0, false)
	step_player = _make_player("footstep.wav", -14.0, false)
	heartbeat = _make_player("heartbeat.wav", -12.0, true)
	# Dentuman langkah Giant: file DEDIKASI giant_thud.wav (sub sine
	# 75->34 Hz + gemuruh, disintesis tools/synth_audio.py). Dulu ini
	# footstep yang sama dipelankan pitch 0.45; sekarang pitch 1.0.
	thud_player = _make_player("giant_thud.wav", -6.0, false)
	if wind:
		wind.play()
	GameState.generator_changed.connect(_on_generator_changed)
	GameState.sanity_changed.connect(_on_sanity_changed)
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("footstep"):
		player.footstep.connect(_on_footstep)

func _make_player(file_name: String, volume_db: float, loop: bool) -> AudioStreamPlayer:
	var path := "res://assets/audio/" + file_name
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		return null
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	add_child(p)
	return p

func _on_generator_changed(is_on: bool, _fuel: float) -> void:
	if generator_hum == null:
		return
	if is_on and not generator_hum.playing:
		generator_hum.play()
	elif not is_on:
		generator_hum.stop()

func _on_sanity_changed(value: float) -> void:
	if heartbeat == null:
		return
	if value < Balance.HEARTBEAT_SANITY_THRESHOLD and not heartbeat.playing:
		heartbeat.play()
	elif value >= Balance.HEARTBEAT_SANITY_THRESHOLD:
		heartbeat.stop()

func _on_footstep() -> void:
	if step_player and not step_player.playing:
		step_player.play()

func play_static() -> void:
	if static_player:
		static_player.play()

func play_creak() -> void:
	if creak_player:
		creak_player.play()

func play_thud() -> void:
	if thud_player:
		thud_player.play()
