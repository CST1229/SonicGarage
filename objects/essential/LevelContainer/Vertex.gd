## Abstract data structure used by [Polygon]s.
##
## I don't just use [Vector2] because of curves,
## and so I can pass them by reference and have stuff like
## an [Array] of selected [Vertex]es and I can just move them by
## modifying their positions.
class_name Vertex

var position: Vector2 = Vector2.ZERO;
var global_position: Vector2:
	get:
		return position + polygon.position;
	set(value):
		position = value - polygon.position;
		
var polygon: Polygon = null;
var selected: bool = false;
var edge: StringName = &"auto";

func duplicate() -> Vertex:
	var new_vert := Vertex.new();
	new_vert.position = position;
	new_vert.polygon = polygon;
	new_vert.edge = edge;
	new_vert.selected = selected;
	
	return new_vert;
