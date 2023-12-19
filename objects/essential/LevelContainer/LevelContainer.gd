extends Node
class_name LevelContainer

# a level container contains the level
# (contains polygons and objects).
# it also handles serializing and deserializing the level
# and acts as a link between objects and the editor

@export var editor_mode: bool = false;
@export var editor: LevelEditor = null;

@onready var polygons = $polygons;
@onready var objects = $objects;

const POLYGON_SCENE = preload("res://objects/essential/LevelContainer/Polygon.tscn");
const PLAYER_SCENE = preload("res://objects/essential/Player/Player.tscn");

func deserialize(level):
	for node in polygons.get_children():
		node.queue_free();
	for node in objects.get_children():
		node.queue_free();
	
	for level_poly in level.polygons:
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
	
	if "objects" in level:
		for obj_def in level.objects:
			var node = EditorLib.create_object(obj_def.id, self);
			if !node: continue;
			node.deserialize(obj_def);
			objects.add_child(node);
	
	# pop the player in
	if !editor_mode:
		objects.add_child(PLAYER_SCENE.instantiate());
		
func serialize():
	var data = {
		polygons = [],
		objects = [],
	};
	
	for poly in polygons.get_children():
		var verts_arr = [];
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
