extends Node2D

@onready var menu_panel = $CanvasLayer/Tabs/Menu;
@onready var credits_panel = $CanvasLayer/Tabs/Credits;
@onready var settings_panel = $CanvasLayer/Tabs/Settings;
@onready var settings_menu: SettingsMenu = $CanvasLayer/Tabs/Settings/HMargin/ScrollContainer/VMargin/SettingsMenu;

func _ready():
	goto_menu();

func goto_editor():
	Fades.fade_to_scene("res://scenes/EditorRoom/EditorRoom.tscn");

func load_level():
	if Input.is_key_pressed(KEY_CTRL) && Input.is_key_pressed(KEY_SHIFT):
		Fades.fade_to_scene("res://scenes/test.tscn");
		return;
	DisplayServer.file_dialog_show(
		"Load Level", "",
		"level.sgl", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.sgl;Sonic Garage Levels (*.sgl)", "*;All Files (*.*)"]),
		EditorLib.load_level_play
	);

func quit():
	get_tree().quit();

func goto_menu():
	menu_panel.visible = true;

func goto_settings():
	settings_panel.visible = true;

func goto_credits():
	credits_panel.visible = true;


func _on_open_folder_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"));
