class_name EditorRoom
extends EditorRoomBase

@onready var playtest_trails: Line2D = $PlaytestTrails;

func _ready() -> void:
	super();
	if LevelUtil.newly_loaded_level:
		LevelUtil.playtest_trails.clear();
		LevelUtil.newly_loaded_level = false;
	
	if !LevelUtil.playtest_trails.is_empty():
		playtest_trails.points = LevelUtil.playtest_trails;
