extends Node2D
class_name EditorRoom

# a room used by the editor
# (and custom levels)
# this handles loading the level and switching between playtest modes

@export var level_container: Node2D;
@export_file("*.tscn", "*.scn") var playtest_room: String;

func _ready():
	if level_container && Global.load_level:
		level_container.deserialize(Global.load_level);

func _process(_delta: float):
	if Input.is_action_just_pressed("editor_playtest") && !Input.is_action_pressed("setting_fullscreen"):
		playtest();
	elif Input.is_action_just_pressed("editor_quit"):
		exit();

func playtest():
	if playtest_room:
		if level_container && level_container.editor_mode:
			Global.load_level = level_container.serialize();
		get_tree().change_scene_to_file(playtest_room);

func exit():
	if level_container && level_container.editor_mode:
		Global.load_level = level_container.serialize();
	get_tree().change_scene_to_file("res://scenes/TitleScreen/TitleScreen.tscn");
