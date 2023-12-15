extends Node

var load_level = null;
var editor_node = null;

class ObjectDef:
	var scene: PackedScene;
	var name: String;

func obj(ui_name: String, scene: PackedScene):
	var def = ObjectDef.new();
	def.name = ui_name;
	def.scene = scene;

var object_list = {
	layer_switcher = obj(
		"Layer Switcher", preload("res://objects/LayerSwitcher/LayerSwitcher.tscn")
	),
};
