## A Polygon is a part of the terrain, made out of [Vertex]es.
extends Node2D
class_name Polygon

var vertices: Array[Vertex] = [];
## An array of [Vertex]es after being parsed, e.g flattening curves.
var parsed_vertices: Array[Vertex] = [];
var decor_sections: Array[DecorSection];
var vectors: PackedVector2Array = PackedVector2Array();
var semisolid: bool = false:
	set(value):
		semisolid = value;
		update_layer();
var valid: bool = false;

var layer: String = "ab":
	set(value):
		layer = value;
		update_layer();
var layer_num: int = LevelUtil.LAYER_A | LevelUtil.LAYER_B;

const INVALID_COLOR = Color(1, 0.2, 0.1);
const SELECTED_COLOR = EditorLib.VERT_COLOR;

var container: LevelContainer;

var is_counterclockwise := false;

@onready var collision: StaticBody2D = $collision;
@onready var collision_polygon: CollisionPolygon2D = $collision/collision_polygon;
@onready var fill: Polygon2D = $polygon;
@onready var decor: PolygonDecoration = $decor;
@onready var shadow_decor: PolygonDecoration = $polygon/shadow_decor;
@onready var highlight_decor: PolygonDecoration = $polygon/highlight_decor;

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED;
	add_to_group(&"polygons");
	update_polygon();
	update_layer();
	
func get_color() -> Color:
	var c := Color.BLACK;
	if layer_num & LevelUtil.LAYER_A:
		c = Color(c.r, c.g + 0.5, c.b + 1);
	if layer_num & LevelUtil.LAYER_B:
		c = Color(c.r + 1, c.g + 0.5, c.b);
	return c;

func redraw() -> void:
	decor.maybe_redraw(valid, parsed_vertices, decor_sections);
	shadow_decor.maybe_redraw(valid, parsed_vertices, decor_sections);
	highlight_decor.maybe_redraw(valid, parsed_vertices, decor_sections);
	queue_redraw();

func _draw() -> void:
	if !is_in_editor(): return;
	
	if !valid:
		# invalid outline
		draw_polyline(vectors, INVALID_COLOR, 3, false);
		# close line
		draw_line(vectors[0], vectors[-1], INVALID_COLOR, 3, false);
	
	# selection outline
	var selected_thickness := 3 if layer == "ab" else 4;
	if is_in_group(&"selected_polygons"):
		draw_polyline(vectors, SELECTED_COLOR, selected_thickness, false);
		# close line
		draw_line(vectors[0], vectors[-1], SELECTED_COLOR, selected_thickness, false);
	else:
		# vertex selection outline
		var i := 0;
		var size := vertices.size();
		for vert in vertices:
			if vert.selected:
				var next_vert := vertices[(i + 1) % size] if !is_counterclockwise else vertices[posmod(i - 1, size)];
				draw_line(vert.position, next_vert.position, SELECTED_COLOR, selected_thickness, false);
			i += 1;
	
	if valid:
		var thickness := 1 if layer == "ab" else 2;
		# layer outline
		var color = get_color();
		draw_polyline(vectors, color, thickness, false);
		# close line
		draw_line(vectors[0], vectors[-1], color, thickness, false);
	
	# draw vertices
	for vert in vertices:
		EditorLib.draw_vert(self, vert.position, 1.0, vert.selected);


# re-computes the polygon's vertices
# (updating its collision and graphics)
func update_polygon() -> void:
	vectors.clear();
	parsed_vertices.clear();
	for vert: Vertex in vertices:
		var vect := vert.position;
		vectors.append(vect);
		parsed_vertices.append(vert);
	is_counterclockwise = false;
	if Geometry2D.is_polygon_clockwise(vectors):
		vectors.reverse();
		parsed_vertices.reverse();
		is_counterclockwise = true;
	
	# check if the polygon self-intersects
	# if it does, make it invalid
	var triangulated = Geometry2D.triangulate_polygon(vectors);
	valid = triangulated.size() > 0;
	fill.visible = valid;
	if valid:
		collision_polygon.polygon = vectors;
		fill.polygon = vectors;
		fill.texture = preload("res://sprites/level_themes/GreenHill/checkerboard.png")
		decor_sections = LevelDrawing.compute_decor(parsed_vertices, self);
	else:
		collision_polygon.polygon = PackedVector2Array();
		decor_sections = [];
	redraw();

func update_layer() -> void:
	if !collision: return;
	collision_polygon.one_way_collision = semisolid;
	layer_num = LevelUtil.LAYER_POLYGONS;
	match layer:
		"a": layer_num |= LevelUtil.LAYER_A;
		"b": layer_num |= LevelUtil.LAYER_B;
		"ab": layer_num |= LevelUtil.LAYER_A | LevelUtil.LAYER_B;
	collision.collision_layer = layer_num;
	collision.collision_mask = layer_num;
	redraw();

func is_in_editor() -> bool:
	return container && container.editor_mode;
