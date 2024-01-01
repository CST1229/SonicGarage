extends Node

# global stuff

# this is where the level is stored between scenes
var load_level = null;

var level_manager: LevelManager = null;

class ObjectDef:
	var scene: PackedScene;
	var name: String;
func obj(ui_name: String, scene: PackedScene):
	var def = ObjectDef.new();
	def.name = ui_name;
	def.scene = scene;
	return def;

# list of objects (used by deserialization)
var object_list: Dictionary = {
	layer_switcher = obj(
		"Layer Switcher", preload("res://objects/level/LayerSwitcher/LayerSwitcher.tscn")
	),
	ring = obj(
		"Ring", preload("res://objects/level/Ring/Ring.tscn")
	),
	signpost = obj(
		"Signpost", preload("res://objects/level/Signpost/Signpost.tscn")
	),
	motobug = obj(
		"Motobug", preload("res://objects/enemies/Motobug/Motobug.tscn")
	),
	monitor = obj(
		"Item Monitor", preload("res://objects/level/Monitor/Monitor.tscn")
	),
};

# settings
var terrain_detail: int = 2;

# layer ids
const LAYER_A = (1 << 0);
const LAYER_B = (1 << 1);
const LAYER_EDITOR_OBJECTS = (1 << 3);
const LAYER_PLAYER = (1 << 4);
const LAYER_POLYGONS = (1 << 5);
const LAYER_MONITORS = (1 << 6);

# names of layers.
# this is used by LayeredTileset
const LAYER_A_NAME = "Collision A";
const LAYER_B_NAME = "Collision B";

var handle_theme: Theme = preload("res://sprites/themes/handle.tres");

var windowed_mode: Window.Mode = Window.Mode.MODE_WINDOWED;

func _process(_delta: float):
	if Input.is_action_just_pressed("setting_detail"):
		Global.terrain_detail = int(fposmod(Global.terrain_detail - 1, 3));
		for node: Polygon in get_tree().get_nodes_in_group(&"polygons"):
			node.redraw();
	if Input.is_action_just_pressed("setting_fullscreen"):
		var window: Window = get_window();
		if window.mode == Window.Mode.MODE_FULLSCREEN:
			window.mode = windowed_mode;
		else:
			windowed_mode = window.mode;
			window.mode = Window.Mode.MODE_FULLSCREEN;
		window.borderless = window.mode == Window.Mode.MODE_FULLSCREEN;
		
