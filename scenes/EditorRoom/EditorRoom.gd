## A room used by the editor and custom levels.
##
## This handles loading the level and switching between playtest modes.
extends Node2D
class_name EditorRoom

@export var should_load_level := true;

@export var level_container: LevelContainer;
@export_file("*.tscn", "*.scn") var playtest_room: String;

@onready var pause_menu: PauseMenu = get_node_or_null(^"PauseMenu");

func _ready():
	if !level_container:
		return;
	if LevelUtil.load_level && should_load_level:
		var err := level_container.deserialize(LevelUtil.load_level);
		if err != "":
			OS.alert(err, "Error loading level!");
			push_error(err);
	if level_container.music:
		if level_container.music != "":
			if level_container.music in Global.songs:
				Music.play.call_deferred(load(Global.songs[level_container.music].path));
			else:
				push_error("Unknown song {0}".format(level_container.music));
	

func _unhandled_input(ev: InputEvent):
	if ev.is_action_pressed("editor_playtest") && !ev.is_action_pressed("setting_fullscreen"):
		playtest();

func playtest():
	if playtest_room:
		if level_container && level_container.editor_mode:
			LevelUtil.load_level = level_container.serialize();
		Fades.change_scene_to_file(playtest_room);

func exit():
	if level_container && level_container.editor_mode:
		LevelUtil.load_level = level_container.serialize();
	if LevelUtil.coming_from_my_levels:
		return Fades.fade_to_scene("res://scenes/MyLevels/MyLevels.tscn");
	else:
		return Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn");

func _on_pause_menu_editor_pressed(_menu: PauseMenu) -> void:
	playtest();
