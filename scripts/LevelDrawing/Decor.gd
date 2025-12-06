## Defines a decoration for polygons.
@tool
extends Resource
class_name Decor

## The type of this decor. Different decors have different variables.
@export var type: DecorType;

## The primary texture of this decor.
@export var texture: Texture2D;
## The secondary texture of this decor.
@export var edge: Texture2D;
## A color for this decor.
@export var color: Color;
## An offset for this decor.
@export var shadow_offset: Vector2;
## A size for this decor.
@export var size: float;

## What polygon decoration layers this decor will be drawn on.
@export_flags("Solid", "Shadow", "Highlight") var layer: int = Layer.SOLID;
## What polygon surface types this decor will be drawn on.
@export var surface_type: SurfaceType = SurfaceType.NONE;

## Array of angles to match (optional).
## The X component of each vector is the "center angle",
## and the Y component is the "radius".
@export_range(0, 360, 0.01, "radians_as_degrees") var match_angle_center: float;
@export_range(0, 360, 0.01, "radians_as_degrees") var match_angle_radius: float;

enum DecorType {
	NONE,
	GRASS,
	SHADE
}

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

func matches(vert: Vertex, angle: float) -> bool:
	var vert_surf_type := vertex_surface_type(vert);
	if (surface_type & vert_surf_type) == 0:
		return false;
	
	if match_angle_radius != 0:
		var angdiff := angle_difference(match_angle_center, angle);
		if abs(angdiff) <= match_angle_radius:
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
