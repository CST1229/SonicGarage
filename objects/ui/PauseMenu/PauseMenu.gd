@tool
class_name PauseMenu
extends CanvasLayer

@export var active := false:
	set(value):
		active = value;
		visible = value;
		if !Engine.is_editor_hint():
			if is_inside_tree():
				get_tree().paused = value;
				if visible && resume:
					resume.grab_focus();
			Music.update_audio();

@export var is_in_editor: bool = false:
	set(value):
		is_in_editor = value;
		if v_box_container:
			for child in v_box_container.get_children():
				if is_in_editor:
					child.visible = child.is_in_group(&"editor");
				else:
					child.visible = child.is_in_group(&"level");
			editor.visible = editor.visible && editor_pressed.has_connections();
@export var is_playtest: bool = false;

var level_container: LevelContainer;

@onready var resume: Button = %Resume;
@onready var playtest: Button = %Playtest;
@onready var restart: Button = %Restart;
@onready var save: Button = %Save;
@onready var save_as: Button = %SaveAs;
@onready var load_button: Button = %Load;
@onready var level_properties: Button = %LevelProperties;
@onready var editor: Button = %Editor;
@onready var settings: Button = %Settings;
@onready var quit: Button = %Quit;

@onready var tab_container: TabContainer = $TabContainer;
@onready var pause_tab: MarginContainer = $TabContainer/Pause;
var settings_tab: Panel;

@onready var v_box_container: VBoxContainer = pause_tab.get_node(^"Pause/VBoxContainer");

@onready var bg_fade: Fade = $Fade;

func _ready() -> void:
	active = false;
	
	if is_playtest && !Engine.is_editor_hint():
		editor.text = "Enter Editor";
	
	if Engine.is_editor_hint():
		is_in_editor = is_in_editor;
		return;
	
	resume.pressed.connect(func():
		active = false;
	);
	restart.pressed.connect(func():
		var fade: Fade = Fades.fade_to_scene("restart");
		if !fade:
			active = false;
			get_viewport().gui_release_focus();
			return;
		fade.process_mode = PROCESS_MODE_ALWAYS;
		fade.tween.tween_callback(func():
			active = false;
			fade.process_mode = Node.PROCESS_MODE_PAUSABLE;
			Fades.fade_container.layer = 499;
		);
		process_mode = Node.PROCESS_MODE_DISABLED;
		Fades.fade_container.layer = 501;
		get_viewport().gui_release_focus();
	);
	
	settings.pressed.connect(func():
		settings_tab = load("res://scenes/SettingsMenu/SettingsMenu.tscn").instantiate();
		tab_container.add_child(settings_tab);
		settings_tab.visibility_changed.connect(func():
			if !settings_tab.visible:
				settings_tab.queue_free();
		);
		
		settings_tab.visible = true;
		settings_tab.entered();
		settings_tab.go_back.connect.call_deferred(func():
			go_back();
		);
	);
	quit.pressed.connect(func():
		quit_pressed.emit(self);
		var fade: Fade = Fades.fade_to_scene("res://scenes/TitleScreen/TitleScreen.tscn" if !LevelUtil.coming_from_my_levels else "res://scenes/MyLevels/MyLevels.tscn");
		if !fade: return;
		fade.process_mode = PROCESS_MODE_ALWAYS;
		fade.tween.tween_callback(func():
			active = false;
			fade.process_mode = Node.PROCESS_MODE_PAUSABLE;
			Fades.fade_container.layer = 499;
		);
		process_mode = Node.PROCESS_MODE_DISABLED;
		Fades.fade_container.layer = 501;
		get_viewport().gui_release_focus();
	);
	
	playtest.pressed.connect(playtest_pressed.emit.bind(self));
	editor.pressed.connect(editor_pressed.emit.bind(self));
	save.pressed.connect(save_pressed.emit.bind(self));
	save_as.pressed.connect(save_as_pressed.emit.bind(self));
	load_button.pressed.connect(load_pressed.emit.bind(self));
		
	bg_fade.clicked.connect(func():
		go_back();
	);
	is_in_editor = is_in_editor;

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if active:
			go_back();
		else:
			active = true;

func go_back():
	if settings_tab:
		pause_tab.show();
		settings.grab_focus();
	else:
		active = false;

signal playtest_pressed(menu: PauseMenu)
signal editor_pressed(menu: PauseMenu)
signal save_pressed(menu: PauseMenu)
signal save_as_pressed(menu: PauseMenu)
signal load_pressed(menu: PauseMenu)
signal quit_pressed(menu: PauseMenu)
