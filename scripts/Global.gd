extends Node

# global stuff

# this is where the level is stored between scenes
var load_level = null;

var level_manager: LevelManager = null;

# settings
var terrain_detail: int = 2;

# layer ids
const LAYER_A = (1 << 0);
const LAYER_B = (1 << 1);
const LAYER_OBJECTS = (1 << 2);
const LAYER_EDITOR_OBJECTS = (1 << 3);
const LAYER_PLAYER = (1 << 4);
const LAYER_POLYGONS = (1 << 5);

# names of layers.
# this is used by LayeredTileset
const LAYER_A_NAME = "Collision A";
const LAYER_B_NAME = "Collision B";

var handle_theme: Theme = preload("res://sprites/themes/handle.tres")

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
};

func _process(_delta: float):
	if Input.is_action_just_pressed("setting_detail"):
		Global.terrain_detail = int(fposmod(Global.terrain_detail - 1, 3));
		for node: Polygon in get_tree().get_nodes_in_group(&"polygons"):
			node.redraw();
