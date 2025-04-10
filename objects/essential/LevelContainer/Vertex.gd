## Abstract data structure used by [Polygon]s.
##
## I don't just use [Vector2] because of curves,
## and so I can pass them by reference and have stuff like
## an [Array] of selected [Vertex]es and I can just move them by
## modifying their positions.
class_name Vertex

var position: Vector2 = Vector2.ZERO;
var polygon: Polygon = null;
var selected: bool = false;
var edge: StringName = &"auto";
