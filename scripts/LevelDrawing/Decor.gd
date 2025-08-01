## Defines a decoration for polygons.
extends Object
class_name Decor

## The type of this decor. Different decors have different variables.
var type: StringName;

## The primary texture of this decor.
var texture: String;
## The secondary texture of this decor.
var edge: String;
## A color for this decor.
var color: Color;
## An offset for this decor.
var shadow_offset: Vector2;
## A size for this decor.
var size: float;

var layer: int = Layer.SOLID;
var surface_type: SurfaceType = SurfaceType.NONE;

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


class LevelTheme:
	var base_texture: String;
	var decors: Array[Decor];
	## Decors that can't coexist on one vertex.
	## If both decors match a vertex, the one that wins will be
	## the one earlier in the theme's decors array.
	var mutually_exclusive: Dictionary[Decor, Array];
	## Indexes that decide which decor takes precedence in case of a
	## mutually_exclusive conflict.
	var decor_precedence: Dictionary[Decor, int] = {};
	## *Inverse* scale of the base "fill" texture on polygons.
	var base_texture_scale := 1.0;
	
	func _init(_base_texture: String, _decors: Array[Decor], _mutually_exclusive: Array[Array] = [], _base_texture_scale := 1.0):
		base_texture = _base_texture;
		decors = _decors;
		mutually_exclusive = {};
		base_texture_scale = _base_texture_scale;
		
		for i in range(decors.size()):
			decor_precedence[decors[i]] = i;
		
		# convert the convienient array declaration into the spaghetti dictionary
		# used by the decor rendering code
		for decor_group in _mutually_exclusive:
			for decor in decor_group:
				if !(decor in mutually_exclusive):
					mutually_exclusive[decor] = [];
				for target_decor in decor_group:
					if !(target_decor in mutually_exclusive[decor]):
						mutually_exclusive[decor].append(target_decor);
	
	func load():
		for decor in decors:
			decor.load();
	
	func unload():
		for decor in decors:
			decor.unload();

static var NONE := define_none();
static var EDITOR_SEMISOLID := define_grass(
	"res://sprites/level_themes/semisolid_indicator.png",
	"",
).match_angles(SurfaceType.ALL, [Vector2(0, 80)]).set_layer(Layer.SOLID);

static var GHZ_GRASS := define_grass(
	"res://sprites/level_themes/GreenHill/grass.png",
	"res://sprites/level_themes/GreenHill/grass_edge.png",
	Vector2(0, 12),
).match_angles(SurfaceType.FLOOR, [Vector2(0, 60)]).set_layer(Layer.SOLID | Layer.SHADOW);
static var GHZ_HIGHLIGHT := define_shade(Color(0.3, 0.2, 0)).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(-45, 90)]).set_layer(Layer.HIGHLIGHT);
static var GHZ_SHADOW := define_shade(Color(0, 0, 0)).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(135, 90)]).set_layer(Layer.SHADOW);

static var MZ_HIGHLIGHT := define_shade(Color(0.15, 0.15, 0.2), 4).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(-45, 90)]).set_layer(Layer.HIGHLIGHT);
static var MZ_SHADOW := define_shade(Color(0, 0, 0), 4).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(135, 90)]).set_layer(Layer.SHADOW);

static var EHZ_GRASS := define_grass(
	"res://sprites/level_themes/EmeraldHill/grass.png",
	"res://sprites/level_themes/EmeraldHill/grass_edge.png",
	Vector2(0, 16),
).match_angles(SurfaceType.FLOOR, [Vector2(0, 60)]).set_layer(Layer.SOLID | Layer.SHADOW);
static var EHZ_HIGHLIGHT := define_shade(Color(0.3, 0.2, 0), 4).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(0, 45)]).set_layer(Layer.HIGHLIGHT);
static var EHZ_SHADOW := define_shade(Color(0, 0, 0), 4).match_angles(SurfaceType.FLOOR_EDGE, [Vector2(180, 270)]).set_layer(Layer.SHADOW);

static var THEME_GHZ := LevelTheme.new(
	"res://sprites/level_themes/GreenHill/checkerboard.png",
	[GHZ_GRASS, GHZ_HIGHLIGHT, GHZ_SHADOW],
	[[GHZ_GRASS, GHZ_HIGHLIGHT, GHZ_SHADOW]],
	(2.0 / 16.0)
);
static var THEME_MZ := LevelTheme.new(
	"res://sprites/level_themes/Marble/bricks.png",
	[GHZ_GRASS, MZ_HIGHLIGHT, MZ_SHADOW],
	[[GHZ_GRASS, MZ_HIGHLIGHT, MZ_SHADOW]],
);
static var THEME_EHZ := LevelTheme.new(
	"res://sprites/level_themes/EmeraldHill/dirt.png",
	[EHZ_GRASS, EHZ_HIGHLIGHT, EHZ_SHADOW],
	[[EHZ_GRASS, EHZ_HIGHLIGHT, EHZ_SHADOW]],
);


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

static func define_grass(d_texture: String, d_edge: String, d_shadow_offset: Vector2 = Vector2.ZERO) -> Decor:
	var decor := new();
	decor.type = &"grass";
	decor.texture = d_texture;
	decor.edge = d_edge;
	decor.shadow_offset = d_shadow_offset;
	return decor;

static func define_shade(d_color: Color, d_size := 24.0) -> Decor:
	var decor := new();
	decor.type = &"shade";
	decor.color = d_color;
	decor.size = d_size;
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

# for some reason if we don't load the texture beforehand it just... becomes white squares???
var loaded_texture: Texture2D;
var loaded_edge_texture: Texture2D;

func load() -> void:
	if texture:
		loaded_texture = load(texture);
	if edge:
		loaded_edge_texture = load(edge);

func unload() -> void:
	loaded_texture = null;
	loaded_edge_texture = null;
