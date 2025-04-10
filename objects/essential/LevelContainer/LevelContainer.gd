## The main container for a level.
##
## A LevelContainer contains the level ([Polygon]s and objects).
## It also handles serializing and deserializing the level
## and acts as a link between objects and the [LevelEditor].
extends Node
class_name LevelContainer

@export var editor_mode: bool = false;
@export var editor: LevelEditor = null;

@onready var polygons = $polygons;
@onready var objects = $objects;
@onready var players = $players;

const FORMAT_VERSION = 2;

const POLYGON_SCENE = preload("res://objects/essential/LevelContainer/Polygon.tscn");
const PLAYER_SCENE = preload("res://objects/essential/Player/Player.tscn");

func deserialize(level) -> String:
	if !(level is Dictionary) || !("format" in level):
		return "Invalid level";
	
	if level.format > FORMAT_VERSION:
		return "Level is too new! Has format version: {0} (current is {1})".format([level.format, FORMAT_VERSION])
	
	deserialize_polygons(level.polygons);
	deserialize_objects(level.objects if "objects" in level else []);
	add_players();
	
	return "";

func deserialize_polygons(polys: Array) -> void:
	for node in polygons.get_children():
		node.queue_free();
	for level_poly in polys:
		var poly = POLYGON_SCENE.instantiate();
		poly.container = self;
		for json_vert in level_poly.vertices:
			var vert;
			if json_vert is Array:
				vert = EditorLib.create_vertex(Vector2(json_vert[0], json_vert[1]));
			else:
				vert = EditorLib.create_vertex(Vector2(json_vert.x, json_vert.y));
				vert.edge = json_vert.edge;
			poly.vertices.append(vert);
			vert.polygon = poly;
		if "layer" in level_poly:
			poly.layer = level_poly.layer;
		polygons.add_child(poly);

func deserialize_objects(objs: Array) -> void:
	for node in objects.get_children():
		node.queue_free();
	for obj_def in objs:
		var node = EditorLib.create_object(obj_def.id, self);
		if !node: continue;
		node.deserialize(obj_def);
		objects.add_child(node);

func add_players() -> void:
	for node in players.get_children():
		node.queue_free();
	if !editor_mode:
		players.add_child(PLAYER_SCENE.instantiate());

func serialize() -> Dictionary:
	var data = {
		format = FORMAT_VERSION,
		polygons = [],
		objects = [],
	};
	
	for poly in polygons.get_children():
		var verts_arr: Array[Dictionary] = [];
		for vert in poly.vertices:
			verts_arr.append({
				x = vert.position.x,
				y = vert.position.y,
				edge = vert.edge,
			});
		data.polygons.append({
			vertices = verts_arr,
			layer = poly.layer,
		});
		
	for obj in objects.get_children():
		if obj.has_method("serialize"):
			data.objects.append(obj.serialize());
	
	return data;
