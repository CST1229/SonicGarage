## A global level manager.
extends Node
class_name LevelManager

var rings: int = 0:
	set(value):
		rings = value;
		if ring_count_label:
			ring_count_label.text = str(rings);

@onready var ring_count_label: Label = $UI/HUD/RingCount;

func _ready():
	LevelUtil.level_manager = self;
