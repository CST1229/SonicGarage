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

var theme_override: LevelTheme;

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
		if container.editor && EditorLib.tool_has_big_verts(container.editor.tool):
			EditorLib.draw_vert(self, vert.position, 1.0, 4.0 if !vert.selected else 6.0);
		else:
			EditorLib.draw_vert(self, vert.position, 1.0, 2.0);

## re-computes the polygon's vertices
## (updating its collision and graphics)
func update_polygon() -> void:
	vectors.clear();
	parsed_vertices.clear();
	for vert: Vertex in vertices:
		var vect := vert.position;
		if vectors.size() == 0 || vectors[-1] != vect:
			vectors.append(vect);
		parsed_vertices.append(vert);
	if vectors.size() == 0:
		return;
	
	is_counterclockwise = false;
	if Geometry2D.is_polygon_clockwise(vectors):
		vectors.reverse();
		parsed_vertices.reverse();
		is_counterclockwise = true;
	
	var actual_theme: LevelTheme = theme_override;
	if !actual_theme && container:
		actual_theme = container.theme;
	valid = actual_theme != null;
	
	# check if the polygon self-intersects in any way
	# if it does, make it invalid
	# triangulate_polygon makes sure it's valid for the fill polygon,
	# and decompose_polygon_in_convex makes sure it's valid for the collision polygon
	# (especially important since you can't select polygons with invalid collision, so you end up with a softlock of sorts)
	if valid:
		var triangulated := Geometry2D.triangulate_polygon(vectors);
		valid = !triangulated.is_empty();
		if valid:
			var decomposed := Geometry2D.decompose_polygon_in_convex(vectors);
			valid = !decomposed.is_empty();
	fill.visible = valid;
	collision_polygon.disabled = true;
	
	fill.polygons = [];
	if valid:
		collision_polygon.build_mode = CollisionPolygon2D.BUILD_SOLIDS;
		collision_polygon.polygon = vectors;
		fill.polygon = vectors;
		decor_sections = LevelDrawing.compute_polygon(actual_theme, parsed_vertices, self);
		collision_polygon.disabled = false;
			
	else:
		if is_in_editor():
			collision_polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS;
			collision_polygon.polygon = vectors;
			collision_polygon.disabled = false;
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
