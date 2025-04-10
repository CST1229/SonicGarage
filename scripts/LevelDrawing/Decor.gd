## Defines a decoration for polygons.
extends Object
class_name Decor

var type: StringName;
var texture: Texture2D;
var edge: Texture2D;
var color: Color;


## Array of angles to match (optional).
## The X component of each vector is the center of the angle,
## and the Y component is the range/"radius".
var match_angles_arr: PackedVector2Array;

enum SurfaceType {
	NONE = 0,
	BASE = 1,
	FLOOR = BASE | 2,
	EDGE = BASE | 4,
	BORDER = BASE | 8,
	FLOOR_EDGE = FLOOR | EDGE,
	ALL = BASE | FLOOR | EDGE | BORDER,
}

var surface_type: SurfaceType = SurfaceType.NONE;

static var NONE := define_none();
static var GHZ_GRASS := define_grass(
	preload("res://sprites/level_themes/GreenHill/grass.png"),
	preload("res://sprites/level_themes/GreenHill/grass_edge.png"),
).match_angles(SurfaceType.FLOOR, [Vector2(-70, 70)]);
static var GHZ_HIGHLIGHT := define_shade(Color(1, 1, 0)).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(-45, 90)]);
static var GHZ_SHADOW := define_shade(Color(0, 0, 0)).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(130, 90)]);

# TODO: themes should define their decor
static var GHZ_DECOR = [GHZ_GRASS, GHZ_HIGHLIGHT, GHZ_SHADOW];

func matches(vert: Vertex, angle: float) -> bool:
	var vert_surf_type := vertex_surface_type(vert);
	if surface_type & vert_surf_type == 0:
		return false;
	
	if match_angles_arr.size() > 0:
		for vector: Vector2 in match_angles_arr:
			if angle >= vector.x && angle < vector.y:
				return true;
		return false;
	
	return true;

static func vertex_surface_type(vert: Vertex) -> SurfaceType:
	match vert.edge:
		"auto": return SurfaceType.FLOOR;
		"floor": return SurfaceType.FLOOR;
		"edge": return SurfaceType.EDGE;
		"border": return SurfaceType.BORDER;
		_: return SurfaceType.NONE;

# functions for defining decor
static func define_none() -> Decor:
	var decor := new();
	decor.type = &"none";
	return decor;

static func define_grass(d_texture: Texture2D, d_edge: Texture2D) -> Decor:
	var decor := new();
	decor.type = &"grass";
	decor.texture = d_texture;
	decor.edge = d_edge;
	return decor;

static func define_shade(d_color: Color) -> Decor:
	var decor := new();
	decor.type = &"shade";
	decor.color = d_color;
	return decor;

func match_angles(surf_type: SurfaceType, _angles: Array[Vector2]) -> Decor:
	surface_type = surf_type;
	match_angles_arr = PackedVector2Array(_angles);
	
	var angles := match_angles_arr;
	for i in match_angles_arr.size():
		var angle = angles[i];
		if angle.x > angle.y:
			angle = Vector2(angle.y, angle.x);
		
		if angle.x < 0 && angle.y >= 0:
			angles[i] = Vector2(0, deg_to_rad(angle.y));
			angles.append(Vector2(deg_to_rad(360 + angle.x), deg_to_rad(360)));
		else:
			angles[i] = Vector2(deg_to_rad(angle.x), deg_to_rad(angle.y));
	return self;
