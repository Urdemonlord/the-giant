extends Node
## Manajer audio: semua SFX disintesis prosedural jadi file .wav
## di assets/audio/ (lihat tools/synth_audio.py). Suara radio
## (radio_voice_1..5.wav) disintesis dari teks siaran lewat gTTS
## bahasa Indonesia, lalu diproses jadi radio tua rusak (band-pass
## 300-3000 Hz + statis, lihat tools/make_radio_voice.py).
## Tidak ada aset audio eksternal berlisensi pihak ketiga.

## v14 (audio-design): bus layout Master <- Ambience / SFX / Voice
## (default_bus_layout.tres). Sebelumnya semua di Master; sekarang
## ambience bisa di-duck saat radio bersuara, dan mix per kelompok
## bisa di-tune tanpa menyentuh tiap player.
var wind: AudioStreamPlayer
var crickets: AudioStreamPlayer
var generator_hum: AudioStreamPlayer
var static_player: AudioStreamPlayer
var creak_player: AudioStreamPlayer
var step_player: AudioStreamPlayer
var heartbeat: AudioStreamPlayer
var thud_player: AudioStreamPlayer
var distant_thud: AudioStreamPlayer
var voice_players: Array[AudioStreamPlayer] = []
var _ambience_bus := -1
var _ducked := false
var _duck_tween: Tween
var _next_distant := 60.0 # detik sampai dentum jauh pertama

func _ready() -> void:
	add_to_group("audio")
	_ambience_bus = AudioServer.get_bus_index("Ambience")
	wind = _make_player("wind.wav", -22.0, true, "Ambience")
	# Jangkrik malam (v14): bed ambience di atas angin, sangat pelan.
	crickets = _make_player("crickets.wav", -30.0, true, "Ambience")
	generator_hum = _make_player("generator_hum.wav", -16.0, true, "Ambience")
	static_player = _make_player("radio_static.wav", -10.0, false, "SFX")
	creak_player = _make_player("door_creak.wav", -8.0, false, "SFX")
	step_player = _make_player("footstep.wav", -14.0, false, "SFX")
	heartbeat = _make_player("heartbeat.wav", -12.0, true, "SFX")
	# Dentuman langkah Giant: file DEDIKASI giant_thud.wav (sub sine
	# 75->34 Hz + gemuruh, disintesis tools/synth_audio.py). Dulu ini
	# footstep yang sama dipelankan pitch 0.45; sekarang pitch 1.0.
	thud_player = _make_player("giant_thud.wav", -6.0, false, "SFX")
	# Dentum jauh (v14): stream yang sama, tapi -20 dB + pitch 0.8,
	# supaya terdengar dari kejauhan, bukan dari dalam pos.
	distant_thud = _make_player("giant_thud.wav", -20.0, false, "SFX")
	if distant_thud != null:
		distant_thud.pitch_scale = 0.8
	# Suara siaran radio (gTTS id + proses radio rusak). Urutan 1..5
	# = urutan LINES di scripts/interactables/radio.gd.
	for i in range(1, 6):
		var v := _make_player("radio_voice_%d.wav" % i, -8.0, false, "Voice")
		if v != null:
			voice_players.append(v)
	if wind:
		wind.play()
	if crickets:
		crickets.play()
	GameState.generator_changed.connect(_on_generator_changed)
	GameState.sanity_changed.connect(_on_sanity_changed)
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("footstep"):
		player.footstep.connect(_on_footstep)

func _process(delta: float) -> void:
	# Ducking (audio-design Pattern 2, tanpa kompresor): saat siaran
	# radio bersuara, ambience (angin + jangkrik + hum) turun 6 dB
	# supaya suara cerita tidak tenggelam; kembali saat siaran habis.
	if _ambience_bus >= 0:
		var voice_on := radio_voice_playing()
		if voice_on != _ducked:
			_ducked = voice_on
			if _duck_tween and _duck_tween.is_running():
				_duck_tween.kill()
			var from := AudioServer.get_bus_volume_db(_ambience_bus)
			_duck_tween = create_tween()
			_duck_tween.tween_method(_set_ambience_db, from, -6.0 if _ducked else 0.0, 0.25)
	_update_distant_thud(delta)

func _set_ambience_db(v: float) -> void:
	if _ambience_bus >= 0:
		AudioServer.set_bus_volume_db(_ambience_bus, v)

## Dentum jauh (v14): Giant terdengar dari kejauhan sebelum event
## kaki 03:30 — petunjuk audio tanpa menampakkan apa pun. Hanya di
## jendela jam Balance, tidak saat event pemburu/Giant aktif, tidak
## saat radio bersuara, tidak saat dentum dekat sedang bunyi.
func _update_distant_thud(delta: float) -> void:
	if distant_thud == null or GameState.shift_over:
		return
	var m := GameState.shift_minutes
	if m < Balance.DISTANT_THUD_EARLIEST or m > Balance.DISTANT_THUD_LATEST:
		return
	var giant := get_tree().get_first_node_in_group("giant_event")
	if giant != null and str(giant.get("active_event")) != "":
		return
	var hunter := get_tree().get_first_node_in_group("hunter_event")
	if hunter != null and bool(hunter.get("_active")):
		return
	if (thud_player != null and thud_player.playing) or distant_thud.playing:
		return
	if radio_voice_playing():
		return
	_next_distant -= delta
	if _next_distant <= 0.0:
		_next_distant = randf_range(Balance.DISTANT_THUD_MIN_GAP, Balance.DISTANT_THUD_MAX_GAP)
		distant_thud.play()

func _make_player(file_name: String, volume_db: float, loop: bool, bus := "Master") -> AudioStreamPlayer:
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
	# Bus harus ada di layout; kalau nama salah, Godot fallback ke
	# Master + log error — dicek tools/verify_atmosphere.gd.
	p.bus = bus
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
