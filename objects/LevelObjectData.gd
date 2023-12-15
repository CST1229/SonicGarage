extends Node2D
class_name LevelObjectData

@export var type: String = "";
@export var x: float = 0;
@export var y: float = 0;

var serialize_vars: Array[String] = ["type", "x", "y"];

var in_editor: bool = false;

func vars() -> Array[String]:
	return [];

func _ready():
	position.x = x;
	position.y = y;
	serialize_vars.append_array(vars());

func serialize():
	var json = {};
	for key in serialize_vars:
		json[key] = get(key);
	return json;

func deserialize(json: Dictionary):
	for key in json.keys():
		if key != "type" && serialize_vars.has(key):
			set(key, json[key]);
