extends Node
## Music-Based Combat (autoload). A steady beat clock (matched to the music's
## ~120 BPM). Firing on-beat powers up your shot; `on_beat()` is the check and
## `pulse()` drives visual feedback.

signal beat(count: int)

@export var bpm: float = 120.0

## Large initial "time since last beat" so on_beat() doesn't report a spurious
## beat before the first real one has fired.
const INITIAL_BEAT_DELAY: float = 99.0

var count: int = 0
var _interval: float = 0.5
var _t: float = 0.0
var _since: float = INITIAL_BEAT_DELAY

func _ready() -> void:
	_interval = 60.0 / bpm

func _process(delta: float) -> void:
	_t += delta
	_since += delta
	if _t >= _interval:
		_t -= _interval
		count += 1
		_since = 0.0
		beat.emit(count)

## True if we're within `window` seconds of a beat (just after or just before).
func on_beat(window: float = 0.15) -> bool:
	return _since <= window or (_interval - _t) <= window

## 1.0 right on the beat, fading toward 0 across the window — for visuals.
func pulse(window: float = 0.18) -> float:
	var d: float = minf(_since, _interval - _t)
	return clampf(1.0 - d / window, 0.0, 1.0)
