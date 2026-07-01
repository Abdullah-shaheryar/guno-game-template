extends Area2D
## A sapling. Time-forward ages it into a giant tree whose branches form a
## climbable staircase up to a high ledge; time-rewind shrinks it back.

@onready var sapling_vis: Polygon2D = $SaplingVisual
@onready var trunk_vis: Polygon2D = $TrunkVisual
@onready var canopy_vis: Polygon2D = $CanopyVisual

var grown: bool = false
var _steps: Array = []

func _ready() -> void:
	_steps = [$Step1, $Step2, $Step3]
	_refresh()

func apply_time(direction: int, _bolt: Node) -> void:
	grown = direction > 0
	_refresh()

func _refresh() -> void:
	sapling_vis.visible = not grown
	trunk_vis.visible = grown
	canopy_vis.visible = grown
	for s in _steps:
		s.get_node("Col").disabled = not grown
		s.get_node("Vis").visible = grown
