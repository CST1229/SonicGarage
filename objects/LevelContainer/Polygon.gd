extends Node2D
class_name Polygon

var vertices: Array[Vertex] = [];
var vectors: PackedVector2Array = PackedVector2Array();
var valid: bool = false;
const INVALID_COLOR = Color(1, 0.2, 0.1)

var container: LevelContainer;

@onready var collision_polygon = $collision/collision_polygon;


func _ready():
	update_polygon();

func _draw():
	if valid:
		draw_colored_polygon(vectors, Color.WHITE);
	
	if !container || !container.editor_mode: return;
	
	if !valid:
		if !container || !container.editor_mode: return;
		draw_polyline(vectors, INVALID_COLOR, 3, false);
		draw_line(vectors[0], vectors[-1], INVALID_COLOR, 3, false);
	for vert in vertices:
		EditorLib.draw_vert(self, vert.position, 1.0, vert.selected);

func update_polygon():
	vectors.clear();
	for vert in vertices:
		vectors.append(vert.position);
	
	var triangulated = Geometry2D.triangulate_polygon(vectors);
	valid = triangulated.size() > 0;
	
	if valid:
		collision_polygon.polygon = vectors;
	else:
		collision_polygon.polygon = PackedVector2Array();
	queue_redraw();
