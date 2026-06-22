## A room used by the editor and custom levels.
##
## This handles loading the level and switching between playtest modes.
extends Node2D
class_name EditorRoomBase

@export var should_load_level := true;

@export var level_container: LevelContainer;
@export_file("*.tscn", "*.scn") var playtest_room: String;

@onready var pause_menu: PauseMenu = get_node_or_null(^"PauseMenu");

func _ready() -> void:
	if !level_container:
		return;
	if LevelUtil.load_params.level && should_load_level:
		var err := level_container.deserialize(LevelUtil.load_params.level);
		if err != "":
			OS.alert(err, "Error loading level!");
			push_error(err);
	if level_container.music:
		if level_container.music != "":
			level_container.play_music();
	LevelUtil.load_params.is_playtesting_from_pos = false;
	

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("editor_playtest") && !ev.is_action_pressed("setting_fullscreen"):
		playtest();

func playtest() -> void:
	if playtest_room:
		Fades.change_scene_to_file(playtest_room);

func exit() -> void:
	LevelUtil.load_params.newly_loaded_level = true;
	if LevelUtil.coming_from_my_levels:
		return Fades.fade_to_scene("res://scenes/MyLevels/MyLevels.tscn");
	else:
		return Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn");

func _on_pause_menu_editor_pressed(_menu: PauseMenu) -> void:
	Fades.change_scene_to_file("res://scenes/EditorRoom/EditorRoom.tscn");
