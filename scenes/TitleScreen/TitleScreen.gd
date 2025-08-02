extends Node2D

@onready var menu_panel = $CanvasLayer/Tabs/Menu;
@onready var credits_panel = $CanvasLayer/Tabs/Credits;
@onready var settings_panel = $CanvasLayer/Tabs/Settings;
@onready var logo_container: DancingLogo = $CanvasLayer/Tabs/Menu/LogoContainer;
@onready var version: Label = $CanvasLayer/Tabs/Menu/Version;

@onready var levels_button: Button = $CanvasLayer/Tabs/Menu/VBoxContainer/LevelsButton
@onready var settings_button: Button = $CanvasLayer/Tabs/Menu/VBoxContainer/SettingsButton
@onready var credits_button: Button = $CanvasLayer/Tabs/Menu/VBoxContainer/GridContainer/CreditsButton
@onready var credits_back_button: Button = $CanvasLayer/Tabs/Credits/BackButton

@onready var last_menu_button: Control = null;

func _ready():
	version.text = "v" + str(ProjectSettings.get_setting("application/config/version"));
	Music.play(preload("res://music/takeoff.mp3"));
	goto_menu();
	levels_button.grab_focus();

func goto_editor():
	Fades.fade_to_scene("res://scenes/EditorRoom/EditorRoom.tscn");

func goto_levels() -> void:
	Fades.fade_to_scene("res://scenes/MyLevels/MyLevels.tscn");

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
	if !menu_panel.visible:
		menu_panel.visible = true;
		logo_container.cancel_recording();
		if last_menu_button:
			last_menu_button.grab_focus();
			last_menu_button = null;

func goto_settings():
	settings_panel.visible = true;
	settings_panel.entered();
	logo_container.cancel_recording();
	last_menu_button = settings_button;

func goto_credits():
	credits_panel.visible = true;
	logo_container.cancel_recording();
	credits_back_button.grab_focus();
	last_menu_button = credits_button;

func _on_logo_container_show_save_vanilla_logo_option() -> void:
	settings_panel.show_custom_logo_movements_button();

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("editor_quit") && event is not InputEventMouse:
		goto_menu();
		get_viewport().set_input_as_handled();
