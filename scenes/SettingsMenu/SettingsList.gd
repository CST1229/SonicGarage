class_name SettingsMenu
extends VBoxContainer

@onready var fullscreen: CheckButton = $Options/Fullscreen;
@onready var terrain_detail: OptionButton = $Options/TerrainDetail
@onready var master_volume: HSlider = $Options/MasterVolume;
@onready var sfx_volume: HSlider = $Options/SFXVolume;
@onready var music_volume: HSlider = $Options/MusicVolume;

func _ready() -> void:
	Global.setting_binding(&"terrain_detail", terrain_detail, &"selected", terrain_detail.item_selected, func(value: int) -> int:
		return 2 - value;
	, func(value: int) -> int:
		return 2 - value;
	);
	Global.setting_binding(&"master_volume", master_volume, &"value", master_volume.value_changed);
	Global.setting_binding(&"sfx_volume", sfx_volume, &"value", sfx_volume.value_changed);
	Global.setting_binding(&"music_volume", music_volume, &"value", music_volume.value_changed);
	Global.setting_binding(&"fullscreen", fullscreen, &"button_pressed", fullscreen.toggled);
	
	handle_save(fullscreen.toggled);
	handle_save(terrain_detail.item_selected);
	handle_save_slider(master_volume.drag_ended);
	handle_save_slider(sfx_volume.drag_ended);
	handle_save_slider(music_volume.drag_ended);

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
