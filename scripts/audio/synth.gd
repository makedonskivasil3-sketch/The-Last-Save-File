class_name Synth
extends RefCounted
## A tiny offline synthesiser: every sound in the game is rendered once from
## code into an AudioStreamWAV and cached (see Sfx). No audio files.
##
## Usage: var b := Synth.begin(1.2)  ->  Synth.tone(b, ...), Synth.noise(b, ...)
##        ->  Synth.to_wav(b). All times are in seconds, frequencies in Hz,
## amplitudes 0..1. Envelopes are "attack, then exponential decay at rate k"
## (k = 1/s; bigger k = shorter). Everything is plain loops over a
## PackedFloat32Array, so keep sounds short and render them off the hot path.

enum Wave { SINE, SQUARE, SAW, TRIANGLE }

## Sample rate used by the next begin()/helpers. Low drones use 11025.
static var rate := 22050


## A silent buffer `seconds` long at `sample_rate`.
static func begin(seconds: float, sample_rate: int = 22050) -> PackedFloat32Array:
	rate = sample_rate
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	return b


## An oscillator with an exponential pitch sweep f0 -> f1 and an
## attack/decay envelope. vibrato = (depth 0..1, speed Hz).
static func tone(b: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, amp: float,
		wave: Wave = Wave.SINE, attack: float = 0.004, k: float = 6.0, vibrato := Vector2.ZERO) -> void:
	var i0 := int(start * rate)
	var n := mini(int(dur * rate), b.size() - i0)
	if n <= 0:
		return
	var f := f0
	var step := pow(f1 / f0, 1.0 / n)
	var dec := exp(-k / rate)
	var env := 1.0
	var att := maxf(attack * rate, 1.0)
	var ph := 0.0
	for i in n:
		var fv := f
		if vibrato.x > 0.0:
			fv *= 1.0 + vibrato.x * sin(TAU * vibrato.y * i / rate)
		ph += fv / rate
		ph -= floorf(ph)
		var v: float
		if wave == Wave.SINE:
			v = sin(TAU * ph)
		elif wave == Wave.SQUARE:
			v = 1.0 if ph < 0.5 else -1.0
		elif wave == Wave.SAW:
			v = 2.0 * ph - 1.0
		else:
			v = 4.0 * absf(ph - 0.5) - 1.0
		var a := minf(1.0, i / att) * env
		b[i0 + i] += v * amp * a
		env *= dec
		f *= step


## Noise burst. lp: one-pole low-pass amount 0..1 (1 = unfiltered, small =
## dark rumble). lp_end sweeps the filter over the burst. hp removes lows.
static func noise(b: PackedFloat32Array, start: float, dur: float, amp: float, attack: float = 0.002,
		k: float = 20.0, lp: float = 1.0, lp_end: float = -1.0, hp: bool = false) -> void:
	var i0 := int(start * rate)
	var n := mini(int(dur * rate), b.size() - i0)
	if n <= 0:
		return
	if lp_end < 0.0:
		lp_end = lp
	var dec := exp(-k / rate)
	var env := 1.0
	var att := maxf(attack * rate, 1.0)
	var y := 0.0
	for i in n:
		var a_lp := lerpf(lp, lp_end, float(i) / n)
		var x := randf() * 2.0 - 1.0
		y += a_lp * (x - y)
		var v := (x - y) if hp else y
		b[i0 + i] += v * amp * minf(1.0, i / att) * env
		env *= dec


## Sparse random clicks: digital crackle. density = clicks per second.
static func crackle(b: PackedFloat32Array, start: float, dur: float, density: float, amp: float) -> void:
	var i0 := int(start * rate)
	var n := mini(int(dur * rate), b.size() - i0)
	var p := density / rate
	var i := 0
	while i < n:
		if randf() < p:
			var click := randi_range(8, 60)
			var s := randf_range(-1.0, 1.0) * amp
			for j in mini(click, n - i):
				b[i0 + i + j] += s * (1.0 - float(j) / click)
			i += click
		i += 1


## Sample-and-hold + quantise: crunchy, broken-console sound.
static func crush(b: PackedFloat32Array, start: float, dur: float, bits: int, hold: int) -> void:
	var i0 := int(start * rate)
	var n := mini(int(dur * rate), b.size() - i0)
	var levels := pow(2.0, bits - 1)
	var held := 0.0
	for i in n:
		if i % maxi(hold, 1) == 0:
			held = roundf(b[i0 + i] * levels) / levels
		b[i0 + i] = held


## Whole-buffer one-pole low-pass (a: 0..1).
static func lowpass(b: PackedFloat32Array, a: float) -> void:
	var y := 0.0
	for i in b.size():
		y += a * (b[i] - y)
		b[i] = y


## Random on/off gating at `rate_hz`: tearing, buzzing, scratching.
static func gate(b: PackedFloat32Array, start: float, dur: float, rate_hz: float, duty: float) -> void:
	var i0 := int(start * rate)
	var n := mini(int(dur * rate), b.size() - i0)
	var seg := maxi(int(rate / rate_hz), 1)
	var on := true
	for i in n:
		if i % seg == 0:
			on = randf() < duty
		if not on:
			b[i0 + i] *= 0.08


## Fold the part after `loop_len` seconds back onto the start (so tails of
## late notes ring into the beginning) and trim: seamless loops.
static func wrap(b: PackedFloat32Array, loop_len: float) -> PackedFloat32Array:
	var n := int(loop_len * rate)
	for i in range(n, b.size()):
		b[i - n] += b[i]
	b.resize(n)
	return b


## Crossfade the last `xfade` seconds into the start: seamless noise loops.
static func loop_crossfade(b: PackedFloat32Array, xfade: float) -> PackedFloat32Array:
	var x := int(xfade * rate)
	var n := b.size() - x
	for i in x:
		var t := float(i) / x
		b[i] = b[i] * t + b[n + i] * (1.0 - t)
	b.resize(n)
	return b


static func fade_out(b: PackedFloat32Array, seconds: float) -> void:
	var n := mini(int(seconds * rate), b.size())
	var s := b.size() - n
	for i in n:
		b[s + i] *= 1.0 - float(i) / n


## Scale so the loudest sample is `peak`.
static func normalize(b: PackedFloat32Array, peak: float = 0.9) -> void:
	var m := 0.0
	for v in b:
		m = maxf(m, absf(v))
	if m < 0.0001:
		return
	var g := peak / m
	for i in b.size():
		b[i] *= g


## Render to a 16-bit mono AudioStreamWAV (optionally looping).
static func to_wav(b: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = b.size()
	return wav
