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

# Estallido tipo "boom": tres capas superpuestas, técnica estándar de diseño de
# sonido para explosiones (cuerpo grave separado del ruido, con un golpe de
# sub-bajo y un chasquido inicial breve, en vez de un solo ruido con caída):
#  1. Chasquido ("crack"): ruido blanco sin filtrar, ~20ms, es el "crac" seco del instante del impacto.
#  2. Golpe ("thump"): seno que cae de ~110Hz a ~40Hz en los primeros 200ms — el "puñetazo" grave que se siente, no solo se oye.
#  3. Cuerpo: ruido pasado por un filtro pasa-bajos de un polo (mucho más "boom" que ruido blanco crudo, que suena a siseo) con caída exponencial larga para el retumbo.
func _synth_explosion() -> AudioStreamWAV:
	var duration := 0.9
	var n := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(n)

	var lp_state := 0.0
	var lp_alpha := 0.045 # corte aproximado ~300Hz: cuanto más bajo, más grave/apagado el cuerpo

	for i in n:
		var time := float(i) / MIX_RATE
		var white := randf() * 2.0 - 1.0

		lp_state += lp_alpha * (white - lp_state)
		var body := lp_state * exp(-time * 3.5) * 0.75

		var thump_freq := lerpf(110.0, 40.0, clampf(time / 0.2, 0.0, 1.0))
		var thump := sin(TAU * thump_freq * time) * exp(-time * 9.0) * 0.65

		var crack := 0.0
		if time < 0.02:
			crack = white * (1.0 - time / 0.02) * 0.4

		samples[i] = body + thump + crack
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
