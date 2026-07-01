extends Node
## Global audio (autoload). ALL sound is synthesized from scratch at startup —
## original oscillator + envelope DSP, no sample files — so the template ships
## with zero third-party audio (no licensing/copyright to track). One-shot SFX
## play via a throwaway-player pool; a 120 BPM chiptune loop (matched to the
## BeatClock) plays as the music bed.

const SR := 22050          # sample rate (Hz), mono 16-bit throughout
const TAU_ := TAU

var _sfx: Dictionary = {}
var _music: AudioStreamPlayer

func _ready() -> void:
	_sfx = {
		"shoot": _wav(_sfx_shoot()),
		"jump": _wav(_sfx_jump()),
		"hit": _wav(_sfx_hit()),
		"levelup": _wav(_sfx_levelup()),
	}
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.stream = _wav(_music_loop(), true)
	_music.volume_db = -13.0
	_music.play()

## Master volume (0..1) — drives the whole game's audio via the master bus.
func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(linear, 0.0001, 1.0)))

func play(sfx: String, volume_db: float = -3.0) -> void:
	var s = _sfx.get(sfx)
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	add_child(p)
	p.stream = s
	p.volume_db = volume_db
	p.finished.connect(p.queue_free)
	p.play()

# --- Synthesis core ----------------------------------------------------------

## Pack a mono float buffer (-1..1) into a 16-bit AudioStreamWAV.
func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	var n := samples.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v: int = int(round(clampf(samples[i], -1.0, 1.0) * 32767.0))
		bytes.encode_s16(i * 2, v)
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w

func _square(phase: float, duty := 0.5) -> float:
	return 1.0 if fmod(phase, 1.0) < duty else -1.0

func _tri(phase: float) -> float:
	return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0

# --- SFX ---------------------------------------------------------------------

func _sfx_shoot() -> PackedFloat32Array:      # descending square "pew"
	var dur := 0.12
	var n := int(dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var p := float(i) / n
		var freq: float = lerp(900.0, 200.0, p)
		phase += freq / SR
		out[i] = _square(phase, 0.5) * exp(-p * 5.0) * 0.5
	return out

func _sfx_jump() -> PackedFloat32Array:       # rising square blip
	var dur := 0.13
	var n := int(dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var p := float(i) / n
		var freq: float = lerp(320.0, 760.0, p)
		phase += freq / SR
		out[i] = _square(phase, 0.5) * exp(-p * 4.0) * 0.42
	return out

func _sfx_hit() -> PackedFloat32Array:        # noise transient + low thud
	var dur := 0.16
	var n := int(dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var p := float(i) / n
		var freq: float = lerp(180.0, 90.0, p)
		phase += freq / SR
		var noise := randf_range(-1.0, 1.0) * exp(-p * 22.0)
		var thud := sin(TAU_ * phase) * exp(-p * 9.0)
		out[i] = clampf(noise * 0.5 + thud * 0.6, -1.0, 1.0) * 0.7
	return out

func _sfx_levelup() -> PackedFloat32Array:    # ascending arpeggio chime
	var notes := [523.25, 659.25, 783.99, 1046.5]   # C5 E5 G5 C6
	var note_dur := 0.1
	var n := int(notes.size() * note_dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / SR
		var idx: int = mini(int(t / note_dur), notes.size() - 1)
		var lp := (t - idx * note_dur) / note_dur
		var env := exp(-lp * 3.5) * (1.0 - exp(-lp * 40.0))
		out[i] = _tri(notes[idx] * t) * env * 0.4
	return out

# --- Music (120 BPM chiptune loop) -------------------------------------------

func _music_loop() -> PackedFloat32Array:
	var beat := 0.5                  # 120 BPM
	var eighth := beat * 0.5
	var total_beats := 8             # 2 bars → 4.0s seamless loop
	var n := int(total_beats * beat * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	# i–VI–III–VII in A minor: Am, F, C, G (2 beats each).
	var bass_roots := [110.0, 87.31, 130.81, 98.0]
	var chords := [
		[220.0, 261.63, 329.63],     # Am
		[174.61, 220.0, 261.63],     # F
		[261.63, 329.63, 392.0],     # C
		[196.0, 246.94, 293.66],     # G
	]
	for i in n:
		var t := float(i) / SR
		var gbeat: int = int(t / beat)
		@warning_ignore("integer_division")
		var chord: int = (gbeat / 2) % 4
		var t_in_beat := t - gbeat * beat
		# Bass: plucked square root note each beat.
		var bass := _square(bass_roots[chord] * t, 0.5) * exp(-t_in_beat * 6.0) * 0.18
		# Arpeggio: triangle eighth-notes cycling the chord tones.
		var geighth: int = int(t / eighth)
		var t_in_e := t - geighth * eighth
		var tone: float = chords[chord][geighth % 3]
		var arp_env := exp(-t_in_e * 8.0) * (1.0 - exp(-t_in_e * 60.0))
		var arp := _tri(tone * t) * arp_env * 0.14
		# Kick on beats 1 and 3 of each bar.
		var kick := 0.0
		if gbeat % 2 == 0:
			var kf: float = lerp(120.0, 45.0, minf(t_in_beat / 0.08, 1.0))
			kick = sin(TAU_ * kf * t_in_beat) * exp(-t_in_beat * 24.0) * 0.35
		out[i] = clampf(bass + arp + kick, -1.0, 1.0)
	return out
