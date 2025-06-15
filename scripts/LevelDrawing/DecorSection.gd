class_name DecorSection

var decor: Decor;
var verts: PackedVector2Array;
var angles: PackedFloat32Array;

static var PF32ARR_EMPTY = PackedFloat32Array();

func _init(s_decor: Decor, s_verts: PackedVector2Array = PackedVector2Array(), s_angles: PackedFloat32Array = PackedFloat32Array()):
	decor = s_decor;
	verts = s_verts;
	angles = s_angles;
