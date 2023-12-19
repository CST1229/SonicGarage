extends RefCounted
class_name Vertex

# abstract data structure used by polygons
# (i don't just use Vector2 because of curves,
# and so i can pass them by reference and have stuff like
# an array of selected vertices and i can just move them by
# modifying their positions)

var position: Vector2 = Vector2.ZERO;
var polygon: Polygon = null;
var selected: bool = false;
var edge: String = "auto";
