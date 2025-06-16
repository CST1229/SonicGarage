## Draws the decoration a [Polygon].
extends Node2D
class_name PolygonDecoration

var parsed_vertices: Array[Vertex];
var decor_sections: Array[DecorSection];

@export var layer: Decor.Layer = Decor.Layer.SOLID;

func maybe_redraw(valid: bool, _parsed_vertices: Array[Vertex], _decor_sections: Array[DecorSection]):
	visible = valid;
	if valid:
		parsed_vertices = _parsed_vertices;
		decor_sections = _decor_sections;
		queue_redraw();

func _draw():
	if !parsed_vertices:
		return;
	if Settings.terrain_detail <= 0 || (layer != Decor.Layer.SOLID && Settings.terrain_detail <= 1):
		return;
	LevelDrawing.draw_decor(self, decor_sections, layer);
