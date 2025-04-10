class_name DecorSection

var decor: Decor;
var verts: PackedVector2Array;
var normals: PackedVector2Array;

static var PV2ARR_EMPTY = PackedVector2Array();

static func create(s_decor: Decor, s_verts: PackedVector2Array, s_normals: PackedVector2Array = PV2ARR_EMPTY):
	var section := new();
	section.decor = s_decor;
	section.verts = s_verts;
	section.normals = s_normals;
	return section;
