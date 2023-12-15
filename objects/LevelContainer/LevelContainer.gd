extends Node
class_name LevelContainer
@export var editor_mode: bool = false;

@onready var polygons = $polygons;
@onready var objects = $objects;

const POLYGON_SCENE = preload("res://objects/LevelContainer/Polygon.tscn");
const PLAYER_SCENE = preload("res://objects/Player/Player.tscn");

func deserialize(level):
	for node in polygons.get_children():
		node.queue_free();
	for node in objects.get_children():
		node.queue_free();
	
	for level_poly in level.polygons:
		var poly = POLYGON_SCENE.instantiate();
		poly.container = self;
		for vert_arr in level_poly.vertices:
			var vert = EditorLib.create_vertex(Vector2(vert_arr[0], vert_arr[1]));
			poly.vertices.append(vert);
			vert.polygon = poly;
		polygons.add_child(poly);
	
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
			verts_arr.append([vert.position.x, vert.position.y]);
		data.polygons.append({
			vertices = verts_arr,
		});
		
	for obj in objects.get_children():
		var obj_data = obj.get_node("data");
		if obj_data:
			data.objects.append(obj_data.serialize());
	
	return data;
