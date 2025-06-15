## A room used by the editor and custom levels.
##
## This handles loading the level and switching between playtest modes.
extends Node2D
class_name EditorRoom

@export var level_container: LevelContainer;
@export_file("*.tscn", "*.scn") var playtest_room: String;

func _ready():
	if level_container && LevelUtil.load_level:
		var err := level_container.deserialize(LevelUtil.load_level);
		if err != "":
			OS.alert(err, "Error loading level!");
			push_error(err);

func _process(_delta: float):
	if Input.is_action_just_pressed("editor_playtest") && !Input.is_action_pressed("setting_fullscreen"):
		playtest();
	elif Input.is_action_just_pressed("editor_quit"):
		exit();

func playtest():
	if playtest_room:
		if level_container && level_container.editor_mode:
			LevelUtil.load_level = level_container.serialize();
		Fades.change_scene_to_file(playtest_room);

func exit():
	if level_container && level_container.editor_mode:
		LevelUtil.load_level = level_container.serialize();
	Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn");
