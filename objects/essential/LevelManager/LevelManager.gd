## A global level manager.
extends Node
class_name LevelManager

var tick_time := true;

var rings: int = 0:
	set(value):
		rings = value;
		if ring_count_label:
			ring_count_label.text = str(rings);
var level_time := 0.0:
	set(value):
		level_time = value;
		if time_label:
			var time_text := "";
			if level_time >= (60 * 60):
				time_text = "     %d:%02d:%05.2f" % [
					level_time / (60 * 60),
					fmod(level_time / 60, 60),
					fmod(level_time, 60)
				];
			else:
				time_text = "     %d:%05.2f" % [
					level_time / 60,
					fmod(level_time, 60)
				];
				
			time_label.text = time_text;

@onready var time_label: Label = $UI/HUD/Stats/Time;
@onready var ring_count_label: Label = $UI/HUD/Stats/RingCount;

func _ready():
	LevelUtil.level_manager = self;
	# activate setters
	rings = rings;
	level_time = level_time;

func _physics_process(delta: float) -> void:
	if tick_time:
		level_time += delta;
