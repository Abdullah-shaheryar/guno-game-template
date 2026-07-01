extends Node
## Run stats that persist across scene reloads (autoloads survive reload): lives,
## collected shards, deaths. Reset when a fresh run starts (menu Play / Retry).

signal changed

const START_LIVES := 3

var lives := START_LIVES
var shards := 0
var deaths := 0

func reset() -> void:
	lives = START_LIVES
	shards = 0
	deaths = 0
	changed.emit()

func add_shard(n := 1) -> void:
	shards += n
	changed.emit()

## Lose a life. Returns true if still alive.
func lose_life() -> bool:
	lives -= 1
	deaths += 1
	changed.emit()
	return lives > 0
