extends Node2D

@export var level_container: Node2D;
@export_file("*.tscn", "*.scn") var playtest_room: String;

func _ready():
	if level_container && Global.load_level:
		level_container.deserialize(Global.load_level);

func _process(_delta):
	if playtest_room && Input.is_action_just_pressed("editor_playtest"):
		if level_container && level_container.editor_mode:
			Global.load_level = level_container.serialize();
		get_tree().change_scene_to_file(playtest_room);
	elif Input.is_action_just_pressed("editor_quit"):
		if level_container && level_container.editor_mode:
			Global.load_level = level_container.serialize();
		get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn");
