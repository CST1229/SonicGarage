extends Node2D
class_name Polygon

# a polygon is a part of the terrain.
# it's made out of Vertices

var vertices: Array[Vertex] = [];
var vectors: PackedVector2Array = PackedVector2Array();
var valid: bool = false;

var layer: String = "ab":
	set(value):
		layer = value;
		update_layer();
var layer_num: int = Global.LAYER_A | Global.LAYER_B;

const INVALID_COLOR = Color(1, 0.2, 0.1);
const SELECTED_COLOR = EditorLib.VERT_COLOR;

var container: LevelContainer;

@onready var collision = $collision;
@onready var collision_polygon = $collision/collision_polygon;
@onready var fill = $polygon;
@onready var decor = $decor;
@onready var shadow_clip = $shadow_polygon;
@onready var shadow_decor = $shadow_polygon/shadow_decor;

func _ready():
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED;
	add_to_group(&"polygons");
	update_polygon();
	update_layer();
	
func get_color():
	var c = Color.BLACK;
	if layer_num & Global.LAYER_A:
		c = Color(c.r, c.g + 0.5, c.b + 1);
	if layer_num & Global.LAYER_B:
		c = Color(c.r + 1, c.g + 0.5, c.b);
	return c;

func _draw():
	decor.visible = valid;
	shadow_decor.visible = valid;
	if valid:
		decor.vectors = vectors;
		decor.queue_redraw();
		shadow_decor.vectors = vectors;
		shadow_decor.queue_redraw();
	
	if !container || !container.editor_mode: return;
	
	if !valid:
		draw_polyline(vectors, INVALID_COLOR, 3, false);
		# close line
		draw_line(vectors[0], vectors[-1], INVALID_COLOR, 3, false);
	if is_in_group(&"selected_polygons"):
		draw_polyline(vectors, SELECTED_COLOR, 2, false);
		# close line
		draw_line(vectors[0], vectors[-1], SELECTED_COLOR, 2, false);
		
	# draw vertices
	for vert in vertices:
		EditorLib.draw_vert(self, vert.position, 1.0, vert.selected);


# re-computes the polygon's vertices
# (updating its collision and graphics)
func update_polygon():
	vectors.clear();
	for vert in vertices:
		vectors.append(vert.position);
	if Geometry2D.is_polygon_clockwise(vectors):
		vectors.reverse();
	
	# check if the polygon self-intersects
	# if it does, make it invalid
	var triangulated = Geometry2D.triangulate_polygon(vectors);
	valid = triangulated.size() > 0;
	fill.visible = valid;
	shadow_clip.visible = valid;
	if valid:
		collision_polygon.polygon = vectors;
		fill.polygon = vectors;
		shadow_clip.polygon = vectors;
		fill.texture = preload("res://sprites/level_themes/GreenHill/checkerboard.png")
	else:
		collision_polygon.polygon = PackedVector2Array();
	
	queue_redraw();

func update_layer():
	if !collision: return;
	layer_num = Global.LAYER_POLYGONS;
	match layer:
		"a": layer_num |= Global.LAYER_A;
		"b": layer_num |= Global.LAYER_B;
		"ab": layer_num |= Global.LAYER_A | Global.LAYER_B;
	collision.collision_layer = layer_num;
	collision.collision_mask = layer_num;
	queue_redraw();
