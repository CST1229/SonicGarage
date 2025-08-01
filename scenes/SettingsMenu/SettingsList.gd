class_name SettingsMenu
extends VBoxContainer

@onready var fullscreen: CheckButton = $Options/Fullscreen;
@onready var vsync: CheckButton = $Options/VSync;
@onready var integer_scale: CheckButton = $Options/IntegerScale;
@onready var terrain_detail: OptionButton = $Options/TerrainDetail;
@onready var retro_scale: CheckButton = $Options/RetroScale;
@onready var show_fps: CheckButton = $Options/ShowFPS;
@onready var master_volume: HSlider = $Options/MasterVolume;
@onready var sfx_volume: HSlider = $Options/SFXVolume;
@onready var music_volume: HSlider = $Options/MusicVolume;
@onready var mute_on_focus_lost: CheckButton = $Options/MuteOnFocusLost;

func _ready() -> void:
	checkbox_binding(fullscreen, &"fullscreen");
	checkbox_binding(vsync, &"vsync");
	checkbox_binding(integer_scale, &"integer_scale");
	Global.setting_binding(&"terrain_detail", terrain_detail, &"selected", terrain_detail.item_selected,
		func(value: int) -> int: return 2 - value;
	, func(value: int) -> int: return 2 - value;
	);
	handle_save(terrain_detail.item_selected);
	checkbox_binding(show_fps, &"show_fps");
	checkbox_binding(retro_scale, &"hd");
	
	slider_binding(master_volume, &"master_volume");
	slider_binding(music_volume, &"music_volume");
	slider_binding(sfx_volume, &"sfx_volume");
	checkbox_binding(mute_on_focus_lost, &"mute_on_focus_lost");

func checkbox_binding(checkbox: Button, setting_name: StringName):
	Global.setting_binding(setting_name, checkbox, &"button_pressed", checkbox.toggled);
	handle_save(checkbox.toggled);

func slider_binding(slider: Slider, setting_name: StringName):
	Global.setting_binding(setting_name, slider, &"value", slider.value_changed);
	handle_save_slider(slider.drag_ended);


func handle_setting(listen: Signal, settings_var: StringName):
	listen.connect(func(value: Variant):
		Settings.set(settings_var, value);
	);
func handle_save_slider(listen: Signal):
	listen.connect(func(value_changed: bool):
		if value_changed: Settings.save_settings();
	);
func handle_save(listen: Signal):
	listen.connect(func(_arg: Variant):
		Settings.save_settings();
	);
