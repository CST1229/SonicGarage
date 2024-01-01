extends Node2D
class_name PolygonDecoration

var parsed_vertices: Array[Vertex];

@export var is_shadow: bool = false;

func _draw():
	if !parsed_vertices:
		return;
	if Global.terrain_detail <= 0 || (is_shadow && Global.terrain_detail <= 1):
		return;
	LevelDrawing.draw_ghz_grass(self, parsed_vertices, is_shadow);
