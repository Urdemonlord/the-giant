extends Node
## Manajer audio: semua SFX disintesis prosedural jadi file .wav
## di assets/audio/ (lihat tools/synth_audio.py). Suara radio
## (radio_voice_1..5.wav) disintesis dari teks siaran lewat gTTS
## bahasa Indonesia, lalu diproses jadi radio tua rusak (band-pass
## 300-3000 Hz + statis, lihat tools/make_radio_voice.py).
## Tidak ada aset audio eksternal berlisensi pihak ketiga.

var wind: AudioStreamPlayer
var generator_hum: AudioStreamPlayer
var static_player: AudioStreamPlayer
var creak_player: AudioStreamPlayer
var step_player: AudioStreamPlayer
var heartbeat: AudioStreamPlayer
var thud_player: AudioStreamPlayer
var voice_players: Array[AudioStreamPlayer] = []

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
	# Suara siaran radio (gTTS id + proses radio rusak). Urutan 1..5
	# = urutan LINES di scripts/interactables/radio.gd.
	for i in range(1, 6):
		var v := _make_player("radio_voice_%d.wav" % i, -8.0, false)
		if v != null:
			voice_players.append(v)
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
		# Tiap langkah sedikit beda nada (0.92-1.08) supaya langkah
		# berulang tidak terdengar seperti mesin (file footstep
		# cuma satu, v2 synth_audio.py).
		step_player.pitch_scale = randf_range(0.92, 1.08)
		step_player.play()

func play_static() -> void:
	if static_player:
		static_player.play()

func play_radio_voice(index: int) -> void:
	# index 0..4 = baris siaran 1..5 di radio.gd. Matikan suara
	# siaran lain yang masih bunyi supaya tidak tumpang tindih.
	if index < 0 or index >= voice_players.size():
		return
	for v in voice_players:
		if v.playing:
			v.stop()
	voice_players[index].play()

func radio_voice_playing() -> bool:
	for v in voice_players:
		if v.playing:
			return true
	return false

func play_creak() -> void:
	if creak_player:
		creak_player.play()

func play_thud() -> void:
	if thud_player:
		thud_player.play()
