## A global level manager.
extends Node
class_name LevelManager

var rings: int = 0;

@onready var ring_count_label: Label = $UI/HUD/RingCount;

func _ready():
	Global.level_manager = self;

func _process(_delta: float):
	ring_count_label.text = String.num(rings);
