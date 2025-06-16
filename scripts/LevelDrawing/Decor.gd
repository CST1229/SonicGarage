## Defines a decoration for polygons.
extends Object
class_name Decor

var type: StringName;
var texture: Texture2D;
var edge: Texture2D;
var color: Color;
var layer: int = Layer.SOLID;


## Array of angles to match (optional).
## The X component of each vector is the "center angle",
## and the Y component is the "radius".
var match_angles_arr: PackedVector2Array = PackedVector2Array();

enum SurfaceType {
	NONE = 0,
	BASE = 1,
	FLOOR = 2,
	EDGE = 4,
	BORDER = 8,
	FLOOR_EDGE = FLOOR | EDGE,
	ALL = BASE | FLOOR | EDGE | BORDER,
}

enum Layer {
	NONE = 0,
	SOLID = 1,
	SHADOW = 2,
	HIGHLIGHT = 4,
}

var surface_type: SurfaceType = SurfaceType.NONE;

static var NONE := define_none();
static var GHZ_GRASS := define_grass(
	preload("res://sprites/level_themes/GreenHill/grass.png"),
	preload("res://sprites/level_themes/GreenHill/grass_edge.png"),
).match_angles(SurfaceType.FLOOR, [Vector2(0, 60)]).set_layer(Layer.SOLID | Layer.SHADOW);
static var GHZ_HIGHLIGHT := define_shade(Color(0.3, 0.2, 0)).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(-45, 90)]).set_layer(Layer.HIGHLIGHT);
static var GHZ_SHADOW := define_shade(Color(0, 0, 0)).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(135, 90)]).set_layer(Layer.SHADOW);

# TODO: themes should define their decor
static var GHZ_DECOR = [GHZ_GRASS, GHZ_HIGHLIGHT, GHZ_SHADOW];

# Decors that can't coexist on one vertex.
# If both decors match a vertex, the one that wins will be
# the one earlier in the theme's decors array.
static var MUTUALLY_EXCLUSIVE: Dictionary[Decor, Array] = {
	GHZ_GRASS: [GHZ_HIGHLIGHT, GHZ_SHADOW],
	GHZ_HIGHLIGHT: [GHZ_GRASS, GHZ_SHADOW],
	GHZ_SHADOW: [GHZ_HIGHLIGHT, GHZ_GRASS],
};

func matches(vert: Vertex, angle: float) -> bool:
	var vert_surf_type := vertex_surface_type(vert);
	if (surface_type & vert_surf_type) == 0:
		return false;
	
	if match_angles_arr.size() > 0:
		for vector: Vector2 in match_angles_arr:
			var angdiff := angle_difference(vector.x, angle);
			if abs(angdiff) <= vector.y:
				return true;
		return false;
	
	return true;

static func vertex_surface_type(vert: Vertex) -> int:
	match vert.edge:
		"auto": return SurfaceType.BASE | SurfaceType.FLOOR;
		"floor": return SurfaceType.BASE | SurfaceType.FLOOR;
		"edge": return SurfaceType.BASE | SurfaceType.EDGE;
		"border": return SurfaceType.BASE | SurfaceType.BORDER;
		_: return SurfaceType.BASE;

# functions for defining decor
static func define_none() -> Decor:
	var decor := new();
	decor.type = &"none";
	decor.layer = Layer.NONE;
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
		var angle := angles[i];
		angles[i] = Vector2(deg_to_rad(angle.x), deg_to_rad(angle.y));
	return self;

func set_layer(value: int) -> Decor:
	layer = value;
	return self;
