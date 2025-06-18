extends Node2D

@onready var menu_panel = $CanvasLayer/Tabs/Menu;
@onready var credits_panel = $CanvasLayer/Tabs/Credits;
@onready var settings_panel = $CanvasLayer/Tabs/Settings;
@onready var logo_container: DancingLogo = $CanvasLayer/Tabs/Menu/LogoContainer;
@onready var version: Label = $CanvasLayer/Tabs/Menu/Version;

func _ready():
	version.text = "v" + str(ProjectSettings.get_setting("application/config/version"));
	Music.play(preload("res://music/takeoff.mp3"));
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
	var fade := Fades.create_fade(true, false, func(_fade):
		get_tree().quit();
	);
	fade.affects_volume = true;

func goto_menu():
	menu_panel.visible = true;
	logo_container.cancel_recording();

func goto_settings():
	settings_panel.visible = true;
	logo_container.cancel_recording();

func goto_credits():
	credits_panel.visible = true;
	logo_container.cancel_recording();
