extends Node
## Living Weapon (autoload). The gun evolves with your playstyle: each mode
## levels up the more you use it, unlocking stronger effects (handled by the
## modes that read level()). Emits leveled_up for HUD/audio feedback.

signal leveled_up(mode_key: String, level: int)

const PER_LEVEL := 4
const MAX_LEVEL := 3

var uses: Dictionary = {}
var levels: Dictionary = {}

func register_use(mode_key: String) -> void:
	uses[mode_key] = int(uses.get(mode_key, 0)) + 1
	@warning_ignore("integer_division")
	var lvl: int = mini(MAX_LEVEL, int(uses[mode_key]) / PER_LEVEL)
	if lvl > int(levels.get(mode_key, 0)):
		levels[mode_key] = lvl
		leveled_up.emit(mode_key, lvl)

func level(mode_key: String) -> int:
	return int(levels.get(mode_key, 0))

func total_level() -> int:
	var t := 0
	for k in levels:
		t += int(levels[k])
	return t
