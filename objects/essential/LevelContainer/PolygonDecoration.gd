## Draws the decoration a [Polygon].
extends Node2D
class_name PolygonDecoration

var parsed_vertices: Array[Vertex];
var decor_sections: Array[DecorSection];

@export var is_shadow: bool = false;

func _draw():
	if !parsed_vertices:
		return;
	if Global.terrain_detail <= 0 || (is_shadow && Global.terrain_detail <= 1):
		return;
	LevelDrawing.draw_decor(self, decor_sections, is_shadow);
