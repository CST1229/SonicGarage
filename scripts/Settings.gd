extends Node

const SETTINGS_PATH = "user://settings.json";

# TODO: controls customization

var settings_dict: Dictionary = {};

var terrain_detail: int = 2:
	set(value):
		terrain_detail = value;
		for node: Polygon in get_tree().get_nodes_in_group(&"polygons"):
			node.redraw();
		changed.emit(&"terrain_detail");
var fullscreen: bool = false:
	set(value):
		fullscreen = value;
		var window: Window = get_window();
		if (window.mode == Window.Mode.MODE_FULLSCREEN) != fullscreen:
			window.mode = Window.Mode.MODE_FULLSCREEN if fullscreen else Window.Mode.MODE_WINDOWED;
			window.borderless = fullscreen;
		changed.emit(&"fullscreen");

var master_volume: float = 1.0:
	set(value):
		if value == 0.001:
			value = 0;
		master_volume = value;
		set_bus_volume(&"Master", value);
		changed.emit(&"master_volume");
var sfx_volume: float = 1.0:
	set(value):
		if value == 0.001:
			value = 0;
		sfx_volume = value;
		set_bus_volume(&"SFX", value);
		changed.emit(&"sfx_volume");
var music_volume: float = 1.0:
	set(value):
		if value == 0.001:
			value = 0;
		music_volume = value;
		set_bus_volume(&"Music", value);
		changed.emit(&"music_volume");

func set_bus_volume(bus_name: StringName, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name);
	AudioServer.set_bus_volume_linear(bus, volume);


# opt: func(Variant (value to set to), StringName (JSON name)) -> Variant (value that gets get)
func do_settings(opt: Callable) -> void:
	var save_verbatim := func(variable: StringName) -> void:
		set(variable, opt.call(get(variable), variable));
	save_verbatim.call(&"fullscreen");
	save_verbatim.call(&"terrain_detail");
	save_verbatim.call(&"master_volume");
	save_verbatim.call(&"sfx_volume");
	save_verbatim.call(&"music_volume");


func _ready():
	load_settings();

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("setting_detail"):
		terrain_detail = int(fposmod(terrain_detail - 1, 3));
		save_settings();
	if Input.is_action_just_pressed("setting_fullscreen"):
		fullscreen = !fullscreen;
		save_settings();


func load_settings() -> void:
	var global_settings_path = ProjectSettings.globalize_path(SETTINGS_PATH);
	
	var settings_text := FileAccess.get_file_as_string(SETTINGS_PATH);
	if FileAccess.get_open_error() != OK:
		if FileAccess.get_open_error() != ERR_FILE_NOT_FOUND:
			OS.alert("Could not open {0} file. Settings have been reset and will be overwritten next time they are modified.".format([global_settings_path]), "Error loading settings");
		return;
	var parser := JSON.new();
	var err := parser.parse(settings_text);
	if err != OK && settings_text != "":
		OS.alert(
			"Could not parse {2} file: {0}\nat line {1}\nSettings have been reset and will be overwritten next time they are modified.".format([parser.get_error_message(), parser.get_error_line(), global_settings_path]),
			"Error loading settings"
		);
		return;
	if parser.data is not Dictionary:
		OS.alert("{0} file is not a dictionary.\nSettings have been reset and will be overwritten next time they are modified.".format([global_settings_path]), "Error loading settings");
		return;
	
	@warning_ignore("unsafe_cast")
	var json = parser.data as Dictionary;
	do_settings(func(val: Variant, key: StringName) -> Variant:
		return deep_get(json, key, val);
	);

func save_settings() -> void:
	do_settings(func(val: Variant, key: StringName) -> Variant:
		deep_set(settings_dict, key, val);
		return val;
	);
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE);
	if file == null:
		OS.alert(error_string(FileAccess.get_open_error()), "Error saving settings!");
		return;
	file.store_string(JSON.stringify(settings_dict, "\t"));


func deep_set(dict: Dictionary, key: String, value: Variant):
	var dot_index := key.find(".");
	if dot_index > -1:
		var real_key = key.left(dot_index);
		if !(real_key in dict && dict[real_key] is Dictionary):
			dict[real_key] = {};
		deep_set(dict[real_key], key.right(-dot_index - 1), value);
	else:
		dict[key] = value;

func deep_get(dict: Dictionary, key: String, default_value: Variant):
	var dot_index := key.find(".");
	if dot_index > -1:
		var real_key = key.left(dot_index);
		if real_key in dict and dict[real_key] is Dictionary:
			return deep_get(dict[real_key], key.right(-dot_index - 1), default_value);
		return default_value;
	else:
		return dict[key] if key in dict else default_value;

signal changed(setting: StringName);
