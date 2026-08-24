extends Node

const MIX_RATE := 44100
const POOL_SIZE := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready() -> void:
	_ensure_players()

func _ensure_players() -> void:
	# El arnés de pruebas `--script` no dispara `_ready()` en autoloads (no corre
	# el bucle normal del motor), así que el pool se crea también de forma perezosa aquí.
	if not _players.is_empty():
		return
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0, jitter: float = 0.05) -> void:
	_ensure_players()
	if not is_inside_tree():
		# El arnés de pruebas `--script` no boota los autoloads en el árbol real;
		# en el juego real (editor o build) esto siempre es true.
		return
	var stream := _get_stream(sound_name)
	if stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale + randf_range(-jitter, jitter)
	player.play()

func _get_stream(sound_name: String) -> AudioStreamWAV:
	if _cache.has(sound_name):
		return _cache[sound_name]
	var stream: AudioStreamWAV = _generate(sound_name)
	if stream != null:
		_cache[sound_name] = stream
	return stream

func _generate(sound_name: String) -> AudioStreamWAV:
	match sound_name:
		"shoot":
			return _synth_shoot()
		"explosion":
			return _synth_explosion()
		"hit":
			return _synth_hit()
		"bounce":
			return _synth_bounce()
		"ui_click":
			return _synth_ui_click()
		"eliminated":
			return _synth_eliminated()
		"victory":
			return _synth_victory()
		_:
			return null

func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v: float = clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	wav.data = bytes
	return wav

# "Pew" corto: barrido descendente con caída rápida.
func _synth_shoot() -> AudioStreamWAV:
	var duration := 0.12
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var progress := float(i) / n
		var time := float(i) / MIX_RATE
		var freq := lerpf(900.0, 220.0, progress)
		var env := pow(1.0 - progress, 2.0)
		samples[i] = sin(TAU * freq * time) * env * 0.5
	return _make_wav(samples)

# Estallido: ruido filtrado + retumbo grave, caída cúbica.
func _synth_explosion() -> AudioStreamWAV:
	var duration := 0.5
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev_noise := 0.0
	for i in n:
		var progress := float(i) / n
		var time := float(i) / MIX_RATE
		var env := pow(1.0 - progress, 3.0)
		var noise := randf() * 2.0 - 1.0
		var filtered := (noise + prev_noise) * 0.5
		prev_noise = noise
		var rumble := sin(TAU * 60.0 * time) * 0.4
		samples[i] = (filtered * 0.7 + rumble * 0.5) * env
	return _make_wav(samples)

# Golpe corto y seco (impacto en jugador/roca).
func _synth_hit() -> AudioStreamWAV:
	var duration := 0.15
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var progress := float(i) / n
		var time := float(i) / MIX_RATE
		var env := pow(1.0 - progress, 4.0)
		samples[i] = sin(TAU * 140.0 * time) * env * 0.6
	return _make_wav(samples)

# "Boop" ascendente para el rebote de la granada rebotante.
func _synth_bounce() -> AudioStreamWAV:
	var duration := 0.1
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var progress := float(i) / n
		var time := float(i) / MIX_RATE
		var freq := lerpf(300.0, 700.0, progress)
		var env := pow(1.0 - progress, 2.0)
		samples[i] = sin(TAU * freq * time) * env * 0.4
	return _make_wav(samples)

# Click de UI, casi inaudible en duración.
func _synth_ui_click() -> AudioStreamWAV:
	var duration := 0.05
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var progress := float(i) / n
		var time := float(i) / MIX_RATE
		var env := pow(1.0 - progress, 3.0)
		samples[i] = sin(TAU * 1200.0 * time) * env * 0.3
	return _make_wav(samples)

# "Womp" descendente para la eliminación de un jugador.
func _synth_eliminated() -> AudioStreamWAV:
	var duration := 0.6
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var progress := float(i) / n
		var time := float(i) / MIX_RATE
		var freq := lerpf(500.0, 90.0, progress)
		var env := pow(1.0 - progress, 1.5)
		samples[i] = sin(TAU * freq * time) * env * 0.5
	return _make_wav(samples)

# Arpegio de 3 notas ascendentes para el podio/victoria.
func _synth_victory() -> AudioStreamWAV:
	var notes: Array[float] = [523.25, 659.25, 783.99]
	var note_duration := 0.15
	var n_per_note := int(MIX_RATE * note_duration)
	var samples := PackedFloat32Array()
	samples.resize(n_per_note * notes.size())
	for note_i in notes.size():
		var freq: float = notes[note_i]
		for i in n_per_note:
			var idx := note_i * n_per_note + i
			var progress := float(i) / n_per_note
			var time := float(i) / MIX_RATE
			var env := pow(1.0 - progress, 1.5)
			samples[idx] = sin(TAU * freq * time) * env * 0.4
	return _make_wav(samples)
