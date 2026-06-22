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

@onready var not_copyright: Label = $CanvasLayer/Tabs/Menu/NotCopyright;

@onready var play_file_dialog: FileDialog = $CanvasLayer/Tabs/Menu/VBoxContainer/PlayFileDialog;

@onready var last_menu_button: Control = null;

func _ready():
	DirAccess.make_dir_recursive_absolute(LevelUtil.FOLDER);
	version.text = "v" + str(ProjectSettings.get_setting("application/config/version"));
	Music.play(preload("res://music/takeoff.ogg"));
	goto_menu();
	levels_button.grab_focus();
	not_copyright.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == 1:
			OS.shell_open("https://www.github.com/CST1229/SonicGarage");
	);
	
	get_window().files_dropped.connect(on_files_dropped);

func on_files_dropped(files: PackedStringArray) -> void:
	if files.size() == 1:
		if files[0].to_lower().ends_with(".sgl"):
			LevelUtil.coming_from_my_levels = false;
			LevelUtil.load_params.newly_loaded_level = true;
			EditorLib.load_level(false, files[0], true);

func goto_editor():
	Fades.fade_to_scene("res://scenes/EditorRoom/EditorRoom.tscn");

func goto_levels() -> void:
	if Input.is_key_pressed(KEY_CTRL) || Input.is_key_pressed(KEY_SHIFT):
		LevelUtil.coming_from_my_levels = false;
		Fades.fade_to_scene("res://scenes/EditorRoom/EditorRoom.tscn");
		return;
	Fades.fade_to_scene("res://scenes/MyLevels/MyLevels.tscn");

func load_level():
	if Input.is_key_pressed(KEY_CTRL) && Input.is_key_pressed(KEY_SHIFT):
		LevelUtil.coming_from_my_levels = false;
		Fades.fade_to_scene("res://scenes/test.tscn", {is_white = true, extra_wait = 0.5});
		return;
	play_file_dialog.hide();
	play_file_dialog.current_dir = LevelUtil.FOLDER;
	play_file_dialog.current_file = "level.sgl";
	play_file_dialog.popup();

func _on_play_file_dialog_file_selected(path: String) -> void:
	LevelUtil.coming_from_my_levels = false;
	LevelUtil.load_params.newly_loaded_level = true;
	EditorLib.load_level(false, path, true);

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
	if event.is_action_pressed("ui_cancel") && event is not InputEventMouse:
		goto_menu();
		get_viewport().set_input_as_handled();
	elif event.is_action_released("setting_disclaimer"):
		get_viewport().set_input_as_handled();
		if Settings.show_disclaimer:
			Settings.show_disclaimer = false;
			GlobalSounds.play_ring();
			OS.alert("Disclaimer disabled.", "You pressed F7");
		else:
			Settings.show_disclaimer = true;
			GlobalSounds.play_spindash();
			OS.alert("Disclaimer enabled.", "You pressed F7");
		Settings.save_settings();
