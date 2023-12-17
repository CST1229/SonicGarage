extends Node2D

# a room used by the editor
# (and custom levels)
# this handles loading the level and switching between playtest modes

@export var level_container: Node2D;
@export_file("*.tscn", "*.scn") var playtest_room: String;

func _ready():
	if level_container && Global.load_level:
		level_container.deserialize(Global.load_level);

func _process(_delta):
	if Input.is_action_just_pressed("editor_playtest"):
		playtest();
	elif Input.is_action_just_pressed("editor_quit"):
		if level_container && level_container.editor_mode:
			Global.load_level = level_container.serialize();
		get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn");

func playtest():
	if playtest_room:
		if level_container && level_container.editor_mode:
			Global.load_level = level_container.serialize();
		get_tree().change_scene_to_file(playtest_room);
