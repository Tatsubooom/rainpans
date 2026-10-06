extends Node
## Sound: builds every drum voice by modal synthesis at load time (no sample
## files), owns the bus layout and a small voice pool.

const RATE := 32000
## D major pentatonic, in semitones from D.
const SCALE := [0, 2, 4, 7, 9]
const VOICES := 40

var _samples := {}
var _voices: Array[AudioStreamPlayer2D] = []
var _next_voice := 0
var _last_hit := {} # drum instance id -> msec, to thin out machine-gun hits

var rain_bed: AudioStreamPlayer
var rain_patter: AudioStreamPlayer
var room_tone: AudioStreamPlayer


func _ready() -> void:
	_setup_buses()
	for i in VOICES:
		var p := AudioStreamPlayer2D.new()
		p.bus = "Drums"
		p.max_distance = 4000.0
		p.attenuation = 0.0
		p.panning_strength = 0.7
		add_child(p)
		_voices.append(p)
	rain_bed = _loop_player(_make_rain_loop(4.0, 0.0), "Ambience", -14.0)
	rain_patter = _loop_player(_make_rain_loop(3.0, 1.0), "Ambience", -40.0)
	room_tone = _loop_player(_make_room_tone(6.0), "Ambience", -38.0)


func _setup_buses() -> void:
	AudioServer.bus_count = 3
	AudioServer.set_bus_name(1, "Drums")
	AudioServer.set_bus_send(1, "Master")
	AudioServer.set_bus_name(2, "Ambience")
	AudioServer.set_bus_send(2, "Master")

	var rev := AudioEffectReverb.new()
	rev.room_size = 0.78
	rev.damping = 0.55
	rev.spread = 0.9
	rev.hipass = 0.12
	rev.dry = 0.85
	rev.wet = 0.32
	AudioServer.add_bus_effect(1, rev)
	var delay := AudioEffectDelay.new()
	delay.dry = 1.0
	delay.tap1_active = true
	delay.tap1_delay_ms = 410.0
	delay.tap1_level_db = -14.0
	delay.tap1_pan = -0.4
	delay.tap2_active = true
	delay.tap2_delay_ms = 830.0
	delay.tap2_level_db = -20.0
	delay.tap2_pan = 0.4
	delay.feedback_active = false
	AudioServer.add_bus_effect(1, delay)
	AudioServer.set_bus_effect_enabled(1, 1, false)
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 5200.0
	AudioServer.add_bus_effect(1, lp)

	var amb_lp := AudioEffectLowPassFilter.new()
	amb_lp.cutoff_hz = 3800.0
	AudioServer.add_bus_effect(2, amb_lp)

	var comp := AudioEffectCompressor.new()
	comp.threshold = -14.0
	comp.ratio = 3.0
	comp.attack_us = 2000.0
	comp.release_ms = 250.0
	AudioServer.add_bus_effect(0, comp)


func set_echo(on: bool) -> void:
	AudioServer.set_bus_effect_enabled(1, 1, on)


func set_reverb_wet(wet: float, room: float) -> void:
	var rev := AudioServer.get_bus_effect(1, 0) as AudioEffectReverb
	rev.wet = wet
	rev.room_size = room


func _loop_player(stream: AudioStream, bus: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	p.autoplay = true
	add_child(p)
	return p


## Rain intensity 0..1 drives the ambience mix.
func set_rain_level(level: float) -> void:
	if rain_bed == null:
		return
	rain_bed.volume_db = lerpf(-26.0, -11.0, clampf(level * 1.4, 0.0, 1.0))
	rain_patter.volume_db = lerpf(-42.0, -15.0, clampf(level, 0.0, 1.0))


# --------------------------------------------------------------------- voices

func sample(id: String) -> AudioStreamWAV:
	if not _samples.has(id):
		_samples[id] = _make_drum(DrumDefs.get_def(id))
	return _samples[id]


## Pre-builds all voices so the first hit of a new drum never stutters.
func warm(ids: Array) -> void:
	for id in ids:
		sample(id)


## Scale degree (can be negative or > 4) to pitch multiplier.
static func degree_ratio(deg: int) -> float:
	var octave := floori(deg / 5.0)
	var step: int = SCALE[posmod(deg, 5)]
	return pow(2.0, (octave * 12 + step) / 12.0)


## Beat grid for the optional quantize: eighth notes at 72 BPM.
const GRID_MS := 60000.0 / 72.0 / 2.0
var _queue: Array = [] # [due_msec, id, degree, pos, velocity]
var _slots := {} # "key@slot" -> true, one note per drum per grid slot


func _process(_delta: float) -> void:
	if _queue.is_empty():
		return
	var now := Time.get_ticks_msec()
	var i := 0
	while i < _queue.size():
		var q: Array = _queue[i]
		if now >= q[0]:
			_voice(q[1], q[2], q[3], q[4])
			_queue.remove_at(i)
		else:
			i += 1
	if _slots.size() > 512:
		_slots.clear()


func play(id: String, degree: int, pos: Vector2, velocity: float, key: int) -> bool:
	var now := Time.get_ticks_msec()
	if Game.settings.get("quantize", false) and key >= 0:
		# Hold the note until the next eighth; one note per drum per slot.
		var slot := int(ceil(now / GRID_MS))
		var sk := "%d@%d" % [key, slot]
		if _slots.has(sk):
			return false
		_slots[sk] = true
		_queue.append([int(slot * GRID_MS), id, degree, pos, velocity])
		return true
	var last: int = _last_hit.get(key, -100000)
	if now - last < 70:
		return false
	_last_hit[key] = now
	_voice(id, degree, pos, velocity)
	return true


func _voice(id: String, degree: int, pos: Vector2, velocity: float) -> void:
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = sample(id)
	p.pitch_scale = degree_ratio(degree) * randf_range(0.996, 1.004)
	p.volume_db = linear_to_db(clampf(velocity, 0.05, 1.0)) - 6.0
	p.global_position = pos
	p.play()


# ------------------------------------------------------------------ synthesis

func _make_drum(d: Dictionary) -> AudioStreamWAV:
	var modes: Array = d.modes
	var longest := 0.0
	for m in modes:
		longest = maxf(longest, m[2])
	var length := minf(longest * 5.0 + 0.05, 6.0)
	var n := int(length * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	buf.fill(0.0)
	var f0: float = d.freq
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.name)
	for m in modes:
		var freq: float = f0 * m[0] * rng.randf_range(0.997, 1.003)
		if freq >= RATE * 0.45:
			continue
		var amp: float = m[1]
		var decay: float = m[2]
		# Recursive sine oscillator: y[n] = 2cos(w)y[n-1] - y[n-2].
		var w := TAU * freq / RATE
		var k := 2.0 * cos(w)
		var y1 := sin(-w)
		var y2 := sin(-2.0 * w)
		var g := exp(-1.0 / (decay * RATE))
		var env := amp
		var frames := mini(n, int(decay * 7.0 * RATE))
		for i in frames:
			var y := k * y1 - y2
			y2 = y1
			y1 = y
			buf[i] += y * env
			env *= g
	# Impact: a short burst of filtered noise (the drop itself).
	var nz: Array = d.noise
	var namp: float = nz[0]
	var ndec: float = nz[1]
	var lp := 0.0
	var ng := exp(-1.0 / (ndec * RATE))
	var nenv := namp
	for i in mini(n, int(ndec * 8.0 * RATE)):
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.35
		buf[i] += lp * nenv * 2.0
		nenv *= ng
	# Soft attack (2ms) and normalisation.
	var att := int(0.002 * RATE)
	var peak := 0.0001
	for i in n:
		if i < att:
			buf[i] *= float(i) / att
		peak = maxf(peak, absf(buf[i]))
	return _to_wav(buf, 0.85 / peak, false)


## Rain loop: pink-ish noise, crossfaded so the loop point is seamless.
## `grain` 0 gives a soft hiss, 1 a patter made of many tiny ticks.
func _make_rain_loop(seconds: float, grain: float) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var fade := int(0.5 * RATE)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + int(grain * 100)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var tick_env := 0.0
	var tick_lp := 0.0
	for i in raw.size():
		var white := rng.randf_range(-1.0, 1.0)
		b0 = 0.99765 * b0 + white * 0.0990460
		b1 = 0.96300 * b1 + white * 0.2965164
		b2 = 0.57000 * b2 + white * 1.0526913
		var pink := (b0 + b1 + b2 + white * 0.1848) * 0.12
		var s := pink * (1.0 - grain * 0.7)
		if grain > 0.0:
			if rng.randf() < 0.0045:
				tick_env = rng.randf_range(0.3, 1.0)
			tick_lp += (white - tick_lp) * 0.6
			s += tick_lp * tick_env * 0.5
			tick_env *= 0.992
		raw[i] = s
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		buf[i] = raw[i]
	for i in fade:
		var t := float(i) / fade
		buf[i] = raw[i] * t + raw[n + i] * (1.0 - t)
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	return _to_wav(buf, 0.7 / peak, true)


## A very quiet low drone (wind through the ruins) under everything.
func _make_room_tone(seconds: float) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.02
		lp2 += (lp - lp2) * 0.05
		var t := float(i) / RATE
		# Whole cycles over the loop length keep it seamless.
		var swell := 0.6 + 0.4 * sin(TAU * t / seconds)
		buf[i] = lp2 * swell + sin(TAU * 73.42 * t) * 0.02 * swell
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	return _to_wav(buf, 0.6 / peak, true)


func _to_wav(buf: PackedFloat32Array, gain: float, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = buf.size()
	return wav
