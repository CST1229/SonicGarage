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

var keybinds: Dictionary[StringName, Array] = {};

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
	deserialize_binds(opt.call(serialize_binds(keybinds), &"keybinds"));

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

# i took most of this keybind serialization code from multibranches lol
var BINDABLE_KEYS: Array[StringName] = InputMap.get_actions().filter(func(action_name: StringName):
	return action_name.begins_with("player_") || action_name.begins_with("editor_");
) as Array[StringName];

func serialize_binds(binds: Dictionary[StringName, Array]) -> Dictionary[StringName, Array]:
	for key: StringName in BINDABLE_KEYS:
		binds[key] = serialize_action(key);
	return binds;

# should be Dictionary[StringName, Array] but godot compound types are dumb
func deserialize_binds(binds: Dictionary) -> void:
	for key: StringName in BINDABLE_KEYS:
		if key in binds and binds[key] is Array:
			deserialize_action(Array(binds[key]), key);

func serialize_action(action: StringName) -> Array[Array]:
	var arr: Array[Array] = [];
	if !InputMap.has_action(action):
		return arr;
	for event: InputEvent in InputMap.action_get_events(action):
		var device = event.device;
		if event is InputEventKey:
			arr.append(["key", device, (event as InputEventKey).physical_keycode
]);
		elif event is InputEventJoypadButton:
			arr.append(["joypadbutton", device, (event as InputEventJoypadButton).button_index]);
		elif event is InputEventMouseButton:
			arr.append(["mousebutton", device, (event as InputEventMouseButton).button_index]);
		elif event is InputEventJoypadMotion:
			arr.append(["joypadmotion", device, (event as InputEventJoypadMotion).axis, (event as InputEventJoypadMotion).axis_value]);
	return arr;

func deserialize_action(events: Array, action: StringName) -> void:
	if !InputMap.has_action(action):
		InputMap.add_action(action);
	InputMap.action_erase_events(action);
	for serialized: Array in events:
		var type: String = serialized[0];
		var device: int = serialized[1];
		match type:
			"key":
				var ev := InputEventKey.new();
				ev.device = device;
				ev.pressed = true;
				ev.physical_keycode = serialized[2];
				InputMap.action_add_event(action, ev);
			"joypadbutton":
				var ev := InputEventJoypadButton.new();
				ev.device = device;
				ev.pressed = true;
				ev.button_index = serialized[2];
				InputMap.action_add_event(action, ev);
			"joypadmotion":
				var ev := InputEventJoypadMotion.new();
				ev.device = device;
				ev.axis = serialized[2];
				ev.axis_value = serialized[3];
				InputMap.action_add_event(action, ev);
			"mousebutton":
				var ev := InputEventMouseButton.new();
				ev.device = device;
				ev.pressed = true;
				ev.button_index = serialized[2];
				InputMap.action_add_event(action, ev);
			_:
				push_error("{0} has unknown keybind type {1}".format([action, type]));

func get_bind_name(event: InputEvent, include_pad: bool = true) -> String:
	if event is InputEventJoypadButton:
		var pad_name: String = "Pad{0}: ".format([event.device + 1]) if include_pad else "";
		return "{0}{1}".format([pad_name, get_joypad_button_name(event.button_index)])
	elif event is InputEventJoypadMotion:
		var pad_name: String = "Pad{0}: ".format([event.device + 1]) if include_pad else "";
		return "{0}{1}".format([pad_name, get_joypad_axis_name(event.axis, event.axis_value)])
	else:
		return event.as_text().replace(" (Physical)", "");

func get_joypad_button_name(button: JoyButton) -> String:
	match button:
		JOY_BUTTON_A: return "A";
		JOY_BUTTON_B: return "B";
		JOY_BUTTON_X: return "X";
		JOY_BUTTON_Y: return "Y";
		JOY_BUTTON_BACK: return "Back";
		JOY_BUTTON_START: return "Start";
		JOY_BUTTON_GUIDE: return "Guide";
		JOY_BUTTON_DPAD_UP: return "D-Pad Up";
		JOY_BUTTON_DPAD_DOWN: return "D-Pad Down";
		JOY_BUTTON_DPAD_LEFT: return "D-Pad Left";
		JOY_BUTTON_DPAD_RIGHT: return "D-Pad Right";
		JOY_BUTTON_LEFT_STICK: return "L Stick Press";
		JOY_BUTTON_RIGHT_STICK: return "R Stick Press";
		JOY_BUTTON_LEFT_SHOULDER: return "L Shoulder";
		JOY_BUTTON_RIGHT_SHOULDER: return "R Shoulder";
		JOY_BUTTON_MISC1: return "Misc.";
		JOY_BUTTON_PADDLE1: return "Paddle 1";
		JOY_BUTTON_PADDLE2: return "Paddle 2";
		JOY_BUTTON_PADDLE3: return "Paddle 3";
		JOY_BUTTON_PADDLE4: return "Paddle 4";
		JOY_BUTTON_TOUCHPAD: return "Touchpad";
		_: return "Unknown";

func get_joypad_axis_name(axis: JoyAxis, value: float = 1) -> String:
	var hor_axis := "Left" if value < 0 else "Right";
	var ver_axis := "Up" if value < 0 else "Down";
	match axis:
		JOY_AXIS_LEFT_X: return "L Stick {0}".format([hor_axis]);
		JOY_AXIS_LEFT_Y: return "L Stick {0}".format([ver_axis]);
		JOY_AXIS_RIGHT_X: return "R Stick {0}".format([hor_axis]);
		JOY_AXIS_RIGHT_Y: return "R Stick {0}".format([ver_axis]);
		JOY_AXIS_TRIGGER_LEFT: return "L Trigger";
		JOY_AXIS_TRIGGER_RIGHT: return "R Trigger";
		_: return "Unknown";

signal changed(setting: StringName);
