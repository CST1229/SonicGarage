extends Node2D

@onready var menu_panel = $CanvasLayer/Menu;
@onready var credits_panel = $CanvasLayer/Credits;
@onready var controls_panel = $CanvasLayer/Controls;

func goto_editor():
	get_tree().change_scene_to_file("res://scenes/EditorRoom/EditorRoom.tscn");
	
func goto_test():
	get_tree().change_scene_to_file("res://scenes/test.tscn");

func load_level():
	if Input.is_key_pressed(KEY_CTRL) && Input.is_key_pressed(KEY_SHIFT):
		get_tree().change_scene_to_file("res://scenes/test.tscn");
		return;
	DisplayServer.file_dialog_show(
		"Load Level", "",
		"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.sgl", "*"]),
		EditorLib.load_level_play
	);

func quit():
	get_tree().quit();

func toggle_controls():
	menu_panel.visible = !menu_panel.visible;
	controls_panel.visible = !controls_panel.visible;

func toggle_credits():
	menu_panel.visible = !menu_panel.visible;
	credits_panel.visible = !credits_panel.visible;

