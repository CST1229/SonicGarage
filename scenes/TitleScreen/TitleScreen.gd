extends Node2D

func goto_editor():
	get_tree().change_scene_to_file("res://scenes/EditorRoom/EditorRoom.tscn");
	
func goto_test():
	get_tree().change_scene_to_file("res://scenes/test.tscn");

func load_level():
	DisplayServer.file_dialog_show(
		"Load Level", "",
		"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.sgl", "*"]),
		EditorLib.load_level_play
	);

func quit():
	get_tree().quit();
